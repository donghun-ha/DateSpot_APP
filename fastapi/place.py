from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from urllib.parse import unquote
import hosts
import unicodedata
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

def normalize_place_name(name: str) -> str:
    # Unicode 정규화 (NFC 적용)
    return unicodedata.normalize("NFC", name)


def remove_invisible_characters(input_str: str) -> str:
    # 모든 비표시 가능 문자를 제거 (공백, 제어 문자 포함)
    return ''.join(ch for ch in input_str if ch.isprintable())

import unicodedata

def normalize_place_name_nfd(name: str) -> str:
    """
    입력된 이름을 Unicode NFD로 정규화
    """
    return unicodedata.normalize("NFD", name)

@router.get("/select")
async def select():
    conn = hosts.connect()
    curs = conn.cursor()

    # SQL 문장
    sql = "SELECT * FROM place"
    curs.execute(sql)
    rows = curs.fetchall()
    conn.close()
    dict_list = []
    for row in rows:
        dict_list.append(
            {
                'name' : row[0],
                'address' : row[1],
                'lat' : row[2],
                'lng' : row[3],
                'description' : row[4],
                'contact_info' : row[5],
                'operating_hour' : row[6],
                'parking' : row[7],
                'closing_time' : row[8]
            }
        )
    return dict_list


def remove_invisible_characters(input_str: str) -> str:
    """
    문자열에서 모든 보이지 않는 문자(공백, 제어 문자 포함)를 제거
    """
    return ''.join(ch for ch in input_str if ch.isprintable())







@router.get("/images")
async def get_images(name: str):
    """
    특정 이름에 해당하는 이미지를 S3에서 가져와 리스트로 반환
    """
    s3_client = hosts.create_s3_client()
    try:
        # 입력값 디코딩 및 NFD 정규화
        decoded_name = unquote(name).strip()
        normalized_name = normalize_place_name_nfd(decoded_name)  # 명소는 NFD로 정규화
        prefix = f"명소/{normalized_name}_"


        # S3에서 파일 검색 (Prefix 적용)
        response = s3_client.list_objects_v2(Bucket=hosts.BUCKET_NAME, Prefix=normalize_place_name_nfd(prefix))
        
        if "Contents" not in response or not response["Contents"]:
            raise HTTPException(status_code=404, detail="No images found")
        
        # 필터링된 키 목록 가져오기
        filtered_keys = [normalize_place_name_nfd(content["Key"]) for content in response["Contents"]]

        return {"images": filtered_keys}

    except Exception as e:
        print(f"Error while fetching images: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching images: {str(e)}")

@router.get("/image_thumb")
async def stream_image(name: str):
    """
    단일 이미지를 S3에서 검색하고 스트리밍 반환
    """
    s3 = hosts.create_s3_client()
    try:
        # 입력값 정리 및 디코딩
        decoded_name = unquote(name).strip()
        normalized_name = normalize_place_name_nfd(decoded_name)
        prefix = f"명소/{normalized_name}_"
        normalized_prefix = normalize_place_name_nfd(prefix)

        # S3에서 파일 검색 (Prefix를 사용하여 제한)
        response = s3.list_objects_v2(Bucket=hosts.BUCKET_NAME, Prefix=normalized_prefix)
        if "Contents" not in response or not response["Contents"]:
            print(f"No images found for prefix: {normalized_prefix}")
            raise HTTPException(status_code=404, detail="Image not found")

        # 첫 번째 파일 키 가져오기
        file_key = response["Contents"][0]["Key"]

        # S3 객체 가져오기
        cleaned_key = remove_invisible_characters(file_key)
        s3_object = s3.get_object(Bucket=hosts.BUCKET_NAME, Key=cleaned_key)

        # 이미지 스트리밍 반환
        return StreamingResponse(
            content=s3_object["Body"],
            media_type="image/jpeg"
        )

    except s3.exceptions.NoSuchKey:
        print(f"NoSuchKey error for key: {name}")
        raise HTTPException(status_code=404, detail="File not found in S3")
    except Exception as e:
        print(f"Error while streaming image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


# Pydantic 모델
class PlaceBookRequest(BaseModel):
    user_email: str
    place_name: str
    name: str

@router.post("/add_bookmark/")
async def add_bookmark(bookmark: PlaceBookRequest):
    connection =hosts.connect()
    try:
        with connection.cursor() as cursor:
            # 북마크 추가
            sql = """
                INSERT INTO place_bookmark (user_email, restaurant_name, name, created_at)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(sql, (
                bookmark.user_email,
                bookmark.place_name,
                bookmark.name,
                datetime.now()
            ))
            connection.commit()
        return {"message": "Bookmark added successfully"}
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to add bookmark")
    finally:
        connection.close()
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from urllib.parse import unquote
import hosts
from botocore.exceptions import ClientError
import unicodedata
import pymysql


router = APIRouter()


@router.get("/select")
async def select():
    conn = hosts.connect()
    curs = conn.cursor()

    # SQL 문장
    sql = "SELECT * FROM place"
    curs.execute(sql)
    rows = curs.fetchall()
    conn.close()
    print(rows)
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

import unicodedata
from fastapi import FastAPI, HTTPException
from urllib.parse import unquote



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

        print(f"Looking for images with Prefix: {prefix}")

        # S3에서 파일 검색 (Prefix 적용)
        response = s3_client.list_objects_v2(Bucket=hosts.BUCKET_NAME, Prefix=normalize_place_name_nfd(prefix))
        
        if "Contents" not in response or not response["Contents"]:
            print(f"No images found for prefix: {prefix}")
            raise HTTPException(status_code=404, detail="No images found")
        
        # 필터링된 키 목록 가져오기
        filtered_keys = [normalize_place_name_nfd(content["Key"]) for content in response["Contents"]]
        print(f"Filtered keys: {filtered_keys}")

        return {"images": filtered_keys}

    except Exception as e:
        print(f"Error while fetching images: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching images: {str(e)}")

@router.get("/image")
async def stream_image(file_key: str):
    s3_client = hosts.create_s3_client()
    try:
        # 파일 키 정리 및 정규화
        cleaned_key = remove_invisible_characters(file_key)

        # S3 객체 가져오기
        s3_object = s3_client.get_object(Bucket=hosts.BUCKET_NAME, Key=cleaned_key)

        # 디버깅: 가져온 객체 출력
        print(f"Streaming file: {cleaned_key}")

        return StreamingResponse(
            content=s3_object["Body"],
            media_type="image/jpeg"
        )
    except s3_client.exceptions.NoSuchKey:
        print(f"File not found in S3: {file_key}")
        raise HTTPException(status_code=404, detail="File not found in S3")
    except Exception as e:
        print(f"Error while streaming image: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

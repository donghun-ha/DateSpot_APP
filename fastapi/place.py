from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from urllib.parse import unquote
import hosts
from geopy.distance import geodesic
import unicodedata
from pydantic import BaseModel
from datetime import datetime
from pymysql.cursors import DictCursor

router = APIRouter()

def normalize_place_name(name: str) -> str:
    # Unicode 정규화 (NFC 적용)
    return unicodedata.normalize("NFC", name)


def remove_invisible_characters(input_str: str) -> str:
    # 모든 비표시 가능 문자를 제거 (공백, 제어 문자 포함)
    return ''.join(ch for ch in input_str if ch.isprintable())


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
class checkPlaceBook(BaseModel):
    user_email: str
    place_name: str

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

@router.post("/check_bookmark/")
async def check_bookmark(request: checkPlaceBook):
    connection = hosts.connect()
    try:
        with connection.cursor(DictCursor) as cursor:  # DictCursor 사용
            # 북마크 존재 여부 확인
            sql = """
                SELECT COUNT(*) AS count
                FROM place_bookmark
                WHERE user_email = %s AND place_name = %s
            """
            cursor.execute(sql, (request.user_email, request.place_name))
            result = cursor.fetchone()
            is_bookmarked = result["count"] > 0  # DictCursor로 딕셔너리로 처리 가능
        return {"is_bookmarked": is_bookmarked}
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to check bookmark")
    finally:
        connection.close()


@router.post("/get_user_bookmarks/")
async def get_user_bookmarks(user_email: str):
    """
    주어진 이메일에 해당하는 모든 북마크 명소 이름을 반환
    """
    connection = hosts.connect()
    try:
        with connection.cursor(DictCursor) as cursor:
            sql = """
                SELECT p.name, p.address
                FROM place_bookmark pb
                JOIN place r ON pb.place_name = p.name
                WHERE pb.user_email = %s
            """
            cursor.execute(sql, (user_email,))
            bookmarks = cursor.fetchall()
        return {"results": bookmarks}
    except Exception as e:
        print(f"Error fetching bookmarks: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch user bookmarks")
    finally:
        connection.close()
class UserLocation(BaseModel):
    lat: float
    lng: float

@router.post("/nearby_places/")
async def get_nearby_places(location: UserLocation, radius: float = 1000):
    """
    사용자 위치(lat, lng)를 기반으로 반경(radius) 내의 맛집 및 명소를 반환
    """
    connection = hosts.connect()
    try:
        with connection.cursor() as cursor:

            # 명소 데이터 가져오기
            place_query = "SELECT name, address, parking, lat, lng FROM place"
            cursor.execute(place_query)
            places = cursor.fetchall()

        # 사용자 위치
        user_coords = (location.lat, location.lng)

        # 반경 내의 명소 필터링
        nearby_places = [
            {
                "name": p[0],
                "address": p[1],
                "lat": p[2],
                "lng": p[3],
                "distance": geodesic(user_coords, (p[2], p[3])).meters
            }
            for p in places
            if geodesic(user_coords, (p[2], p[3])).meters <= radius
        ]

        # 결과 반환
        return {
            "nearby_places": nearby_places
        }
    except Exception as e:
        print(f"Error fetching nearby places: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch nearby places")
    finally:
        connection.close()
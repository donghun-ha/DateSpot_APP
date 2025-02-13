from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from urllib.parse import unquote
import hosts, json
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


@router.get("/select_redis")
async def select():

    # Redis 키 설정 (이메일 기반)
    redis_key = "place:all"
    
    # Redis 연결
    redis = await hosts.get_redis_connection()

   # Redis에서 데이터 검색
    cached_data = await redis.get(redis_key)
    if cached_data:
        # Redis 캐시에 데이터가 존재하면 반환
        data = json.loads(cached_data)
        print("Redis에서 데이터 반환")
        return {"source": "redis", "data": data}

    # Redis 캐시에 데이터가 없는 경우 DB 조회
    conn = hosts.connect()
    curs = conn.cursor()

    # SQL 문장
    sql = "SELECT * FROM place"
    curs.execute(sql)
    rows = curs.fetchall()
    conn.close()

    # 결과를 딕셔너리로 변환
    dict_list = []
    for row in rows:
        dict_list.append(
            {
                'name': row[0],
                'address': row[1],
                'lat': row[2],
                'lng': row[3],
                'description': row[4],
                'contact_info': row[5],
                'operating_hour': row[6],
                'parking': row[7],
                'closing_time': row[8]
            }
        )

    # Redis에 캐싱 (유효 기간: 300초)
    await redis.set(redis_key, json.dumps(dict_list), ex=300)
    print("Redis에 데이터 캐싱 완료")

    # DB 데이터를 반환
    return {"source": "database", "data": dict_list}



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

@router.get("/image")
async def stream_image(file_key: str):
    """
    단일 이미지를 S3에서 검색하고 스트리밍 반환
    """
    s3_client = hosts.create_s3_client()
    try:
        # 입력값 정리 및 유니코드 정규화 (NFD 적용)
        decoded_key = unquote(file_key).strip()
        normalized_key = unicodedata.normalize("NFD", decoded_key)
        cleaned_key = remove_invisible_characters(normalized_key)
        # S3 객체 가져오기
        s3_object = s3_client.get_object(Bucket=hosts.BUCKET_NAME, Key=cleaned_key)
        # 이미지 스트리밍 반환
        return StreamingResponse(
            content=s3_object["Body"],
            media_type="image/jpeg"
        )

    except s3_client.exceptions.NoSuchKey:
        print(f"NoSuchKey error for key: {file_key}")
        raise HTTPException(status_code=404, detail="File not found in S3")
    except Exception as e:
        print(f"Error while streaming image: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


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
                INSERT INTO place_bookmark (user_email, place_name, name, created_at)
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
                JOIN place p ON pb.place_name = p.name
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
    connection = hosts.connect()
    try:
        with connection.cursor() as cursor:
            place_query = "SELECT name, address, parking, lat, lng, description, contact_info, operating_hour, closing_time FROM place"
            cursor.execute(place_query)
            places = cursor.fetchall()

        user_coords = (location.lat, location.lng)

        # 유효한 장소 필터링
        valid_places = [
            {
                "name": p[0],
                "address": p[1],
                "lat": p[3],
                "lng": p[4],
                "distance": geodesic(user_coords, (p[3], p[4])).meters,
                "description": p[5] if p[5] else "No description available",
                "contact_info": p[6] if p[6] else "No contact info",
                "operating_hour": p[7] if p[7] else "Unknown",
                "parking": p[2] if p[2] else "No parking info",
                "closing_time": p[8] if p[8] else "Unknown"
            }
            for p in places
            if p[3] is not None and p[4] is not None
        ]

        nearby_places = [p for p in valid_places if p["distance"] <= radius]

        return nearby_places
    except Exception as e:
        print(f"Error fetching nearby places: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch nearby places")
    finally:
        connection.close()

# 디테일 페이지로 이동할때 클릭한 place 정보 쿼리
@router.get('/go_detail')
async def get_detail(name: str):
    """
    북마크한 매장 또는 명소의 정보 가져오기
    """
    conn = hosts.connect()
    curs = conn.cursor()

    sql = "SELECT * FROM place WHERE name = %s"
    curs.execute(sql, (name,))
    rows = curs.fetchall()
    conn.close()

    if not rows:
        raise HTTPException(status_code=404, detail="Not Found")
    
    # 데이터를 매핑하여 반환 // SwiftUI에 맞는 형태
    results = [
        {
            "name": row[0],
            "address": row[1],
            "lat": row[2],
            "lng": row[3],
            "description": row[4],
            "contact_info": row[5],
            "operating_hour": row[6],
            "parking": row[7],
            "closing_time": row[8]
        }
        for row in rows
    ]
    return {"results": results}

@router.post("/delete_bookmark/")
async def delete_bookmark(bookmark: PlaceBookRequest):
    """
    북마크 삭제 API
    """
    connection = hosts.connect()
    try:
        with connection.cursor() as cursor:
            # 북마크 삭제 쿼리
            sql = """
                DELETE FROM place_bookmark
                WHERE user_email = %s AND place_name = %s
            """
            cursor.execute(sql, (bookmark.user_email, bookmark.place_name))
            connection.commit()
            
            # 삭제된 행 확인
            if cursor.rowcount == 0:
                raise HTTPException(
                    status_code=404,
                    detail="Bookmark not found"
                )

        return {"message": "Bookmark deleted successfully"}
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete bookmark")
    finally:
        connection.close()
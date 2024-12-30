from fastapi import HTTPException, APIRouter
from fastapi.responses import StreamingResponse
import hosts, unicodedata, re
from urllib.parse import unquote

router = APIRouter()


@router.get('/restaurant_select_all')
async def select():
    redis = hosts.get_redis_connection()
    try:
        conn = hosts.connect()
        curs = conn.cursor()
        sql = "select * from restaurant"
        curs.execute(sql)
        data = curs.fetchall()
        print(data)
        return {"result" : data}
    except Exception as e :
        print("restaurant.py select Error")
        return {"restaurant.py select Error" : e}
    
    
# 디테일 페이지로 이동할때 클릭한 restaurant 정보 쿼리
@router.get('/go_detail')
async def get_detail(name: str):
    """
    북마크한 매장 또는 맛집의 정보 가져오기
    """
    conn = hosts.connect()
    curs = conn.cursor()

    sql = "SELECT * FROM restaurant WHERE name = %s"
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
            "parking": row[4],
            "operatingHour": row[5],
            "closedDays": row[6],
            "contactInfo": row[7],
            "breakTime": row[8],  # 기존 description -> breakTime
            "lastOrder": row[9]   # 기존 closingTime -> lastOrder
        }
        for row in rows
    ]
    return {"results": results}



def normalize_restaurant_name(name: str) -> str:
    """
    입력된 이름을 S3에서 사용한 규칙에 맞게 변환
    """
    # 정규표현식을 사용하여 파일명을 S3 키에 맞게 변환
    match = re.match(r'^(.*?)(_.*)?$', name.strip(), re.IGNORECASE)
    if match:
        return match.group(1).strip()
    return name.strip()

def normalize_restaurant_name(name: str) -> str:
    # Unicode 정규화 (NFC 적용)
    return unicodedata.normalize("NFC", name)

def remove_invisible_characters(input_str: str) -> str:
    # 모든 비표시 가능 문자를 제거 (공백, 제어 문자 포함)
    return ''.join(ch for ch in input_str if ch.isprintable())

@router.get("/images")
async def get_images(name: str):
    """
    특정 이름에 해당하는 이미지를 S3에서 가져와 리스트로 반환
    """
    s3_client = hosts.create_s3_client()
    try:
        # 입력값 디코딩 및 정규화
        decoded_name = unquote(name).strip()
        normalized_name = normalize_restaurant_name(decoded_name)
        prefix = f"맛집/{normalized_name}_"

        # S3에서 파일 검색
        response = s3_client.list_objects_v2(Bucket=hosts.BUCKET_NAME)
        all_keys = [
            content["Key"] for content in response.get("Contents", [])
        ]

        # S3 키 정규화 및 매칭
        filtered_keys = [
            key for key in all_keys
            if normalize_restaurant_name(key).startswith(prefix)
        ]

        # 결과 확인
        if not filtered_keys:
            print(f"No images found for: {normalized_name}")
            raise HTTPException(status_code=404, detail="No images found")
        return {"images": filtered_keys}

    except Exception as e:
        print(f"Error while fetching images: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching images: {str(e)}")



@router.get("/image")
async def stream_image(file_key: str):
    """
    S3에서 단일 이미지 파일 스트리밍
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
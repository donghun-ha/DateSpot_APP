from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from urllib.parse import unquote
from image import s3  # 이미 초기화된 S3 클라이언트 사용
import unicodedata
import pymysql
import user


router = APIRouter()

def connect():
    # MySQL Connection
    conn = pymysql.connect(
        host='3.34.18.250',
        user='datespot',
        password='qwer1234',
        db='datespot',
        charset='utf8'
    )
    return conn


@router.get("/select")
async def select():
    conn = connect()
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

def normalize_name(name: str) -> str:
    """
    입력된 이름을 Unicode 정규화하여 S3 검색에 적합한 형태로 변환
    """
    return unicodedata.normalize("NFC", name.strip())

def remove_invisible_characters(input_str: str) -> str:
    """
    문자열에서 모든 보이지 않는 문자(공백, 제어 문자 포함)를 제거
    """
    return ''.join(ch for ch in input_str if ch.isprintable())

@router.get("/image")
async def stream_image(name: str, category: str = "명소"):
    """
    단일 이미지를 S3에서 검색 및 스트리밍 반환
    - name: 이미지와 연관된 이름 (예: 장소 이름 또는 식당 이름)
    """
    try:
        # 입력값 정리 및 디코딩
        decoded_name = unquote(name).strip()
        normalized_name = normalize_name(decoded_name)
        print(f"Original input: {repr(name)}")
        print(f"Decoded name: {decoded_name}")
        print(f"Normalized name: {normalized_name}")

        # Prefix 설정 (카테고리에 따라 달라짐)
        prefix = f"{category}/{normalized_name}_"
        print(f"Using Prefix: {prefix}")

        # S3에서 파일 검색
        response = s3.list_objects_v2(Bucket=user.BUCKET_NAME, Prefix=prefix)
        all_keys = [content["Key"] for content in response.get("Contents", [])]

        # 파일이 없을 경우 처리
        if not all_keys:
            print(f"No images found for {normalized_name} in category {category}")
            raise HTTPException(status_code=404, detail="Image not found")

        # 첫 번째 파일 키 가져오기
        file_key = all_keys[0]
        print(f"Selected file key: {file_key}")

        # 보이지 않는 문자 제거 후 파일 가져오기
        cleaned_key = remove_invisible_characters(file_key)
        s3_object = s3.get_object(Bucket=user.BUCKET_NAME, Key=cleaned_key)

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
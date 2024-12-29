from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from urllib.parse import unquote
from image import s3  # 이미 초기화된 S3 클라이언트 사용
from botocore.exceptions import ClientError
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

import unicodedata
from fastapi import FastAPI, HTTPException
from urllib.parse import unquote

import re

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


@router.get("/images")
async def get_images(name: str):
    """
    특정 이름에 해당하는 이미지를 S3에서 가져와 리스트로 반환
    """
    s3_client = user.create_s3_client()
    try:
        # 입력값 디코딩 및 정규화
        decoded_name = unquote(name).strip()
        normalized_name = normalize_restaurant_name(decoded_name)
        print(f"Original input (repr): {repr(name)}")
        print(f"Decoded name (repr): {repr(decoded_name)}")
        print(f"Normalized name (repr): {repr(normalized_name)}")

        # Prefix 생성
        prefix = f"명소/{normalized_name}_"
        print(f"Using Prefix: {prefix}")

        # S3에서 파일 검색
        response = s3_client.list_objects_v2(Bucket=user.BUCKET_NAME)
        all_keys = [
            content["Key"] for content in response.get("Contents", [])
        ]
        print(f"All S3 Keys: {all_keys}")

        # S3 키 정규화 및 매칭
        filtered_keys = [
            key for key in all_keys
            if normalize_restaurant_name(key).startswith(prefix)
        ]
        print(f"Filtered keys after normalization: {filtered_keys}")

        # 결과 확인
        if not filtered_keys:
            print(f"No images found for: {normalized_name}")
            raise HTTPException(status_code=404, detail="No images found")

        return {"images": filtered_keys}

    except Exception as e:
        print(f"Error while fetching images: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching images: {str(e)}")


@router.get("/images_old")
async def get_images_old(name: str):
    """
    이전에 동작했던 코드: URL 디코딩만 사용, 정규화 없음
    """
    s3_client = user.create_s3_client()  # S3 클라이언트 생성
    try:
        # URL 디코딩 및 공백 제거
        decoded_name = unquote(name).strip()
        print(f"Decoded name: {decoded_name}")  # 디버깅용 로그
        print(f"Original input (repr): {repr(name)}")
        print(f"Decoded name (repr): {repr(decoded_name)}")
        # Prefix 생성 (디렉토리 포함)
        prefix = f"명소/{decoded_name}_"
        print(f"Using Prefix: {prefix}")  # 디버깅용 로그

        # S3에서 전체 파일 검색
        response = s3_client.list_objects_v2(Bucket=user.BUCKET_NAME)
        all_keys = [content["Key"] for content in response.get("Contents", [])]

        if "Contents" not in response or not response["Contents"]:
            print("No files found in the bucket")  # 디버깅용 로그
            raise HTTPException(status_code=404, detail="No images found")

        # 검색된 키에서 이름 필터링
        filtered_keys = [
            key
            for key in all_keys
            if f"{decoded_name}_" in key  # 더 유연한 필터링 조건
        ]

        print(f"Filtered keys: {filtered_keys}")  # 필터링된 파일 키 출력

        # 필터링된 키가 없을 경우
        if not filtered_keys:
            print(f"No images found for: {decoded_name}")  # 디버깅용 로그
            raise HTTPException(status_code=404, detail="No images found")

        return {"images": filtered_keys}
    
    except ClientError as e:
        # S3 클라이언트 에러 처리
        print(f"ClientError while fetching images: {str(e)}")  # 디버깅용 로그
        raise HTTPException(status_code=500, detail=f"ClientError fetching images: {str(e)}")
    except Exception as e:
        # 기타 에러 처리
        print(f"Error while fetching images: {str(e)}")  # 상세 예외 출력
        raise HTTPException(status_code=500, detail=f"Error fetching images: {str(e)}")



@router.get("/image")
async def stream_image(file_key: str):
    """
    S3에서 단일 이미지 파일 스트리밍
    """
    s3_client = user.create_s3_client()
    try:
        # 보이지 않는 문자 제거
        cleaned_key = remove_invisible_characters(file_key)
        print(f"Original key: {file_key}")
        print(f"Cleaned key: {cleaned_key}")

        # S3 객체 가져오기
        s3_object = s3_client.get_object(Bucket=user.BUCKET_NAME, Key=cleaned_key)
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

def remove_invisible_characters(input_str: str) -> str:
    # 모든 비표시 가능 문자를 제거 (공백, 제어 문자 포함)
    return ''.join(ch for ch in input_str if ch.isprintable())
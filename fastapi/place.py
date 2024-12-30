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

# def normalize_name(name: str) -> str:
#     """
#     입력된 이름을 Unicode 정규화하여 S3 검색에 적합한 형태로 변환
#     """
#     return unicodedata.normalize("NFC", name.strip())

def remove_invisible_characters(input_str: str) -> str:
    """
    문자열에서 모든 보이지 않는 문자(공백, 제어 문자 포함)를 제거
    """
    return ''.join(ch for ch in input_str if ch.isprintable())

import unicodedata
from fastapi import FastAPI, HTTPException
from urllib.parse import unquote

import re

def normalize_place_name(name: str) -> str:
    """
    입력된 이름을 S3에서 사용한 규칙에 맞게 변환
    """
    # 정규표현식을 사용하여 파일명을 S3 키에 맞게 변환
    match = re.match(r'^(.*?)(_.*)?$', name.strip(), re.IGNORECASE)
    if match:
        return match.group(1).strip()
    return name.strip()

@router.get("/images")
async def get_images(name: str):
    """
    특정 이름에 해당하는 이미지를 S3에서 가져와 리스트로 반환
    """
    s3_client = hosts.create_s3_client()  # S3 클라이언트 생성
    try:
        # 입력값 디코딩
        decoded_name = unquote(name).strip()
        print(f"Decoded name: {decoded_name}")  # 디버깅: 디코딩된 이름 출력

        # NFD/NFC 정규화 비교
        normalized_name_nfd = unicodedata.normalize("NFD", decoded_name)
        normalized_name_nfc = unicodedata.normalize("NFC", decoded_name)
        print(f"NFD Normalized: {normalized_name_nfd}")
        print(f"NFC Normalized: {normalized_name_nfc}")

        # Prefix 생성 (NFC 기준으로 생성)
        prefix = f"명소/{normalized_name_nfc}_"
        print(f"Prefix used for S3: {prefix}")

        # S3에서 Prefix로 파일 검색
        response = s3_client.list_objects_v2(Bucket=hosts.BUCKET_NAME, Prefix=prefix)
        print(f"S3 Response: {response}")  # 디버깅: S3 응답 확인

        # S3에 파일이 없는 경우
        if 'Contents' not in response or not response['Contents']:
            print(f"No files found for prefix: {prefix}")
            raise HTTPException(status_code=404, detail="No images found")

        # 검색된 파일 키 리스트
        image_keys = [content["Key"] for content in response["Contents"]]
        print(f"Found image keys: {image_keys}")  # 디버깅: 발견된 이미지 키 출력

        return {"images": image_keys}

    except ClientError as e:
        # S3 클라이언트 에러 처리
        print(f"ClientError while fetching images: {str(e)}")
        raise HTTPException(status_code=500, detail=f"ClientError fetching images: {str(e)}")
    except Exception as e:
        # 기타 에러 처리
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

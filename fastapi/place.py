from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from urllib.parse import unquote

import unicodedata, hosts


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
    단일 이미지를 S3에서 검색하고 스트리밍 반환
    """
    s3 = hosts.create_s3_client()
    try:
        # 입력값 정리 및 디코딩
        decoded_name = unquote(name).strip()
        normalized_name = normalize_name(decoded_name)
        prefix = f"{category}/{normalized_name}_"
        print(f"Original input: {repr(name)}")
        print(f"Decoded name: {decoded_name}")
        print(f"Normalized name: {normalized_name}")
        print(f"Using Prefix: {prefix}")

        # S3에서 파일 검색 (Prefix를 사용하여 제한)
        response = s3.list_objects_v2(Bucket=hosts.BUCKET_NAME, Prefix=prefix)
        if "Contents" not in response or not response["Contents"]:
            print(f"No images found for prefix: {prefix}")
            raise HTTPException(status_code=404, detail="Image not found")

        # 첫 번째 파일 키 가져오기
        file_key = response["Contents"][0]["Key"]
        print(f"Selected file key: {file_key}")

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

from fastapi import FastAPI, HTTPException, APIRouter,Query
from fastapi.responses import StreamingResponse
import user
from botocore.exceptions import ClientError


router = APIRouter()


@router.get('/restaurant_select_all')
async def select():
    redis = user.get_redis_connection()
    try:
        conn = user.connect()
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
async def get_booked_rating(name: str):
    conn = user.connect()
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

@router.get("/images/")
async def get_images(name: str):
    """
    특정 이름에 해당하는 이미지를 S3에서 가져와 리스트로 반환
    """
    s3_client = user.create_s3_client()
    try:
        # S3에서 해당 이름에 맞는 파일 검색
        response = s3_client.list_objects_v2(Bucket=user.BUCKET_NAME, Prefix=f"{name}_")
        if "Contents" not in response:
            raise HTTPException(status_code=404, detail="No images found")

        # 파일 키 리스트 생성
        file_keys = [content["Key"] for content in response["Contents"]]
        return {"images": file_keys}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/image/")
async def stream_image(file_key: str):
    """
    S3에서 단일 이미지 파일 스트리밍
    """
    s3_client = user.create_s3_client()
    try:
        s3_object = s3_client.get_object(Bucket=user.BUCKET_NAME, Key=file_key)
        return StreamingResponse(
            content=s3_object["Body"],
            media_type="image/jpeg"
        )
    except s3_client.exceptions.NoSuchKey:
        raise HTTPException(status_code=404, detail="File not found in S3")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
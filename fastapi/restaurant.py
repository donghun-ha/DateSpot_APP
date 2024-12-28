from fastapi import FastAPI, HTTPException, APIRouter,Query
from fastapi.responses import StreamingResponse
import user
from botocore.exceptions import ClientError


router = APIRouter()
app = FastAPI()


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

@app.get("/view/")
async def stream_image(file_keys: list[str] = Query(...)):
    """
    S3에서 이미지 파일들을 가져와 스트리밍 응답으로 반환
    """
    s3 = user.create_s3_client()
    responses = []
    for file_key in file_keys:
        try:
            # S3에서 객체 가져오기
            s3_object = s3.get_object(Bucket=user.BUCKET_NAME, Key=file_key)
            image_data = s3_object['Body']  # S3의 파일 스트림

            # 개별 이미지에 대한 응답 추가
            responses.append({
                "file_key": file_key,
                "image_data": image_data.read()  # 스트림 데이터를 읽어서 추가
            })
        except ClientError as e:
            if e.response['Error']['Code'] == "NoSuchKey":
                raise HTTPException(status_code=404, detail=f"File not found: {file_key}")
            else:
                raise HTTPException(status_code=500, detail=f"Error fetching file: {file_key}, {str(e)}")

    # 반환 형식 설정
    return [
        {
            "file_key": response["file_key"],
            "image_stream": StreamingResponse(
                content=response["image_data"],
                media_type="image/jpeg"  # 파일 타입에 따라 변경 가능 (image/png 등)
            )
        }
        for response in responses
    ]
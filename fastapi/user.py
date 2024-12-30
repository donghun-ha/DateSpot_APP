"""
Author : 하동훈
Description : 
<사용자 로그인 처리 로직>
Apple/Google 로그인 데이터 기반으로 Redis와 MySQL을 연동하여 사용자 데이터를 관리,
Apple 로그인 시 이메일 가리기 로직 처리.
Usage: 로그인 시 캐싱을 통한 반환 및 MySQL Insert 처리
"""

from fastapi import APIRouter, HTTPException, Request, File, Form, UploadFile
import uuid
import json, hosts


# FastAPI 라우터 생성
router = APIRouter()


@router.post("/login") 
async def user_login(request: Request):
    """
    사용자 로그인 요청 처리:
    1. Redis에서 사용자 데이터 검색
    2. Redis에 데이터가 없으면 MySQL에서 확인 후 추가
    3. Apple 이메일 가리기 로직 추가
    """
    print(f"로그인 요청 request : {request.body}")
    # 클라이언트에서 전송된 JSON
    data = await request.json()
    email = data.get("email")
    name = data.get("name")
    login_type = data.get("login_type")

    if not email:
        raise HTTPException(status_code=400, detail="email이 누락되었습니다.")
    
    if login_type == "apple":
        # Apple 로그인 처리
        if email.endswith("privaterelay.appleid.com"):
            user_identifier = data.get("user_identifier", email)  # Apple의 user_identifier 필드 사용
        else:
            user_identifier = email  # 실제 이메일이 제공된 경우 그대로 사용
    elif login_type == "google":
        # Google 로그인 처리
        user_identifier = email  # Google 이메일을 그대로 식별자로 사용
    else:
        raise HTTPException(status_code=400, detail="지원되지 않는 로그인 유형입니다.")

    # Redis 키 설정 (이메일 기반)
    redis_key = f"user:{user_identifier}"
    
    # Redis 연결
    redis = await hosts.get_redis_connection()

    # Redis에서 데이터 검색
    cached_user = await redis.get(redis_key)
    if cached_user:
        user_data = json.loads(cached_user)
        print("Redis에서 사용자 데이터를 반환")
        return {"source": "redis", "user_data": user_data}
    
    # Redis에 데이터가 없을 경우
    mysql_conn = hosts.connect()
    cursor = mysql_conn.cursor()

    try:
        # MySQL 사용자 확인
        query = "SELECT email, name, image, user_identifier FROM user WHERE email = %s"
        cursor.execute(query, (email,))
        user = cursor.fetchone()

        if user:
            print("MySQL 사용자 데이터")
            user_data = {
                "email": user[0],
                "name": user[1],
                "image": user[2],
                "user_identifier": user[3],
            }
            # Redis에 사용자 데이터 캐싱
            await redis.set(redis_key, str(user_data))
            return {"source": "mysql", "user_data": user_data}
        else:
            print("MySQL 사용자 데이터 없음")
            # MySQL에 새 사용자 추가
            insert_query = """
            INSERT INTO user (email, name, image, user_identifier)
            VALUES (%s, %s, %s, %s)
            """ 
            cursor.execute(insert_query, (email, name, None, user_identifier))
            mysql_conn.commit()

            user_data = {"email": email, "name": name}
            # Redis에 추가된 사용자 데이터 캐싱
            await redis.set(redis_key, json.dumps(user_data))
            return {"source": "mysql", "user_data": user_data}
    finally:
        cursor.close()
        mysql_conn.close()

@router.post("/upload-profile")
async def upload_profile_image(
    # Form은 클라이언트가 보내는 multipart/form-data 형식에서 user_id를 추출
    # str 타입으로 정의 되어있으며, Form(...)과 File(...)은 필수값임을 의미!
    # UploadFile은 클라이언트가 업로드한 파일을 처리하기 위한 FastAPI의 기본 데이터 유형
    # Package FastAPI에 추가해줘야함!
    user_id: str = Form(...), image: UploadFile = File(...)
):
    """
    프로필 이미지를 업로드하고 S3 URL을 MySQL에 저장
    1. 멀티파트로 전송된 이미지를 S3에 업로드
    2. S3 URL을 MySQL에 저장
    """
    try:
        # S3 클라이언트 생성
        s3_client = hosts.create_s3_client()
        region = hosts.REGIONE or "ap-northeast-2"

        # S3에 업로드할 파일 이름 생성
        file_extension = image.filename.split(".")[-1] #파일 확장자 추출
        file_name = f"profile_images/{uuid.uuid4()}.{file_extension}" # 고유 파일 이름 생성

        # S3에 파일 업로드
        s3_client.upload_fileobj(
            image.file, # 업로드할 파일 객체
            hosts.BUCKET_NAME, # S3 버킷 이름
            file_name, # S3에 저장될 파일 이름 및 경로
            ExtraArgs={"ContentType" : image.content_type, "ACL" : "public-read"}
        )

        # S3 URL 생성
        image_url = f"https://{hosts.BUCKET_NAME}.s3.{region}.amazonaws.com/{file_name}"
        print(image_url)


        # MySQL에 URL 저장
        mysql_conn = hosts.connect()
        cursor = mysql_conn.cursor()

        query ="""
        UPDATE user SET image = %s WHERE email = %s
        """
        cursor.execute(query, (image_url, user_id))
        mysql_conn.commit()
        cursor.close()
        mysql_conn.close()

        return {
            "status" : "success",
            "message" : "Profile image uploaded successfully",
            "image_url" : image_url
        }
    
    except Exception as e:
        print(f"Error uploading image: {e}")
        raise HTTPException(
            status_code=500, detail="Failed to upload profile image"
        )
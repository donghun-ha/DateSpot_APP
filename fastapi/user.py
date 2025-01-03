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
            INSERT INTO user (email, name, image, user_identifier, is_logged_in)
            VALUES (%s, %s, %s, %s, %s)
            """ 
            cursor.execute(insert_query, (email, name, None, user_identifier, 1))
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
    
    print(f"Received user_id: {user_id}")  # 디버깅 로그
    print(f"Received file name: {image.filename}")  # 파일 정보 출력
    print(f"Received file content type: {image.content_type}")


    """
    프로필 이미지를 업로드하고 S3 URL을 MySQL에 저장
    1. 멀티파트로 전송된 이미지를 S3에 업로드
    2. S3 URL을 MySQL에 저장
    """
    try:
        # S3 클라이언트 생성
        s3_client = hosts.create_s3_client()

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
        image_url = f"https://{hosts.BUCKET_NAME}.s3.ap-northeast-2.amazonaws.com/{file_name}"
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
    
@router.post("/get-profile-image")
async def get_profile_image(user_id: str = Form(...)):
    """
    사용자 이미지를 받아오는 엔드포인트
    """
    try:
        # MySQL에서 사용자 이미지 URL 가져오기
        mysql_conn = hosts.connect()
        cursor = mysql_conn.cursor()
        query = "SELECT image FROM user WHERE email = %s"
        cursor.execute(query, (user_id,))
        result = cursor.fetchone()
        cursor.close()
        mysql_conn.close()

        if result:
            return {"status": "success", "image_url": result[0]}
        else:
            raise HTTPException(status_code=404, detail="User not found")
    except Exception as e:
        print(f"Error fetching user image: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch user image")
    
@router.post("/logout")
async def logout(user_id: str = Form(...)):
    """
    - 사용자 로그아웃 처리 API
    - Redis 세션 삭제
    - MySQL 로그인 상태 업데이트
    """
    try:
        # Redis 세션 삭제
        redis = await hosts.get_redis_connection()
        redis_key = f"user:{user_id}"
        await redis.delete(redis_key)
        print(f"Redis 세션 삭제 완료: {redis_key}")

        # MySQL 로그인 상태 업데이트
        mysql_conn = hosts.connect()
        cursor = mysql_conn.cursor()
        query = "UPDATE user SET is_logged_in = 0 WHERE email = %s"
        cursor.execute(query, (user_id,))
        mysql_conn.commit()

        # MySQL에서 업데이트 된 행 확인
        if cursor.rowcount > 0:
            print(f"MySQL 로그인 상태 업데이트 완료:{user_id}")
            return {"status": "success", "message": "User logged out successfully"}
        else:
            raise HTTPException(status_code=404, detail="User not found")
    except Exception as e:
        print(f"Error logging out: {e}")
        raise HTTPException(status_code=500, detail="Failed to log out")
    finally:
        if cursor:
            cursor.close()
        if mysql_conn:
            mysql_conn.close()

@router.post("/account_delete")
async def account_delete(user_id: str = Form(...)):
    """
    사용자 계정을 삭제하는 엔드포인트
    """
    try:
        # MySQL에서 사용자 계정 탈퇴
        mysql_conn = hosts.connect() # MySQL 연결
        cursor = mysql_conn.cursor()
        # MySQL문 사용자 데이터 삭제
        query = """
        DELETE FROM user WHERE email = %s
        """
        cursor.execute(query, (user_id,))
        mysql_conn.commit()

        # Redis 캐시에서도 사용자 데이터 삭제
        redis = await hosts.get_redis_connection()
        redis_key = f"user:{user_id}"
        await redis.delete(redis_key)

        # 삭제 결과 확인
        if cursor.rowcount > 0:
            return {"status" : "success", "message": "Account deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail="User not found")
    except Exception as e:
        print(f"Error deleting account: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete account")
    finally:
        cursor.close()
        mysql_conn.close()
"""
Author : 하동훈
Description : 
<사용자 로그인 처리 로직>
Apple/Google 로그인 데이터 기반으로 MySQL을 연동하여 사용자 데이터를 관리,
Apple 로그인 시 이메일 가리기 로직 처리.
Usage: 로그인 시 MySQL Insert 처리
"""

from backend import APIRouter, HTTPException, Request, File, Form, UploadFile
import uuid
import json, hosts

# FastAPI 라우터 생성
router = APIRouter()

@router.post("/login") 
async def user_login(request: Request):
    """
    사용자 로그인 요청 처리:
    1. MySQL에서 사용자 데이터 검색
    2. MySQL에 데이터가 없으면 추가
    3. Apple 이메일 가리기 로직 추가
    """
    print(f"로그인 요청 request : {request.body}")
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
            return {"source": "mysql", "user_data": user_data}
    finally:
        cursor.close()
        mysql_conn.close()

@router.post("/upload-profile")
async def upload_profile_image(
    user_id: str = Form(...), image: UploadFile = File(...)
):
    """
    프로필 이미지를 업로드하고 S3 URL을 MySQL에 저장
    """
    print(f"Received user_id: {user_id}")
    print(f"Received file name: {image.filename}")
    print(f"Received file content type: {image.content_type}")

    try:
        # S3 클라이언트 생성
        s3_client = hosts.create_s3_client()

        # S3에 업로드할 파일 이름 생성
        file_extension = image.filename.split(".")[-1] 
        file_name = f"profile_images/{uuid.uuid4()}.{file_extension}"

        # S3에 파일 업로드
        s3_client.upload_fileobj(
            image.file,
            hosts.BUCKET_NAME,
            file_name,
            ExtraArgs={"ContentType": image.content_type, "ACL": "public-read"}
        )

        # S3 URL 생성
        image_url = f"https://{hosts.BUCKET_NAME}.s3.ap-northeast-2.amazonaws.com/{file_name}"
        print(image_url)

        # MySQL에 URL 저장
        mysql_conn = hosts.connect()
        cursor = mysql_conn.cursor()

        query = "UPDATE user SET image = %s WHERE email = %s"
        cursor.execute(query, (image_url, user_id))
        mysql_conn.commit()
        cursor.close()
        mysql_conn.close()

        return {
            "status": "success",
            "message": "Profile image uploaded successfully",
            "image_url": image_url
        }
    
    except Exception as e:
        print(f"Error uploading image: {e}")
        raise HTTPException(status_code=500, detail="Failed to upload profile image")

@router.post("/get-profile-image")
async def get_profile_image(user_id: str = Form(...)):
    """
    사용자 이미지를 받아오는 엔드포인트
    """
    try:
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
    - MySQL 로그인 상태 업데이트
    """
    try:
        mysql_conn = hosts.connect()
        cursor = mysql_conn.cursor()
        query = "UPDATE user SET is_logged_in = 0 WHERE email = %s"
        cursor.execute(query, (user_id,))
        mysql_conn.commit()

        if cursor.rowcount > 0:
            print(f"MySQL 로그인 상태 업데이트 완료:{user_id}")
            return {"status": "success", "message": "User logged out successfully"}
        else:
            raise HTTPException(status_code=404, detail="User not found")
    except Exception as e:
        print(f"Error logging out: {e}")
        raise HTTPException(status_code=500, detail="Failed to log out")
    finally:
        cursor.close()
        mysql_conn.close()

@router.post("/account_delete")
async def account_delete(user_id: str = Form(...)):
    """
    사용자 계정을 삭제하는 엔드포인트
    """
    try:
        mysql_conn = hosts.connect()
        cursor = mysql_conn.cursor()
        query = "DELETE FROM user WHERE email = %s"
        cursor.execute(query, (user_id,))
        mysql_conn.commit()

        if cursor.rowcount > 0:
            return {"status": "success", "message": "Account deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail="User not found")
    except Exception as e:
        print(f"Error deleting account: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete account")
    finally:
        cursor.close()
        mysql_conn.close()
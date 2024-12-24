"""
Author : 하동훈
Description : 
<사용자 로그인 처리 로직>
Apple/Google 로그인 데이터 기반으로 Redis와 MySQL을 연동하여 사용자 데이터를 관리,
Apple 로그인 시 이메일 가리기 로직 처리.
"""

import os
import pymysql , json
from redis.asyncio import Redis
from fastapi import APIRouter, HTTPException, Request

# FastAPI 라우터 생성
router = APIRouter()

# 환경 변수에서 불러오기
DB = os.getenv('DATESPOT_DB')
DB_USER = os.getenv('DATESPOT_DB_USER')
DB_PASSWORD = os.getenv('DATESPOT_DB_PASSWORD')
DB_TABLE = os.getenv('DATESPOT_DB_TABLE')
DB_PORT = os.getenv('DATESPOT_PORT')
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = os.getenv("REDIS_PORT")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")

# Redis client 초기화
redis_client = None

# Redis 연결 함수
async def get_redis_connection():
    """
    Redis 연결 초기화 및 기존 연결 반환
    """
    global redis_client
    if not redis_client:
        try:
            print("Initializing Redis connection...")
            # Redis 클라이언트 생성
            redis_client = Redis(
                host=REDIS_HOST,
                port=REDIS_PORT,
                decode_responses=True  # 문자열 디코딩 활성화
            )
            # 연결 테스트
            await redis_client.ping()
            print("Redis 연결 성공")
        except Exception as e:
            print(f"Redis 연결 실패: {e}")
            redis_client = None
            raise e
    return redis_client


def connect():
    """
    MySQL 데이터베이스 연결 및 반환
    """
    try:
        conn = pymysql.connect(
            host="3.34.18.250",
            user=DB_USER,
            password=DB_USER,
            charset='utf8',
            db=DB_TABLE,
            port=int(DB_PORT)
        )
        print("MySQL 연결 성공")
        return conn
    except Exception as e:
        print(f"MySQL 연결 실패: {e}")
        raise e

@router.post("/login") 
async def user_login(request: Request):
    """
    사용자 로그인 요청 처리"
    1. Redis에서 사용자 데이터 검색.
    2. Redis에 데이터가 없으면 MySQL에서 확인 후 추가
    3. Apple 이메일 가리기 로직 추가.
    """
    # 클라이언트에서 전송된 JSON
    data = await request.json()
    email = data.get("email")
    name = data.get("name")

    if not email:
        raise HTTPException(status_code=400, detail="email이 누락되었습니다.")
    
    # Apple 이메일 가리기 처리 로직
    if email.endswith("privaterelay.appleid.com"):
        email = email.split('@')[0] + "@hidden.appleid.com"

    # Reids 키 설정 (이메일 기반)
    redis_key = f"user:{email}"
    
    # Redis 연결
    redis = await get_redis_connection()

    # Redis에서 데이터 검색
    cached_user = await redis.get(redis_key)
    if cached_user:
        user_data = json.loads(cached_user)
        print("Redis에서 사용자 데이터를 반환")
        return {"source": "redis", "user_data": cached_user}
    
    # Redis에 데이터가 없을 경우
    mysql_conn = connect()
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
            return {"source" : "mysql", "user_data" : user_data}
        else:
            print("MySQL 사용자 데이터 없음")
            # MySQL에 새 사용자 추가
            insert_query = """
            INSERT INTO user (email, name, image, user_identifier)
            VALUES (%s, %s, NULL, NULL)
            """ 
            cursor.execute(insert_query, (email,name))
            mysql_conn.commit()

            user_data = {"email" : email, "name" : name}
            # Redis에 추가된 사용자 데이터 캐싱
            await redis.set(redis_key, json.dumps(user_data))
            return {"source" : "mysql", "user_data" : user_data}
    finally:
        cursor.close()
        mysql_conn.close()

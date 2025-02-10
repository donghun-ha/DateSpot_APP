from fastapi import HTTPException
import os
import pymysql 
from redis.asyncio import Redis
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

# 환경 변수에서 불러오기
AWS_ACCESS_KEY = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
BUCKET_NAME = os.getenv('BUCKET_NAME')
REGION = os.getenv('AWS_REGION')
DB = os.getenv('DATESPOT_DB')
DB_USER = os.getenv('DATESPOT_DB_USER')
DB_PASSWORD = os.getenv('DATESPOT_DB_PASSWORD')
DB_TABLE = os.getenv('DATESPOT_DB_TABLE')
DB_PORT = os.getenv('DATESPOT_PORT')
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = os.getenv("REDIS_PORT")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")


def create_s3_client():

    if not AWS_SECRET_KEY or not AWS_SECRET_KEY:
        raise HTTPException(status_code=400, detail="AWS credentials are not set in environment variables.")

    try:
        s3 = boto3.client(
            's3',
            aws_access_key_id=AWS_ACCESS_KEY,
            aws_secret_access_key=AWS_SECRET_KEY,
            region_name=REGION
        )
        return s3
    except (NoCredentialsError, PartialCredentialsError) as e:
        raise HTTPException(status_code=401, detail=f"AWS credentials error: {str(e)}")
    

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
                host='datespot-redis.a4ifxd.ng.0001.apn2.cache.amazonaws.com',
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
    print(f"환경변수 : {os.getenv('DATESPOT_DB_PASSWORD')}")
    print(DB_USER)
    print(DB_PORT)
    try:
        conn = pymysql.connect(
            host="svc.sel4.cloudtype.app",
            user=DB_USER,
            password=DB_PASSWORD,
            charset='utf8',
            db=DB_TABLE,
            port=32176
        )
        print("MySQL 연결 성공")
        return conn
    except Exception as e:
        print(f"MySQL 연결 실패: {e}")
        raise e
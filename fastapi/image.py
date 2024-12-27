"""
author: 하동훈
Description: 이미지 S3 연동
Fixed: 24.12.27
Usage: AWS S3에서 이미지 불러오기
"""

import user
import boto3


s3 = boto3.client(
    's3',
    aws_access_key_id=user.AWS_ACCESS_KEY,
    aws_secret_acces_key=user.AWS_SECRET_KEY,
    region_name=user.REGION
)
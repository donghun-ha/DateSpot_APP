"""
author: 하동훈
Description: 이미지 S3 연동
Fixed: 24.12.27
Usage: AWS S3에서 이미지 불러오기
"""

import hosts
import boto3


s3 = boto3.client(
    's3',
    aws_access_key_id=hosts.AWS_ACCESS_KEY,
    aws_secret_acces_key=hosts.AWS_SECRET_KEY,
    region_name=hosts.REGION
)
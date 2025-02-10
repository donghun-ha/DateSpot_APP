# 최신 Python 3.12 slim 버전 사용
FROM python:3.12-slim

# 작업 디렉토리 설정
WORKDIR /DATESPOT

# 모든 파일 복사
COPY . .

# FastAPI 종속성 설치
RUN pip install --no-cache-dir -r requirements.txt

# FastAPI가 실행될 폴더로 이동
WORKDIR /DATESPOT/backend

# 컨테이너에서 사용할 포트 지정
EXPOSE 8000

# FastAPI 실행
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
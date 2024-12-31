"""
작성자: 하동훈  
작성일시: 2024-11-21  
파일 내용: 여의도와 뚝섬 한강공원의 주차 예측 및 혼잡도 계산을 위한 FastAPI 서버 구현.  
          - 이용시간 및 주차대수 예측 모델을 사용하여 혼잡도를 계산.  
          - 두 공원의 입력 데이터를 구분하여 처리.  
usage: 'http://127.0.0.1:8000/predict/predict_yeouido'
usage: 'http://127.0.0.1:8000/predict/predict_ttukseom'
"""

from fastapi import APIRouter, FastAPI
from pydantic import BaseModel
import pandas as pd
import numpy as np
import joblib
import requests
import json
import time
from fastapi.responses import JSONResponse

app = FastAPI()
router = APIRouter()

# 모델 및 피처 로드 (여의도)
yeouido_usage_model = joblib.load('../Data/Yeouido_usage_model.pkl')
yeouido_parking_model = joblib.load('../Data/Yeouido_parking_model.pkl')
yeouido_features_usage = joblib.load('../Data/Yeouido_features_usage.pkl')
yeouido_features_parking = joblib.load('../Data/Yeouido_features_parking.pkl')

# 모델 및 피처 로드 (뚝섬)
ttukseom_usage_model = joblib.load('../Data/Ttukseom_usage_model.pkl')
ttukseom_parking_model = joblib.load('../Data/Ttukseom_parking_model.pkl')
ttukseom_features_usage = joblib.load('../Data/Ttukseom_features_usage.pkl')
ttukseom_features_parking = joblib.load('../Data/Ttukseom_features_parking.pkl')

# 입력 데이터 스키마 정의 (여의도)
class YeouidoFeatures(BaseModel):
    요일: int # 0월 ~ 6일
    휴일여부: int
    주차장명: str
    연도: int
    월: int
    일: int
    주차구획수: int

# 입력 데이터 스키마 정의 (뚝섬)
class TtukseomFeatures(BaseModel):
    요일: int # 0월 ~ 6일
    휴일여부: int
    주차장명: str
    연도: int
    월: int
    최고기온: float # api 로 불러오기
    주차구획수: int

def calculate_congestion(parking_count, capacity):
    ratio = parking_count / capacity
    if ratio <= 0.5:
        return '여유'
    elif ratio <= 0.8:
        return '보통'
    elif ratio <= 1.0:
        return '혼잡'
    else:
        return '만차'

def convert_to_python_type(data):
    """
    numpy 타입을 Python 타입으로 변환합니다.
    """
    if isinstance(data, (list, tuple)):
        return [float(item) if isinstance(item, (np.float32, np.float64)) else item for item in data]
    elif isinstance(data, (np.float32, np.float64)):
        return float(data)
    return data

@app.post("/predict_yeouido")
async def predict_yeouido(features: YeouidoFeatures):
    # 입력 데이터를 DataFrame으로 변환
    input_data = pd.DataFrame([features.model_dump()])

    # 입력 데이터 원-핫 인코딩
    input_encoded = pd.get_dummies(input_data)

    # 누락된 피처를 모델이 필요로 하는 피처 세트에 맞게 추가
    for missing_feature in set(yeouido_features_usage) - set(input_encoded.columns):
        input_encoded[missing_feature] = 0

    # 불필요한 피처 제거 (예: 주차구획수는 혼잡도 계산에만 사용)
    input_encoded = input_encoded[yeouido_features_usage]

    # 이용시간 예측
    predicted_usage = yeouido_usage_model.predict(input_encoded)

    # 예측된 이용시간을 입력 피처에 추가
    input_with_usage = pd.concat([
        input_encoded,
        pd.DataFrame(predicted_usage, columns=['예측 아침 이용시간', '예측 낮 이용시간', '예측 저녁 이용시간'])
    ], axis=1)

    # 주차대수 예측
    for missing_feature in set(yeouido_features_parking) - set(input_with_usage.columns):
        input_with_usage[missing_feature] = 0

    input_with_usage = input_with_usage[yeouido_features_parking]
    predicted_parking = yeouido_parking_model.predict(input_with_usage)

    # 혼잡도 계산
    congestion_results = {
        "예측 아침 혼잡도": calculate_congestion(predicted_parking[0][0], 100),
        "예측 낮 혼잡도": calculate_congestion(predicted_parking[0][1], 100),
        "예측 저녁 혼잡도": calculate_congestion(predicted_parking[0][2], 100)
    }

    # 데이터를 Python 기본 타입으로 변환
    predicted_usage = convert_to_python_type(predicted_usage.tolist())
    predicted_parking = convert_to_python_type(predicted_parking.tolist())
    congestion_results = convert_to_python_type(congestion_results)
    print(predicted_parking[0][0])
    print(predicted_parking[0][1])
    print(predicted_parking[0][2])
    # 결과 반환
    return {
        "예측 이용시간": {
            "아침": predicted_usage[0][0],
            "낮": predicted_usage[0][1],
            "저녁": predicted_usage[0][2]
        },
        "예측 주차대수": {
            "아침": predicted_parking[0][0],
            "낮": predicted_parking[0][1],
            "저녁": predicted_parking[0][2]
        },
        "혼잡도": congestion_results
    }

@app.post("/predict_ttukseom")
async def predict_ttukseom(features: TtukseomFeatures):
    # 입력 데이터를 DataFrame으로 변환
    input_data = pd.DataFrame([features.model_dump()])

    # 입력 데이터 원-핫 인코딩
    input_encoded = pd.get_dummies(input_data)

    # 누락된 피처를 모델이 필요로 하는 피처 세트에 맞게 추가
    for missing_feature in set(ttukseom_features_usage) - set(input_encoded.columns):
        input_encoded[missing_feature] = 0

    # 불필요한 피처 제거 (예: 주차구획수는 혼잡도 계산에만 사용)
    input_encoded = input_encoded[ttukseom_features_usage]

    # 이용시간 예측
    predicted_usage = ttukseom_usage_model.predict(input_encoded)

    # 예측된 이용시간을 입력 피처에 추가
    input_with_usage = pd.concat([
        input_encoded,
        pd.DataFrame(predicted_usage, columns=['예측 아침 이용시간', '예측 낮 이용시간', '예측 저녁 이용시간'])
    ], axis=1)

    # 주차대수 예측
    for missing_feature in set(ttukseom_features_parking) - set(input_with_usage.columns):
        input_with_usage[missing_feature] = 0

    input_with_usage = input_with_usage[ttukseom_features_parking]
    predicted_parking = ttukseom_parking_model.predict(input_with_usage)

    # 혼잡도 계산
    congestion_results = {
        "예측 아침 혼잡도": calculate_congestion(predicted_parking[0][0], features.주차구획수),
        "예측 낮 혼잡도": calculate_congestion(predicted_parking[0][1], features.주차구획수),
        "예측 저녁 혼잡도": calculate_congestion(predicted_parking[0][2], features.주차구획수)
    }

    # 데이터를 Python 기본 타입으로 변환
    predicted_usage = convert_to_python_type(predicted_usage.tolist())
    predicted_parking = convert_to_python_type(predicted_parking.tolist())
    congestion_results = convert_to_python_type(congestion_results)

    # 결과 반환
    return {
        "예측 이용시간": {
            "아침": predicted_usage[0][0],
            "낮": predicted_usage[0][1],
            "저녁": predicted_usage[0][2]
        },
        "예측 주차대수": {
            "아침": predicted_parking[0][0],
            "낮": predicted_parking[0][1],
            "저녁": predicted_parking[0][2]
        },
        "혼잡도": congestion_results
    }


def fetch_data(url: str):
    """
    지정된 URL로 GET 요청을 보내고 JSON 데이터를 반환합니다.
    :param url: 요청할 API URL
    :return: 응답 JSON 데이터 또는 None
    """
    response = requests.get(url)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}")
        return None

# 실시간 인구 및 혼잡도 정보 추출 함수
# def extract_congestion_info(city_data: dict):
#     """
#     실시간 인구 및 혼잡도 정보를 추출합니다.
#     :param city_data: CITYDATA 키로부터 가져온 데이터
#     :return: 정리된 혼잡도 정보 딕셔너리
#     """
#     return {
#         "장소명": city_data.get("AREA_NM", "정보 없음"),
#         "장소 코드": city_data.get("AREA_CD", "정보 없음"),
#     }

# 주차장 중복 제거 및 최신 정보 선택 함수
def extract_unique_parking_info(city_data: dict):
    """
    중복된 주차장 데이터를 제거하고 최신 데이터를 반환합니다.
    :param city_data: CITYDATA 키로부터 가져온 데이터
    :return: 고유 주차장 리스트
    """
    parking_data = city_data.get("PRK_STTS", [])
    unique_parking = {}

    for prk in parking_data:
        key = (prk.get("PRK_NM"), prk.get("PRK_CD"))
        if key not in unique_parking or prk.get("CUR_PRK_TIME"):
            unique_parking[key] = prk

    return list(unique_parking.values())

# 날씨 현황 정보 추출 함수
def extract_weather_info(city_data: dict):
    """
    날씨 정보를 추출합니다.
    :param city_data: CITYDATA 키로부터 가져온 데이터
    :return: 정리된 날씨 정보 딕셔너리
    """
    weather_data = city_data.get('WEATHER_STTS', [])
    weather_info = weather_data[0] if weather_data else {}
    
    return {
        "최고기온": weather_info.get("MAX_TEMP", "정보 없음"),
        "최저기온": weather_info.get("MIN_TEMP", "정보 없음"),
        "습도": weather_info.get("HUMIDITY", "정보 없음"),
        "풍향": weather_info.get("WIND_DIRCT", "정보 없음"),
        "풍속": weather_info.get("WIND_SPD", "정보 없음"),
        "강수량": weather_info.get("PRECIPITATION", "정보 없음"),
        "강수형태": weather_info.get("PRECPT_TYPE", "정보 없음"),
        "하늘상태": weather_info.get("SKY_STTS", "정보 없음"),
        "날씨 메시지": weather_info.get("AIR_MSG", "정보 없음"),
    }


# 전체 데이터 처리 함수
def process_city_data(data: dict):
    """
    CITYDATA 키에서 필요한 데이터를 처리합니다.
    :param data: API에서 반환된 전체 JSON 데이터
    :return: 정리된 데이터 딕셔너리
    """
    city_data = data.get('CITYDATA', {})
    # congestion_info = extract_congestion_info(city_data)
    unique_parking_list = extract_unique_parking_info(city_data)
    weather_info = extract_weather_info(city_data)

    return {
        # **congestion_info,
        "주차장 현황": unique_parking_list,
        **weather_info
    }

# FastAPI 엔드포인트
@app.get("/citydata/{pname}")
async def get_city_data(pname: str):
    """
    특정 지역의 실시간 데이터를 반환합니다.
    :param pname: 요청할 지역 이름
    :return: 실시간 데이터 (JSON 형식)
    """
    start_time = time.time()
    url = f'http://openapi.seoul.go.kr:8088/434675486868617235394264587a4e/json/citydata/1/1000/{pname}'
    data = fetch_data(url)

    if data:
        processed_data = process_city_data(data)
        end_time = time.time()
        print(f"코드 실행 시간: {end_time - start_time:.4f}초")
        return JSONResponse(content=processed_data, status_code=200)
    else:
        return JSONResponse(content={"error": "데이터를 가져오는 데 실패했습니다."}, status_code=500)

if __name__ == "__main__":
    import uvicorn 
    uvicorn.run(app,host="127.0.0.1", port=8000)
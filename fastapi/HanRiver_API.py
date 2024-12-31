"""
작성자: 하동훈
작성일시: 2024-11-21
파일 내용: 실시간 데이터를 FastAPI로 처리하여 Flutter로 전달.
usage: 'http://127.0.0.1:8000/hanriver/citydata/{pname}'
"""

import requests
import json
import time
from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter()

# API 데이터 요청 함수
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
@router.get("/citydata/{pname}")
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

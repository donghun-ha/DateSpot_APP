
"""
author: 신정섭
Description: 식당 라우터
Fixed: 24.12.26
Usage: 식당 정보 불러오는 라우터
"""


from fastapi import APIRouter
import user 
import json



router = APIRouter()



@router.get('/restaurant_select_all')
async def select():
    # redis 조회 키값 생성
    redis_key = "restaurant_select_all"

    # redis 인스턴스 생성
    redis = await user.get_redis_connection()

    # redis 데이터 조회
    cached_redis = await redis.get(redis_key)
    if cached_redis:
        restaurant_all = json.loads(cached_redis)
        print("already exist restaurant_select_all")
        return {"where": "redis", "restaurant_select_all": restaurant_all}
    
    # 데이터 없을경우 mysql 접속
    try:
        conn = user.connect()
        curs = conn.cursor()
        sql = "select * from restaurant"
        curs.execute(sql)
        data = curs.fetchall()
        
        # mysql에 데이터가 존재할 경우
        if data :
            result = []
            for i in data : 
                result.append(
            {
                'name' : i[0],
                'address' : i[1],
                'lat' : i[2],
                'lng' : i[3],
                'parking' : i[4],
                'operating_hour' : i[5],
                'closed_days' : i[6],
                'contact_info' : i[7],
                'break_time' : i[8],
                'last_order' : i[9]
            }
                )
            await redis.set(redis_key, str(result))
            return {"where" : 'mysql', "result" : result}
    except Exception as e :
        print("restaurant.py select Error")
        return {"restaurant.py select Error" : e}
    




    
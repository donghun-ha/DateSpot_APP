from fastapi import APIRouter, FastAPI
import pymysql 
import os
import user 



router = APIRouter()
app = FastAPI()



# def connect():
#     try:
#         conn = pymysql.connect(
#             host="3.34.18.250",
#             user="datespot",
#             password="qwer1234",
#             charset='utf8',
#             db="datespot",
#             port=3306
#         )
#         print("MYSQL Connect Success")
#         return conn
#     except Exception as e:
#         print(f"MYSQL Connect Error  {e}")
#         return e


@router.get('/restaurant_select_all')
async def select():
    redis = user.get_redis_connection()


    try:
        conn = user.connect()
        curs = conn.cursor()
        sql = "select * from restaurant"
        curs.execute(sql)
        data = curs.fetchall()
        print(data)
        return data
    except Exception as e :
        print("restaurant.py select Error")
        return {"restaurant.py select Error" : e}
    

from fastapi import APIRouter, FastAPI, HTTPException 
import pymysql 
import os
import user 



router = APIRouter()
app = FastAPI()


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
    

@router.get('/')
async def get_booked_rating(name: str):
    conn = user.connect()
    curs = conn.cursor()

    sql = "SELECT * FROM restaurant WHERE name = %s"
    curs.execute(sql, (name,))
    rows = curs.fetchall()
    conn.close()

    if not rows:
        raise HTTPException(status_code=404, detail="Not Found")
    
    # 데이터를 매핑하여 반환
    results = [
        {
            "name": row[0],
            "address": row[1],
            "lat": row[2],
            "lng": row[3],
            "description": row[4],
            "contactInfo": row[5],
            "operatingHour": row[6],
            "parking": row[7],
            "closingTIme": row[8]
        }
        for row in rows
    ]
    
    return {"results": results}
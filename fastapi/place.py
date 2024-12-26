from fastapi import APIRouter, File, UploadFile
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import pymysql


router = APIRouter()

def connect():
    # MySQL Connection
    conn = pymysql.connect(
        host='3.34.18.250',
        user='datespot',
        password='qwer1234',
        db='datespot',
        charset='utf8'
    )
    return conn


@router.get("/select")
async def select():
    conn = connect()
    curs = conn.cursor()

    # SQL 문장
    sql = "SELECT * FROM place"
    curs.execute(sql)
    rows = curs.fetchall()
    conn.close()
    print(rows)
    dict_list = []
    for row in rows:
        dict_list.append(
            {
                'name' : row[0],
                'address' : row[1],
                'lat' : row[2],
                'lng' : row[3],
                'description' : row[4],
                'contact_info' : row[5],
                'operating_hour' : row[6],
                'parking' : row[7],
                'closing_time' : row[8]
            }
        )
    return dict_list

from fastapi import FastAPI 
import pymysql 

app = FastAPI()

def connect():
    conn = pymysql.connect(
        host='127.0.0.1',
        user='datespot',
        password='qwer1234',
        db='datespot',
        charset='utf8'
    )
    return conn

# @app.get("/select")
# async def select():
#     conn = connect()
#     curs = conn.cursor()  # 결과물을 알고 있는것이 cursor()

#     sql = "select seq, todo, time, image from todolist"
#     curs.execute(sql)
#     rows = curs.fetchall()
#     conn.close()
#     print(rows)

    # 결과값을 Dictionary로 변환
    # result = []
    # for row in rows:
    #     tempDict = {
    #         'seq'  : row[0],
    #         'todo' : row[1],
    #         'time' : row[2],
    #         'image': row[3]
    #     }
    #     result.append(tempDict)

    # result = [{'code' : rows[0], 'name' : rows[1], 'dept' : rows[2], 'phone' : rows[3]}]
    # return {'result' : result}
#     return {'results':rows}

# @app.get('/insert')
# async def insert(todo: str=None, time: str=None, image: str=None):
#     conn = connect()
#     curs = conn.cursor()

#     try:# 데이터베이스는 자기것이 아니라 다른데것이라  
#         sql = 'insert into todolist(todo, time, image) values (%s,%s,%s)'
#         curs.execute(sql, (todo, time, image))
#         conn.commit()
#         conn.close()
#         return {'result' : 'OK'}
#     except Exception as e:
#         conn.close()
#         print("Error:", e)
#         return {'result':'Error'}

# @app.get('/delete')
# async def delete(seq: int=None):
#     conn = connect()
#     curs = conn.cursor()

#     try:
#         sql = 'delete from todolist where seq=%s'
#         curs.execute(sql,(seq))
#         conn.commit()
#         conn.close()
#         return {'result': 'OK'}
#     except Exception as e:
#         conn.close()
#         print("Error:",e)
#         return {'result':'Error'}
    

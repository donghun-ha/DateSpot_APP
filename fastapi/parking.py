from fastapi import APIRouter
import hosts



router =  APIRouter()


# @app.get('/api_parkinginfo')
# def fetch_pakring(): # 자치구 입력
#     try:
#         url = f'http://openapi.seoul.go.kr:8088/496c726e54746c733132325669414e57/json/GetParkingInfo/3/1000'
#         response = requests.get(url=url)
#         data = response.json()
#         results = data["GetParkingInfo"]["row"]
#         unique_parking = {row["PKLT_CD"]: row for row in results}.values()
#         data = []
#         for result in unique_parking :
#             data.append({
#             "name" : result['PKLT_NM'],
#             "address" : result["ADDR"],
#             "latitude" : result["LAT"],
#             "longitude" : result["LOT"]
#             })
#         print(data.__len__())
#         return {"result" : data}
#     except Exception as e :
#         print("parking_info", e)
#         return {"result" : e}







@router.get("/select_parkinginfo")
async def select():
    try:
        conn = hosts.connect()
        curs = conn.cursor()
        sql = "select * from parking"
        curs.execute(sql)
        data = curs.fetchall()  
        results = []
        for row in data:
            results.append({
                "name": row[0],       
                "address": row[1],    
                "latitude": row[2],   
                "longitude": row[3]   
            })
        return {"result": results}
    except Exception as e:
        print("parking.py select Error", e)
        return {"parking.py select Error": str(e)}



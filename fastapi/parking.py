from fastapi import APIRouter
import hosts

router =  APIRouter()

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
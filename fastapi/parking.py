from fastapi import APIRouter, FastAPI
import requests


router =  APIRouter()
app = FastAPI()

@app.get('/select_parkinginfo')
def fetch_pakring(region : str): # 자치구 입력
    try:
        url = f'http://openapi.seoul.go.kr:8088/496c726e54746c733132325669414e57/json/GetParkingInfo/1/100/{region}'
        response =  requests.get(url=url)
        data = response.json()
        results = data["GetParkingInfo"]["row"]
        data = []
        for result in results :
            data.append({
            "name" : result['PKLT_NM'],
            "address" : result["ADDR"],
            "lat" : result["LAT"],
            "lng" : result["LOT"]
            })
        return {"result" : data}
    except Exception as e :
        print("parking_info", e)
        return {"result" : e}
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)

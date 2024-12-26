"""
author: 이원영
Description: 별점 라우터
Fixed: 24.12.26
Usage: 별점 읽어오고 별점 수정하기 기능을 제공하는 라우터
"""

from fastapi import APIRouter, HTTPException 
import hosts
router = APIRouter()

# Detail Page에서 별점을 메긴 기록이 있으면 별점 가져오기
@router.get('/')
async def get_booked_rating(user_email: str):
    conn = hosts.connect()
    curs = conn.cursor()

    sql = "SELECT * FROM rating WHERE user_email = %s"
    curs.execute(sql, (user_email,))
    rows = curs.fetchall()
    conn.close()

    if not rows:
        raise HTTPException(status_code=404, detail="즐겨찾기 병원이 없습니다.")
    
    return {'results': rows}
"""
author: 이원영
Description: 별점 라우터
Fixed: 24.12.26
Usage: 별점 읽어오고 별점 수정하기 기능을 제공하는 라우터
"""

from fastapi import APIRouter, HTTPException 
import hosts
from pydantic import BaseModel

router = APIRouter()

# Detail Page에서 별점을 메긴 기록이 있으면 별점 가져오기
@router.get('/get_detail')
async def get_booked_rating(user_email: str, book_name):
    """
    Detail 페이지로 갈 때 같이 가져올 별점을 query하는 엔드포인트
    """
    conn = hosts.connect()
    curs = conn.cursor()

    sql = "SELECT * FROM rating WHERE user_email = %s and book_name = %s"
    curs.execute(sql, (user_email, book_name))
    rows = curs.fetchall()
    conn.close()

    if not rows:
        raise HTTPException(status_code=404, detail="해당 페이지에 해당하는 별점이 없습니다.")
    
    # 데이터를 매핑하여 반환
    results = [
        {
            "id": row[0],
            "userEmail": row[1],
            "bookName": row[2],
            "evaluation": row[3]
        }
        for row in rows
    ]
    
    return {"results": results}

# 별점 데이터를 위한 Pydantic 모델
class Rating(BaseModel):
    userEmail: str
    bookName: str
    evaluation: float

# 별점 업데이트하는 api
@router.post("/update_detail")
async def update_booked_rating(rating: Rating):
    """
    터치해서 별점을 업데이트 할떄 작동하는 엔드포인트
    """
    conn = hosts.connect()
    curs = conn.cursor()

    # 기존 데이터 확인
    check_sql = """
        SELECT * FROM rating WHERE user_email = %s AND book_name = %s
    """
    curs.execute(check_sql, (rating.userEmail, rating.bookName))
    row = curs.fetchone()

    if row:
        # 기존 데이터가 있는 경우 업데이트
        update_sql = """
            UPDATE rating
            SET evaluation = %s
            WHERE user_email = %s AND book_name = %s
        """
        curs.execute(update_sql, (rating.evaluation, rating.userEmail, rating.bookName))
    else:
        # 기존 데이터가 없는 경우 삽입
        insert_sql = """
            INSERT INTO rating (user_email, book_name, evaluation)
            VALUES (%s, %s, %s)
        """
        curs.execute(insert_sql, (rating.userEmail, rating.bookName, rating.evaluation))

    conn.commit()
    conn.close()

    return {"message": "Rating updated successfully"}
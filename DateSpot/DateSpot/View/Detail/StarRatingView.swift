//
//  StarRatingView.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//
import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    var onRatingChanged: ((Int) -> Void)? // 별점 변경 시 실행할 클로저

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray)
                    .onTapGesture {
                        rating = star
                        onRatingChanged?(star) // 별점 변경 이벤트 호출
                    }
            }
        }
    }
}

//
//  StarRatingView.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//
import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int // 현재 별점
    let maxRating: Int = 5 // 최대 별점

    var body: some View {
        GeometryReader { geometry in
            let starSize = min(geometry.size.width / CGFloat(maxRating), geometry.size.height) // 별 크기 계산
            let spacing = starSize / 10 // 간격 계산

            HStack(spacing: spacing) {
                ForEach(1...maxRating, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.yellow)
                        .frame(width: starSize, height: starSize)
                        .onTapGesture {
                            rating = star // 별을 탭했을 때 별점 업데이트
                        }
                }
            }
        }
    }
}



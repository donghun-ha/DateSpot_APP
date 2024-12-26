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

struct ContentView: View {
    @State private var rating: Int = 3 // 기본 별점

    var body: some View {
        VStack(spacing: 20) {
            Text("Rating: \(rating)")
                .font(.headline)

            // 크기 지정하여 StarRatingView 사용
            StarRatingView(rating: $rating)
                .frame(width: 200, height: 40) // 크기 지정
                .background(Color.gray.opacity(0.2)) // 배경 확인용
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

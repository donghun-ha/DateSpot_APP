//
//  SocialLoginButton.swift
//  DateSpot
//
//  Created by 이종남 on 26/12/2024.
//

import SwiftUI

struct ContentView: View {
    
    let restaurantData = [
        Restaurant(image: "w1", category: "한식", name: "김치찌개 맛집", description: "한국의 전통 음식을 맛볼 수 있는 곳"),
        Restaurant(image: "w2", category: "일식", name: "스시야", description: "신선한 초밥이 유명한 레스토랑"),
        Restaurant(image: "w3", category: "양식", name: "스테이크 하우스", description: "부드러운 스테이크와 와인을 즐길 수 있는 곳"),
        Restaurant(image: "w4", category: "중식", name: "짜장면 전문점", description: "수제 짜장면과 탕수육이 유명한 곳")
    ]

    let spotData = [
        Spot(image: "w5", category: "박물관", name: "역사 박물관", description: "한국의 역사를 알 수 있는 명소"),
        Spot(image: "w6", category: "자연", name: "도심 공원", description: "도심 속에서 자연을 느낄 수 있는 공간"),
        Spot(image: "w7", category: "테마파크", name: "놀이공원", description: "아이들과 함께 즐기기 좋은 장소"),
        Spot(image: "w8", category: "랜드마크", name: "전망대", description: "도시를 한눈에 볼 수 있는 명소")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 맛집 섹션
                Text("맛집")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(restaurantData) { restaurant in
                            CardView(
                                image: restaurant.image,
                                category: restaurant.category,
                                heading: restaurant.name,
                                author: restaurant.description
                            )
                            .frame(width: 300) // 카드 너비 설정
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 명소 섹션
                Text("추천 명소")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(spotData) { spot in
                            CardView(
                                image: spot.image,
                                category: spot.category,
                                heading: spot.name,
                                author: spot.description
                            )
                            .frame(width: 300) // 카드 너비 설정
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct CardView: View {
    var image: String
    var category: String
    var heading: String
    var author: String

    var body: some View {
        VStack(alignment: .leading) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
                .clipped()
            
            VStack(alignment: .leading) {
                Text(category)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text(heading)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(author)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct Restaurant: Identifiable {
    var id = UUID()
    var image: String
    var category: String
    var name: String
    var description: String
}

struct Spot: Identifiable {
    var id = UUID()
    var image: String
    var category: String
    var name: String
    var description: String
}


#Preview {
    ContentView()
}


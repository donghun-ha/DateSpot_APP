//
//  SocialLoginButton.swift
//  DateSpot
//
//  Created by 이종남 on 26/12/2024.
//

import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var viewModel = RestaurantViewModel() // 뷰모델 연결
    
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
                        // 레스토랑 데이터를 ForEach로 생성
                        ForEach(viewModel.restaurants, id: \.self) { restaurant in
                            CardView(
//                                image: "w1",               // 실제로는 모델에 맞춰 변경
                                category: restaurant.parking, // ex) 주차 가능/불가
                                heading: restaurant.name,     // ex) 식당 이름
                                author: restaurant.address    // or contactInfo 등 원하는 정보
                            )
                            .frame(width: 300)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            // 화면 나타날 때 JSON 로드
            viewModel.fetchRestaurants()
        }
    }
}

struct CardView: View {
//    var image: String
    var category: String
    var heading: String
    var author: String

    var body: some View {
        VStack(alignment: .leading) {
//            Image(image)
//                .resizable()
//                .scaledToFill()
//                .frame(height: 150)
//                .clipped()
//            
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

// MARK: - 미리보기
#Preview {
    ContentView()
}


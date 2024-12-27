//
//  SocialLoginButton.swift
//  DateSpot
//
//  Created by 이종남 on 26/12/2024.
//

import SwiftUI

import SwiftUI

// MARK: - 모델 정의


// 서버나 로컬 JSON 구조가 {"restaurants": [...], "places": [...]} 형태라고 가정
struct DataModel: Decodable {
    let restaurants: [Restaurant]
    let places: [PlaceData]
}

// MARK: - 메인 ContentView
struct ContentView: View {
    @State private var restaurants: [Restaurant] = []
    @State private var places: [PlaceData] = []
    
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
                        ForEach(restaurants, id: \.self) { restaurant in
                            CardView(
                                image: "w1",                  // 실제로는 모델에 맞춰 변경
                                category: restaurant.parking, // ex) 주차 가능/불가
                                heading: restaurant.name,     // ex) 식당 이름
                                author: restaurant.address    // or contactInfo 등 원하는 정보
                            )
                            .frame(width: 300)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 추천 명소 섹션
                Text("추천 명소")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 20) {
//                        ForEach(places, id: \.self) { place in
//                            CardView(
//                                image: "w5",                      // 실제로는 모델에 맞춰 변경
//                                category: place.parking,          // ex) "가능" / "불가"
//                                heading: place.name,              // 명소 이름
//                                author: place.description         // 명소 설명
//                            )
//                            .frame(width: 300)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
            }
            .padding(.vertical)
        }
        .onAppear {
            // 화면 나타날 때 JSON 로드
            fetchDataFromServer()
            // 또는 loadLocalJSON() 등으로 대체
        }
    }
    
    // MARK: - 서버에서 JSON 로드 (예시)
    func fetchDataFromServer() {
        guard let url = URL(string: "https://example.com/api/data") else {
            print("URL이 올바르지 않습니다.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("네트워크 에러:", error.localizedDescription)
                return
            }
            guard let data = data else {
                print("데이터가 없습니다.")
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(DataModel.self, from: data)
                // 메인 스레드에서 UI 업데이트
                DispatchQueue.main.async {
                    self.restaurants = decoded.restaurants
                    self.places = decoded.places
                }
            } catch {
                print("JSON 디코딩 에러:", error.localizedDescription)
            }
        }.resume()
    }
    
    // MARK: - 로컬 JSON 로드 (선택 예시)
    // func loadLocalJSON() {
    //     guard let url = Bundle.main.url(forResource: "data", withExtension: "json") else {
    //         print("로컬 JSON 파일을 찾을 수 없습니다.")
    //         return
    //     }
    //
    //     do {
    //         let data = try Data(contentsOf: url)
    //         let decoded = try JSONDecoder().decode(DataModel.self, from: data)
    //         self.restaurants = decoded.restaurants
    //         self.places = decoded.places
    //     } catch {
    //         print("로컬 JSON 디코딩 에러:", error.localizedDescription)
    //     }
    // }
}

// MARK: - CardView
struct CardView: View {
    let image: String
    let category: String
    let heading: String
    let author: String

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

// MARK: - 미리보기
#Preview {
//    ContentView()
}

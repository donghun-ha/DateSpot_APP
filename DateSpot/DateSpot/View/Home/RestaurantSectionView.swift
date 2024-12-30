//
//  RestaurantSectionView.swift
//  DateSpot
//
//  Created by 이종남 on 12/29/24.
//

import SwiftUI

struct RestaurantSectionView: View {
    let restaurants: [Restaurant]                      // 상위에서 주입받은 레스토랑 리스트
    @State private var loadedImages: [String: UIImage] = [:] // 레스토랑 이름별로 이미지를 저장
    private let baseURL = "https://fastapi.fre.today/restaurant/images?name="

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("맛집")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(restaurants, id: \.name) { restaurant in
                        // loadedImages 딕셔너리에 해당 레스토랑 이름으로 저장된 UIImage가 있을 수도, 없을 수도 있음
                        CardView(
                            image: loadedImages[restaurant.name],      // 이미지가 없으면 nil, 있으면 UIImage
                            category: restaurant.parking ?? "N/A",
                            heading: restaurant.name,
                            author: restaurant.address
                        )
                        .frame(width: 300)
                        // 각 CardView가 화면에 나타날 때(onAppear) 이미지를 비동기로 로드
                        .onAppear {
                            Task {
                                await loadImage(for: restaurant.name)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    /// 비동기로 이미지를 로드하는 함수
    private func loadImage(for restaurantName: String) async {
        // 이미 로드된 이미지가 있으면 중복 요청 방지
        guard loadedImages[restaurantName] == nil else { return }

        // 레스토랑 이름에 공백이나 특수문자가 있을 수 있으니 퍼센트 인코딩
        let encodedName = restaurantName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? restaurantName
        guard let url = URL(string: "\(baseURL)\(encodedName)") else {
            print("Invalid URL for \(restaurantName)")
            return
        }

        do {
            // URLSession + async/await
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 상태 코드 확인(200이 아닐 경우 에러 가능성)
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code for \(restaurantName): \(httpResponse.statusCode)")
            }

            // 데이터로부터 UIImage 생성
            if let image = UIImage(data: data) {
                // 메인 스레드에서 @State를 업데이트해야 하므로 Task { @MainActor } 또는 MainActor.run 사용
                await MainActor.run {
                    loadedImages[restaurantName] = image
                }
            } else {
                print("Failed to decode image for \(restaurantName)")
            }
        } catch {
            print("Error loading image for \(restaurantName): \(error.localizedDescription)")
        }
    }
}


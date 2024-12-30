//
//  RestaurantSectionView.swift
//  DateSpot
//
//  Created by 이종남 on 12/29/24.
//
import SwiftUI

struct RestaurantSectionView: View {
    let restaurants: [Restaurant]
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
                        let image = loadedImages[restaurant.name] // 이미 로드된 이미지를 가져옴
                        CardView(
                            image: image,
                            category: restaurant.parking,
                            heading: restaurant.name,
                            author: restaurant.address
                        )
                        .frame(width: 300)
                        .onAppear {
                            loadImage(for: restaurant.name) // 이미지를 로드
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func loadImage(for restaurantName: String) {
        guard loadedImages[restaurantName] == nil else { return } // 이미 로드된 경우 스킵

        let encodedName = restaurantName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? restaurantName
        guard let url = URL(string: "\(baseURL)\(encodedName)") else {
            print("Invalid URL for \(restaurantName)")
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        loadedImages[restaurantName] = image // 이미지 저장
                    }
                } else {
                    print("Failed to decode image for \(restaurantName)")
                }
            } catch {
                print("Error loading image for \(restaurantName): \(error.localizedDescription)")
            }
        }
    }
}

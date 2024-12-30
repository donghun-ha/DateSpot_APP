//    //
//    //  PlaceSectionView.swift
//    //  DateSpot
//    //
//    //  Created by 이종남 on 12/29/24.
//    //
import SwiftUI

struct PlaceSectionView: View {
    let places: [PlaceData]
    @State private var loadedImages: [String: UIImage] = [:] // 명소 이름별로 이미지를 저장
    private let imageBaseUrl = "https://fastapi.fre.today/place/images?name=" // 이미지 URL 기본 경로

    var body: some View {
        if !places.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("명소")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(places, id: \.name) { place in
                            let image = loadedImages[place.name] // 이미 로드된 이미지를 가져옴
                            CardView(
                                image: image, // UIImage 전달
                                category: place.parking ?? "N/A",
                                heading: place.name,
                                author: place.address
                            )
                            .frame(width: 300)
                            .onAppear {
                                loadImage(for: place.name) // 이미지를 로드
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        } else {
            Text("명소 데이터를 불러올 수 없습니다.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
    }

    private func loadImage(for placeName: String) {
        guard loadedImages[placeName] == nil else { return } // 이미 로드된 경우 스킵

        let encodedName = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeName
        guard let url = URL(string: "\(imageBaseUrl)\(encodedName)") else {
            print("Invalid URL for \(placeName)")
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        loadedImages[placeName] = image // 이미지 저장
                    }
                } else {
                    print("Failed to decode image for \(placeName)")
                }
            } catch {
                print("Error loading image for \(placeName): \(error.localizedDescription)")
            }
        }
    }
}

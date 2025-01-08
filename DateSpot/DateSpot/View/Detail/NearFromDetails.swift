import SwiftUI

import SwiftUI

struct NearFromDetails: View {
    @StateObject private var placeViewModel = PlaceViewModel()
    @State private var isLoading = true

    var currentLat: Double = 37.5665
    var currentLng: Double = 126.9780

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text("근처의 명소")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    Text("해당 장소와 가까운 명소들을 확인하세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }

                // 컨텐츠
                if isLoading {
                    ProgressView("Loading places...")
                        .font(.headline)
                        .padding()
                } else if !placeViewModel.nearbyPlaces.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(placeViewModel.nearbyPlaces, id: \.name) { place in
                            NearPlaceRow(
                                place: place,
                                placeViewModel: placeViewModel,
                                currentLat: currentLat,
                                currentLng: currentLng
                            )
                        }
                    }
                } else {
                    Text("근처 명소가 없습니다.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding()
                }
            }
            .padding(.top)
        }
        .onAppear {
            Task {
                isLoading = true
                await placeViewModel.fetchNearbyPlaces(lat: currentLat, lng: currentLng)
                isLoading = false
            }
        }
    }
}

struct NearPlaceRow: View {
    let place: PlaceData
    @ObservedObject var placeViewModel: PlaceViewModel
    let currentLat: Double
    let currentLng: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목 및 북마크 버튼
            HStack {
                Text(place.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    print("Bookmarked \(place.name)")
                }) {
                    Image(systemName: "bookmark")
                        .foregroundColor(.blue)
                }
            }

            // 주소 및 거리
            HStack {
                Text(place.address)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
                Text("\(String(format: "%.2fkm", calculateDistance()))")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            // 이미지
            if let image = placeViewModel.homeimage[place.name] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .cornerRadius(12)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                        .cornerRadius(12)
                    Text("이미지 로드 중...")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .onAppear {
                            Task {
                                await placeViewModel.loadImages(for: place.name)
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    // 거리 계산
    private func calculateDistance() -> Double {
        return placeViewModel.calculateDistance(
            lat: place.lat,
            lng: place.lng,
            currentLat: currentLat,
            currentLng: currentLng
        )
    }
}

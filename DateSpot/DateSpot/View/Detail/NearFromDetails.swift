import SwiftUI

struct NearFromDetails: View {
    @StateObject private var placeViewModel = PlaceViewModel() // ViewModel 선언
    @State private var isLoading = true

    var currentLat: Double = 37.5665 // 현재 위치 (예: 서울시청)
    var currentLng: Double = 126.9780

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerView()

                if isLoading {
                    ProgressView("Loading places...")
                        .font(.headline)
                        .padding()
                } else if !placeViewModel.nearbyPlaces.isEmpty {
                    placeListView()
                } else {
                    noPlacesView()
                }
            }
            .padding(.top)
        }
        .onAppear {
            Task {
                isLoading = true
                await placeViewModel.fetchPlaces(currentLat: currentLat, currentLng: currentLng)
                isLoading = false
            }
        }
    }

    // 헤더 뷰
    @ViewBuilder
    private func headerView() -> some View {
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
    }

    // 명소 리스트 뷰
    @ViewBuilder
    private func placeListView() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(placeViewModel.nearbyPlaces, id: \.name) { place in
                PlaceRowView(
                    place: place,
                    image: placeViewModel.images1[place.name],
                    fetchImage: {
                        await placeViewModel.fetchImage(fileKey: place.name)
                    },
                    calculateDistance: {
                        calculateDistance(lat: place.lat, lng: place.lng)
                    }
                )
                .padding(.horizontal)
            }
        }
    }

    // 명소가 없을 때 표시할 뷰
    @ViewBuilder
    private func noPlacesView() -> some View {
        Text("근처 명소가 없습니다.")
            .foregroundColor(.gray)
            .font(.subheadline)
            .padding()
    }

    // 거리 계산 함수 (재사용)
    private func calculateDistance(lat: Double, lng: Double) -> Double {
        return placeViewModel.calculateDistance(lat: lat, lng: lng, currentLat: currentLat, currentLng: currentLng)
    }
}

// 명소의 개별 행 뷰
struct PlaceRowView: View {
    let place: PlaceData
    let image: UIImage?
    let fetchImage: () async -> Void
    let calculateDistance: () -> Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            HStack {
                Text(place.address)
                    .foregroundColor(.gray)
                    .font(.subheadline)

                Spacer()
                Text("\(String(format: "%.2fkm", calculateDistance()))")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            // 이미지 표시
            if let image = image {
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
                                await fetchImage()
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

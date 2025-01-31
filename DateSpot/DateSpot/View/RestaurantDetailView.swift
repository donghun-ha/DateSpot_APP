import SwiftUI
import RealmSwift

struct RestaurantDetailView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @StateObject private var placeViewModel = PlaceViewModel()
    @State private var selection: Int = 0
    @State private var isLoading = true
    @State private var nearbyPlaces: [PlaceData] = []
    var name: String = "[백년가게]만석장"
    var type: String = ""

    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading...")
                    .font(.headline)
            } else if let restaurant = restaurantViewModel.selectedRestaurant {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 이미지 슬라이더
                        if !restaurantViewModel.images.isEmpty {
                            ImageSliderView(
                                currentItem: name,
                                currentType: "restaurant",
                                images: restaurantViewModel.images,
                                selection: $selection
                            )
                        } else {
                            Text("No images available")
                                .foregroundColor(.gray)
                                .frame(height: 260)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .padding()
                        }
                        
                        // 레스토랑 상세 정보
                        RestaurantDetailInfoView(restaurant: restaurant, images: $restaurantViewModel.images[0])

                        // 근처 명소
                        if !nearbyPlaces.isEmpty {
                            NearFromDetails()
                        } else {
                            Text("No nearby places found.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                }
            } else {
                Text("Restaurant not found.")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            Task {
                await restaurantViewModel.fetchRestaurantDetail(name: name)
            }
            debugPrint(Realm.Configuration.defaultConfiguration.fileURL ?? "")
            Task {
                isLoading = true
                // 레스토랑 세부 정보 및 이미지 가져오기
                await restaurantViewModel.fetchRestaurantDetail(name: name)
                await restaurantViewModel.loadImages(for: name)

                // 명소 데이터 불러오기
                await placeViewModel.fetchPlaces(currentLat: restaurantViewModel.selectedRestaurant?.lat ?? 37.5665, currentLng: restaurantViewModel.selectedRestaurant?.lng ?? 126.9780)
                if let restaurant = restaurantViewModel.selectedRestaurant {
                    // 가까운 5개의 명소 계산
                    nearbyPlaces = calculateNearbyPlaces(
                        places: placeViewModel.places,
                        restaurantLat: restaurant.lat,
                        restaurantLng: restaurant.lng
                    )
                }
                isLoading = false
            }
        }
    }

    // 근처 명소 계산 함수
    private func calculateNearbyPlaces(places: [PlaceData], restaurantLat: Double, restaurantLng: Double) -> [PlaceData] {
        return places
            .map { place in
                (place, calculateDistance(lat1: restaurantLat, lng1: restaurantLng, lat2: place.lat, lng2: place.lng))
            }
            .sorted(by: { $0.1 < $1.1 }) // 거리 기준 정렬
            .prefix(5) // 가장 가까운 5개 선택
            .map { $0.0 }
    }

    // 거리 계산 함수
    private func calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let deltaLat = lat2 - lat1
        let deltaLng = lng2 - lng1
        return sqrt(deltaLat * deltaLat + deltaLng * deltaLng) * 111 // 대략적인 거리(km)
    }
}




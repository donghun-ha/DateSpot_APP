import SwiftUI

struct DetailView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var selection: Int = 0
    @State private var isLoading = true
    var restaurantName: String = "[백년가게]만석장"

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
                        let samplePlaces = [
                                    PlaceData(
                                        name: "(재)환기재단·환기미술관",
                                        address: "서울 종로구",
                                        lat: 37.5822,
                                        lng: 126.9835,
                                        description: "현대 미술 전시장",
                                        contact_info: "02-123-4567",
                                        operating_hour: "9:00 AM - 6:00 PM",
                                        parking: "가능",
                                        closing_time: "6:00 PM"
                                    ),
                                    PlaceData(
                                        name: "윤동주 문학관",
                                        address: "서울 종로구",
                                        lat: 37.5803,
                                        lng: 126.9817,
                                        description: "윤동주 시인을 기리는 문학관",
                                        contact_info: "02-765-1234",
                                        operating_hour: "10:00 AM - 5:00 PM",
                                        parking: "불가능",
                                        closing_time: "5:00 PM"
                                    )
                                ]
                        // 레스토랑 상세 정보
                        RestaurantDetailInfoView(restaurant: restaurant)
                        NearFromDetails(nearbyPlaces: samplePlaces)
                    }
                }
                .navigationBarTitle("Date Spots", displayMode: .inline)
            } else {
                Text("Restaurant not found.")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            Task {
                print("DetailView appeared. Loading data for: \(restaurantName)")
                isLoading = true
                await restaurantViewModel.fetchRestaurantDetail(name: restaurantName)
                print("Restaurant detail fetched: \(String(describing: restaurantViewModel.selectedRestaurant))")
                await restaurantViewModel.loadImages(for: restaurantName)
                isLoading = false
                print("Images loaded: \(restaurantViewModel.images.count)")
            }
        }
    }
}

#Preview {
    DetailView()
}

import SwiftUI

struct RestaurantSectionView: View {
    @StateObject var viewModel = RestaurantViewModel() // ViewModel 초기화
    @State private var userLocation: (lat: Double, lng: Double) = (37.5255100592, 127.0367640978) // 기본 위치 (서울)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("맛집")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(viewModel.nearbyRestaurants.prefix(5)) { restaurant in
                        NavigationLink(
                            destination: RestaurantDetailView(restaurantName: restaurant.name)
                        ) {
                            ZStack {
                                if let image = viewModel.homeimage[restaurant.name] {
                                    CardView(
                                        image: image,
                                        category: restaurant.parking,
                                        heading: restaurant.name,
                                        author: restaurant.address
                                    )
                                    .frame(width: 300, height: 300)
                                } else {
                                    CardView(
                                        image: UIImage(systemName: "photo"), // 기본 이미지
                                        category: restaurant.parking,
                                        heading: restaurant.name,
                                        author: restaurant.address
                                    )
                                    .frame(width: 300, height: 300)
                                    .onAppear {
                                        Task {
                                            if viewModel.homeimage[restaurant.name] == nil {
                                                var images = await viewModel.fetchImageKeys(for: restaurant.name)
                                                await viewModel.fetchFirstImage(for: restaurant.name)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            // 스크롤될 때마다 동적으로 데이터 로드
                            Task {
                                await viewModel.fetchNearbyRestaurants(
                                    lat: userLocation.lat,
                                    lng: userLocation.lng,
                                    radius: 1000
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            Task {
                // FastAPI에서 근처 레스토랑 데이터를 가져오기
                await viewModel.fetchNearbyRestaurants(
                    lat: userLocation.lat,
                    lng: userLocation.lng,
                    radius: 1000
                )
            }
        }
    }
}

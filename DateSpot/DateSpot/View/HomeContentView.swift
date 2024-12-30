import SwiftUI

struct HomeContentView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @StateObject private var placeViewModel = PlaceViewModel()
    @State private var isLoading = true

    var body: some View {
        NavigationView { // NavigationView로 감싸기
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .font(.headline)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 맛집 섹션
                            RestaurantSectionView(
                                restaurants: restaurantViewModel.restaurants,
                                viewModel: restaurantViewModel
                            )

                            // 명소 섹션
                            PlaceSectionView(
                                places: placeViewModel.places,
                                viewModel: placeViewModel
                            )
                        }
                        .padding(.vertical)
                    }
                }
            }
            .onAppear {
                Task {
                    isLoading = true
                    async let restaurants = restaurantViewModel.fetchRestaurants()
                    async let places = placeViewModel.fetchPlace()
                    isLoading = false
                    
                    // 병렬로 데이터 로드
                    await (restaurants, places)
                }
            }
        }
    }
}


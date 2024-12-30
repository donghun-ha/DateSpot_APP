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
                    await restaurantViewModel.fetchRestaurants()
                    await placeViewModel.fetchPlace()
                    isLoading = false
                }
            }
        }
    }
}


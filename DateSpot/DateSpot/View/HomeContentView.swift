import SwiftUI

    struct HomeContentView: View {
        @StateObject private var restaurantViewModel = RestaurantViewModel()
        @StateObject private var placeViewModel = PlaceViewModel()
        @State private var isLoading = true

        var body: some View {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .font(.headline)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 맛집 섹션
                            RestaurantSectionView(
                                restaurants: restaurantViewModel.restaurants, // 레스토랑 데이터 전달
                                viewModel: restaurantViewModel // ViewModel 전달
                            )

                            // 명소 섹션
                            PlaceSectionView(places: placeViewModel.places)
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

#Preview {
    HomeContentView()
}

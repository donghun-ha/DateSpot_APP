import SwiftUI

struct HomeContentView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()  // 레스토랑 데이터
    @StateObject private var placeViewModel = PlaceViewModel()            // 명소 데이터
    @StateObject private var mapViewModel = TabMapViewModel()             // 위치 기반 ViewModel
    
    @State private var isLoading = true  // 로딩 상태

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                        .font(.headline)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 2km 반경 레스토랑 섹션
                            RestaurantSectionView(
                                restaurants: mapViewModel.filteredRestaurants,  // 필터링된 레스토랑 데이터
                                viewModel: restaurantViewModel
                            )
                            
                            // 2km 반경 명소 섹션
                            PlaceSectionView(
                                places: mapViewModel.filteredPlaces,             // 필터링된 명소 데이터
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

                    // 레스토랑 및 명소 데이터 로드
                    async let restaurants: () = restaurantViewModel.fetchRestaurants()
                    async let places: () = placeViewModel.fetchPlace()
                    await (restaurants, places)

                    // 사용자 위치 기반 데이터 필터링
                    mapViewModel.filterData(
                        restaurants: restaurantViewModel.restaurants,
                        places: placeViewModel.places
                    )
                    print("Filtered Restaurants:", mapViewModel.filteredRestaurants)

                    isLoading = false
                }
            }
        }
    }
}



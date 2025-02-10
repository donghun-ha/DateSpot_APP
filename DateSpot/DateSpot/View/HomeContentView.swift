import SwiftUI

struct HomeContentView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()  // 레스토랑 데이터
    @StateObject private var placeViewModel = PlaceViewModel()            // 명소 데이터
    @StateObject private var mapViewModel = TabMapViewModel()             // 위치 기반 ViewModel
    
    @State private var isLoading = true  // 로딩 상태

    var body: some View {
        NavigationView {
            if !mapViewModel.authorization {
                Text("mapviewmodel.authorization = false")
            }
//                else if isLoading {
//                    ProgressView("Loading...")
//                        .font(.headline) 
//                }
            else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // 2km 반경 레스토랑 섹션
                            RestaurantSectionView(
//                                viewModel: restaurantViewModel
                            )
                            
                            // 2km 반경 명소 섹션
                            PlaceSectionView(
//                                viewModel: placeViewModel
                            )
                        }
                        .frame(height: 800)
                        .padding(.vertical)
                    }
                }
            }
        .onAppear {
//            if mapViewModel.authorization {
//                Task {
//                isLoading = true
//                // 사용자 위치 기반 데이터 필터링
//                mapViewModel.filterData(
//                    restaurants: restaurantViewModel.restaurants,
//                    places: placeViewModel.places
//                )
//                isLoading = false
//            }
//        }
            }
        }
    
}



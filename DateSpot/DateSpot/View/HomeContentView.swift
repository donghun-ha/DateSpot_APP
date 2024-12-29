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
                        if !restaurantViewModel.restaurants.isEmpty {
                            SectionHeaderView(title: "맛집")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(restaurantViewModel.restaurants, id: \.id) { restaurant in
                                        CardView(
                                            category: restaurant.parking ?? "N/A",
                                            heading: restaurant.name,
                                            author: restaurant.address
                                        )
                                        .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Text("맛집 데이터를 불러올 수 없습니다.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }

                        // 명소 섹션
                        if !placeViewModel.places.isEmpty {
                            SectionHeaderView(title: "명소")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(placeViewModel.places, id: \.name) { place in
                                        CardView(
                                            category: place.parking ?? "N/A",
                                            heading: place.name,
                                            author: place.address
                                        )
                                        .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Text("명소 데이터를 불러올 수 없습니다.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            Task {
                isLoading = true
                // 맛집 데이터 로드
                await restaurantViewModel.fetchRestaurants()
                // 명소 데이터 로드
                await placeViewModel.fetchPlaces()
                isLoading = false
            }
        }
    }
}

// Reusable Section Header
struct SectionHeaderView: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.title)
            .fontWeight(.bold)
            .padding(.horizontal)
    }
}

#Preview {
    HomeContentView()
}


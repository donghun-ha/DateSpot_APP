import SwiftUI

struct HomeContentView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @StateObject private var placeViewModel = PlaceViewModel()
    @State private var isLoading = true
    
    var body: some View {
        if isLoading {
            ProgressView("Loading...")
                .font(.headline)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 맛집 섹션
                    if !restaurantViewModel.restaurants.isEmpty {
                        Text("맛집")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(restaurantViewModel.restaurants, id: \.self) { restaurant in
                                    CardView(
                                        category: restaurant.parking,
                                        heading: restaurant.name,
                                        author: restaurant.address
                                    )
                                    .frame(width: 300)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    
                    // 명소 섹션
//                    if !placeViewModel.places.isEmpty {
//                        Text("명소")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .padding(.horizontal)
//                        
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 20) {
//                                ForEach(placeViewModel.places, id: \.name) { place in
//                                    CardView(
//                                        category: place.parking,
//                                        heading: place.name,
//                                        author: place.address
//                                    )
//                                    .frame(width: 300)
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
                }
                .padding(.vertical)
            }
        }
        
//            .onAppear {
//                Task {
//                    isLoading = true
//                    await restaurantViewModel.fetchRestaurants()
//                    // await placeViewModel.fetchPlaces() // Uncomment to fetch places
//                    isLoading = false
//                }
//            }
    }
}

#Preview {
    HomeContentView()
}

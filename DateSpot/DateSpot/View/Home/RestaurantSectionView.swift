import SwiftUI

struct RestaurantSectionView: View {
    let restaurants: [Restaurant]
    @ObservedObject var viewModel: RestaurantViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("맛집")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                let limitedRestaurants = Array(restaurants.prefix(20))

                HStack(spacing: 20) {
                    ForEach(limitedRestaurants, id: \.name) { restaurant in
                        ZStack {
                            // 이미 로드된 첫 번째 이미지를 표시
                            if let image = viewModel.homeimage[restaurant.name] {
                                CardView(
                                    image: image,
                                    category: restaurant.parking,
                                    heading: restaurant.name,
                                    author: restaurant.address
                                )
                                .frame(width: 300)
                            } else {
                                // 기본 이미지를 표시하며 첫 번째 이미지를 비동기로 로드
                                CardView(
                                    image: UIImage(systemName: "photo"), // 기본 이미지
                                    category: restaurant.parking,
                                    heading: restaurant.name,
                                    author: restaurant.address
                                )
                                .frame(width: 300)
                                .onAppear {
                                    Task {
                                        await viewModel.fetchFirstImage(for: restaurant.name)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

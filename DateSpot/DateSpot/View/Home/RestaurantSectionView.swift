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
                LazyHStack(spacing: 20) {
                    ForEach(restaurants.prefix(20), id: \.name) { restaurant in
                        NavigationLink(
                            destination: DetailView(restaurantName: restaurant.name) // 클릭 시 DetailView로 이동
                        ) {
                            ZStack {
                                if let image = viewModel.homeimage[restaurant.name] {
                                    // 이미 로드된 첫 번째 이미지를 표시
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
                        .buttonStyle(PlainButtonStyle()) // 기본 스타일 제거
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}


import SwiftUI

struct RestaurantSectionView: View {
    let restaurants: [Restaurant]                      // 상위에서 주입받은 레스토랑 리스트
    @ObservedObject var viewModel: RestaurantViewModel // ViewModel을 받아옴

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("맛집")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(restaurants, id: \.name) { restaurant in
                        ZStack {
                            if let image = viewModel.images.first { // 이미지가 있는 경우
                                CardView(
                                    image: image,
                                    category: restaurant.parking ?? "N/A",
                                    heading: restaurant.name,
                                    author: restaurant.address
                                )
                                .frame(width: 300)
                            } else {
                                // 로드 중인 경우 기본 이미지 표시
                                CardView(
                                    image: UIImage(systemName: "photo"), // 기본 이미지
                                    category: restaurant.parking ?? "N/A",
                                    heading: restaurant.name,
                                    author: restaurant.address
                                )
                                .frame(width: 300)
                                .onAppear {
                                    Task {
                                        await viewModel.loadImages(for: restaurant.name)
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


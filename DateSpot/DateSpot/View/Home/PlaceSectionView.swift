import SwiftUI

struct PlaceSectionView: View {
    let places: [PlaceData]
    @ObservedObject var viewModel: PlaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("명소")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // places 배열에서 최대 20개의 명소만 선택
                    ForEach(Array(places.prefix(20)), id: \.name) { place in
                        ZStack {
                            // 이미 로드된 첫 번째 이미지를 표시
                            if let image = viewModel.images[place.name] {
                                CardView(
                                    image: image,
                                    category: place.parking ?? "N/A",
                                    heading: place.name,
                                    author: place.address
                                )
                                .frame(width: 300)
                            } else {
                                // 기본 이미지를 표시하며 첫 번째 이미지를 비동기로 로드
                                CardView(
                                    image: UIImage(systemName: "photo"), // 기본 이미지
                                    category: place.parking ?? "N/A",
                                    heading: place.name,
                                    author: place.address
                                )
                                .frame(width: 300)
                                .onAppear {
                                    Task {
                                        await viewModel.fetchFirstImage(for: place.name) // 첫 번째 이미지 로드
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


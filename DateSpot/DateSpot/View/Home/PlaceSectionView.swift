import SwiftUI

struct PlaceSectionView: View {
    @StateObject var viewModel = PlaceViewModel() // ViewModel 초기화
    @State private var userLocation: (lat: Double, lng: Double) = (37.5665, 126.9780) // 기본 위치 (서울)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("명소")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(viewModel.nearbyPlaces.prefix(5), id: \.name) { place in
                        NavigationLink(
                            destination: DetailView(restaurantName: place.name)
                        ) {
                            ZStack {
                                if let image = viewModel.images[place.name] {
                                    CardView(
                                        image: image,
                                        category: place.parking,
                                        heading: place.name,
                                        author: place.address
                                    )
                                    .frame(width: 300, height: 300)
                                } else {
                                    CardView(
                                        image: UIImage(systemName: "photo"),
                                        category: place.parking,
                                        heading: place.name,
                                        author: place.address
                                    )
                                    .frame(width: 300, height: 300)
                                    .onAppear {
                                        Task {
                                            await viewModel.fetchNearbyPlaces(
                                                lat: userLocation.lat,
                                                lng: userLocation.lng,
                                                radius: 1000
                                            )
                                            print("\(place.name)의 이미지 가져오기")
                                            await viewModel.fetchFirstImage(for: place.name)
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchNearbyPlaces(
                    lat: userLocation.lat,
                    lng: userLocation.lng,
                    radius: 1000
                )
            }
        }
    }
}

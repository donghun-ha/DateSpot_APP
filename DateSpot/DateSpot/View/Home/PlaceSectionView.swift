import SwiftUI

struct PlaceSectionView: View {
    @StateObject var viewModel = PlaceViewModel() // ViewModel 초기화
    @State private var userLocation: (lat: Double, lng: Double) = (37.5665, 126.9780) // 기본 위치 (서울)
    @StateObject var mapViewModel = TabMapViewModel()
    @State var isloading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !mapViewModel.authorization{
                Text("위치 제공 동의가 필요합니다.")
            }else if isloading == false{
                ProgressView("Loading...")
            }else{
                Text("명소")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 20) {
                        ForEach(viewModel.nearbyPlaces.prefix(5), id: \.name) { place in
                            PlaceCardView(place: place, viewModel: viewModel)
                        }
                        
                    }
                    .padding(.horizontal)
                }
        }
            }
        
        .onAppear {
//            if mapViewModel.authorization{
//                Task {
//                    isloading = false
//                    
//                    await viewModel.fetchNearbyPlaces(
//                        lat: (mapViewModel.userLocation?.coordinate.latitude)!,
//                        lng: (mapViewModel.userLocation?.coordinate.longitude)!,
//                        radius: 1000
//                    )
//                    isloading = true
//                }
//            }
//            else{
                Task {
                    isloading = false
                    
                    await viewModel.fetchNearbyPlaces(
                        lat: (userLocation.lat),
                        lng: (userLocation.lng),
                        radius: 1000
                    )
                    isloading = true
                }
                
//            }
        }
    }
    
    /// 명소 카드 뷰를 별도 함수로 분리
    @ViewBuilder
    private func placeCardView(for place: PlaceData) -> some View {
        ZStack {
            if let image = viewModel.homeimage[place.name] {
                CardView(
                    image: image,
                    category: place.parking,
                    heading: place.name,
                    author: place.address
                )
                .frame(width: 300, height: 300)
            } else {
                CardView(
                    image: UIImage(systemName: "photo") ?? UIImage(), // 옵셔널 해제
                    category: place.parking,
                    heading: place.name,
                    author: place.address
                )
                .frame(width: 300, height: 300)
                .onAppear {
                    Task {
                        await viewModel.fetchFirstImage(for: place.name)
                    }
                }
            }
        }
    }
}

struct PlaceCardView: View {
    let place: PlaceData // Place 모델
    @ObservedObject var viewModel: PlaceViewModel
//    let userLocation: (lat: Double, lng: Double)
    
    var body: some View {
        NavigationLink(
            destination: PlaceDetailView(placeName: place.name)
        ) {
            ZStack {
                if let image = viewModel.homeimage[place.name] {
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
                            await viewModel.fetchFirstImage(for: place.name)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

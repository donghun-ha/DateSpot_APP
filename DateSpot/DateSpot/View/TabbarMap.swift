import SwiftUI
import MapKit

struct TabbarMapView: View {
    @StateObject var mapViewModel = TabMapViewModel()
    @StateObject var restaurantVM = RestaurantViewModel()
    @StateObject var placeVM = PlaceViewModel()
    @State var loadingStatus = false // 데이터 로드 관리
    @State private var selectedResult: MKMapItem? // 검색 관리
    @State private var showSearchSheet = false // 검색 sheet 관리
    var body: some View {
            NavigationView {
                if loadingStatus == false {
                    ProgressView("Loading...")
                        .font(.headline)
                } else {
                    Map(position: $mapViewModel.cameraPosition) {
                        
                        // 현재 위치 표시
                        UserAnnotation()
                        
                        // 명소 마커(파란색)
                        ForEach($mapViewModel.nearPlace.indices, id: \.self) { index in
                            let place = mapViewModel.nearPlace[index]
                            Marker(place.name, systemImage: "house.fill", coordinate:
                                    CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng))
                            .tint(.red)
                        }
                        
                        // 맛집 마커(빨간색)
                        ForEach($mapViewModel.nearRestaurant.indices, id: \.self) { index in
                            let restaurant = mapViewModel.nearRestaurant[index]
                            Marker(restaurant.name, systemImage: "fork.knife.circle.fill", coordinate:
                                    CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng))
                            .tint(.blue)
                        }
                    }
                    .onMapCameraChange {
                        change in
                        mapViewModel.region = change.region
                        Task{
                            await mapViewModel.filterNearALL(currentLocation: CLLocation(latitude : mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude), placeData: placeVM.places, restaurantData: restaurantVM.restaurants)
                        }
                        
                    }
                    // 검색결과 시트 표시
                    .sheet(isPresented: $showSearchSheet) {
                        SearchResultsView(mapViewModel: mapViewModel)
                            .presentationDetents([.height(300)])
                    }
                }
            }
            .navigationTitle("지도")
            .onAppear {
                        Task{
                            await restaurantVM.fetchRestaurants()
                            await placeVM.fetchPlaces(currentLat: 36, currentLng: 127)
                            await mapViewModel.filterNearALL(currentLocation: mapViewModel.userLocation!, placeData: placeVM.places, restaurantData: restaurantVM.restaurants)
                            loadingStatus = true
                        }
                    }
        // 검색바
            .searchable(
                text: $mapViewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "장소 검색"
            )
        // 검색 여부에 따른 sheet 처리
            .onChange(of: mapViewModel) { _,_ in
                if mapViewModel.searchText.isEmpty {
                    mapViewModel.searchResults = []
                    showSearchSheet = false
                }
            }
        // 검색기능
            .onSubmit(of: .search) {
                mapViewModel.searchLocations()
                showSearchSheet = !mapViewModel.searchResults.isEmpty
            }
        // 화면 꺼지면 gps 신호 받기 중단
            .onDisappear {
                mapViewModel.tabMapLoc.stopUpdatingLocation()
            }
        }
    }

// 검색 결과
struct SearchResultsView: View {
    @ObservedObject var mapViewModel: TabMapViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(mapViewModel.searchResults, id: \.self) { item in
                Button {
                    if let coordinate = item.placemark.location?.coordinate {
                        mapViewModel.cameraPosition = .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        )
                    }
                    mapViewModel.searchResults = []
                    mapViewModel.searchText = ""
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "")
                            .foregroundColor(.primary)
                        Text(item.placemark.title ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let phoneNumber = item.phoneNumber {
                            Text(phoneNumber)
                                .font(.caption)
                        }
                        if let timeZone = item.timeZone?.identifier {
                            Text(timeZone)
                                .font(.caption)
                        }
                    }

                }
            }
        }
    }
}

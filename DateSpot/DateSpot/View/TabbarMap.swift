import SwiftUI
import MapKit
struct TabbarMapView: View {
    @StateObject var mapViewModel = TabMapViewModel()
    @StateObject var restaurantVM = RestaurantViewModel()
    @StateObject var placeVM = PlaceViewModel()
    @State var loadingStatus = false
    @State private var selectedResult: MKMapItem?
    @State private var showSearchSheet = false

    var body: some View {
        NavigationView {
            Group {
                if !mapViewModel.authorization {
                        Text("GPS 권한이 필요합니다")
                            .font(.headline)
                } else if loadingStatus == false {
                    ProgressView("Loading...")
                        .font(.headline)
                } else {
                    Map(position: $mapViewModel.cameraPosition) {
                        UserAnnotation()
                        
                        ForEach($mapViewModel.nearPlace.indices, id: \.self) { index in
                            let place = mapViewModel.nearPlace[index]
                            Marker(place.name, systemImage: "house.fill", coordinate:
                                    CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng))
                            .tint(.red)
                        }
                        
                        ForEach($mapViewModel.nearRestaurant.indices, id: \.self) { index in
                            let restaurant = mapViewModel.nearRestaurant[index]
                            Marker(restaurant.name, systemImage: "fork.knife.circle.fill", coordinate:
                                    CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng))
                            .tint(.blue)
                        }
                    }
                    .onMapCameraChange { change in
                        mapViewModel.region = change.region
                        Task {
                            await mapViewModel.filterNearALL(currentLocation: CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude), placeData: placeVM.places, restaurantData: restaurantVM.restaurants)
                        }
                    }
                    .sheet(isPresented: $showSearchSheet) {
                        SearchResultsView(mapViewModel: mapViewModel)
                            .presentationDetents([.height(300)])
                    }
                }
            }
            .onAppear {
                Task {
                    if mapViewModel.authorization {
                        await restaurantVM.fetchRestaurants()
                        await placeVM.fetchPlaces(currentLat: (mapViewModel.userLocation?.coordinate.latitude)!, currentLng: (mapViewModel.userLocation?.coordinate.longitude)!)
                        await mapViewModel.filterNearALL(currentLocation: mapViewModel.userLocation!, placeData: placeVM.places, restaurantData: restaurantVM.restaurants)
                        loadingStatus = true
                    }
                }
            }
            .searchable(
                text: $mapViewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "장소 검색"
            )
//            .onChange(of: mapViewModel) { _,_ in
//                if mapViewModel.searchText.isEmpty {
//                    mapViewModel.searchResults = []
//                    showSearchSheet = false
//                }
//            }
            .onSubmit(of: .search) {
                if mapViewModel.searchText.isEmpty {
                    mapViewModel.searchResults = []
                    showSearchSheet = false
                }else{
                    mapViewModel.searchLocations()
                    showSearchSheet = !mapViewModel.searchResults.isEmpty
                }
            }
            .onDisappear {
                mapViewModel.tabMapLoc.stopUpdatingLocation()
            }
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
                        Text("\(item.placemark.administrativeArea ?? "") \(item.placemark.locality ?? "") \(item.placemark.subLocality ?? "")")
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



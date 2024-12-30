import SwiftUI
import MapKit

struct TabbarMapView: View {
    @StateObject var mapViewModel = TabMapViewModel()
    @StateObject var restaurantVM = RestaurantViewModel()
    @StateObject var placeVM = PlaceViewModel()
    @State var loadingStatus = false
    
    
    var body: some View {
        NavigationView {
            if loadingStatus == false{
                ProgressView("Loading...")
                    .font(.headline)
            }else{
                ZStack {
                // 지도 초기화
                Map(position: $mapViewModel.cameraPosition) {
                    // 내 위치 표시
                    UserAnnotation()
                    
                    // 명소 마커 (빨간색)
                    ForEach($mapViewModel.nearPlace.indices, id:\.self) { index in
                        let place = mapViewModel.nearPlace[index]
                        Marker(place.name, systemImage: "house.fill", coordinate:
                                CLLocationCoordinate2D(latitude:
                                                        place.lat, longitude:
                                                        place.lng))
                        .tint(.red)
                    }
                    
                    // 맛집 마커 (파란색)
                    ForEach($mapViewModel.nearRestaurant.indices, id:\.self) { index in
                        let restaurant = mapViewModel.nearRestaurant[index]
                        Marker(restaurant.name, systemImage:"fork.knife.circle.fill", coordinate:
                                CLLocationCoordinate2D(latitude:
                                                        restaurant.lat, longitude:
                                                        restaurant.lng))
                        .tint(.blue)
                    }
                }
                
            }
            }
                
        }
        .navigationTitle("지도")
        .onAppear {
            mapViewModel.tabMapLoc.delegate = mapViewModel
            mapViewModel.tabMapLoc.requestWhenInUseAuthorization()
            Task{
                await restaurantVM.fetchRestaurants()
                await placeVM.fetchPlace()
                mapViewModel.filterNearALL(currentLocation: mapViewModel.userLocation!, placeData: placeVM.places, restaurantData: restaurantVM.restaurants)
                loadingStatus = true
                
            }   
        }
    }
}




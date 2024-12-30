import SwiftUI
import MapKit

struct TabbarMapView: View {
    @StateObject var mapViewModel = TabMapViewModel()
//    @Binding var restaurantData : [Restaurant]
    
    // 테스트 데이터
    let testPlace: [PlaceData] = [
        PlaceData(
            name: "압구정 로데오거리",
            address: "서울특별시 강남구 압구정동",
            lat: 37.5268766055,
            lng: 127.0388971983,
            description: "압구정 로데오거리 설명",
            contact_info: "02-3423-5114",
            operating_hour: "00:00 ~ 24:00",
            parking: "가능",
            closing_time: "0"
        ),
        PlaceData(
            name: "향기억",
            address: "서울특별시 강남구 신사동",
            lat: 37.5261572277,
            lng: 127.0379584155,
            description: "향기억 설명",
            contact_info: "0507-1318-9070",
            operating_hour: "11:00~21:00",
            parking: "가능 (공영주차장)",
            closing_time: "0"
        )
    ]
    
    let restaurantData: [Restaurant] = [
        Restaurant(
            name: "바빌리안테이블",
            address: "서울특별시 강남구 압구정로46길",
            lat: 37.5280930945,
            lng: 127.0368834583,
            parking: "가능 요금(최초 2시간 2,000원)",
            operatingHour: "11:00~23:00",
            closedDays:"연중무휴",
            contactInfo:"02-540-3305"
        ),
        Restaurant(
            name:"무탄",
            address:"서울특별시 강남구 논현로176길",
            lat :37.5273597287,
            lng :127.0303257432,
            parking:"가능(발렛주차)",
            operatingHour:"11:00~22:00",
            closedDays:"연중무휴",
            contactInfo:"02-549-9339"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 지도 초기화
                Map(position: $mapViewModel.cameraPosition) {
                    // 내 위치 표시
                    UserAnnotation()
                    
                    // 명소 마커 (빨간색)
                    ForEach(testPlace.indices, id:\.self) { index in
                        let place = testPlace[index]
                        Marker(place.name, systemImage: "house.fill", coordinate:
                            CLLocationCoordinate2D(latitude:
                                place.lat, longitude:
                                place.lng))
                            .tint(.red)
                    }
                    
                    // 맛집 마커 (파란색)
                    ForEach(restaurantData.indices, id:\.self) { index in
                        let restaurant = restaurantData[index]
                        Marker(restaurant.name, systemImage:"fork.knife.circle.fill", coordinate:
                            CLLocationCoordinate2D(latitude:
                                restaurant.lat, longitude:
                                restaurant.lng))
                            .tint(.blue)
                    }
                }    
            }
        }
        .onAppear {
            mapViewModel.tabMapLoc.delegate = mapViewModel
            mapViewModel.tabMapLoc.requestWhenInUseAuthorization()
            
            if let userLocation = mapViewModel.userLocation {
                mapViewModel.filterNearALL(currentLocation:userLocation,
                                           placeData:testPlace,
                                           restaurantData:restaurantData)
            }
        }
    }
}


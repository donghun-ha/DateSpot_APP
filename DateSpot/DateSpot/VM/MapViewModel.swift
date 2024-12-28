//
//  MapViewModel.swift
//  DateSpot
//
//  Created by 신정섭 on 12/27/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class TabMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation? // 사용자 위치 데이터
    let tabMapLoc = CLLocationManager()
    var region : MKCoordinateRegion = MKCoordinateRegion()
    @Published var placeData = [PlaceData]() // 명소 전체 목록
    var nearPlace : [PlaceData] = [] // 명소 맵 마커 저장
    @Published var restaurantData = [Restaurant]() // 식당 전체 목록
    var nearRestaurant : [Restaurant] = [] // 식당 맵 마커 저장
    
    
    override init() {
        super.init()
        tabMapLoc.requestWhenInUseAuthorization()
        tabMapLoc.startUpdatingLocation() // GPS 좌표 받기

    }


    // gps 제공 동의
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            print("tabMapVM: Nodetermined")
            manager.desiredAccuracy = kCLLocationAccuracyBest
            self.tabMapLoc.requestWhenInUseAuthorization()
        case .denied:
            print("tabMapVM: denied")
        case .restricted:
            print("tabMaopVM: restricted")
        case .authorizedWhenInUse:
            print("tabMapVM: authorizedWhenInUse")
            manager.startUpdatingLocation()
        default:
            print("TabMapVM: default")
        }
    }
    
    
    // 마커 filter
    func filterNearALL(currentLocation: CLLocation) {
        self.nearPlace = placeData.filter { place in
            let placeLocation = CLLocation(latitude: place.lat, longitude: place.lng)
            return currentLocation.distance(from: placeLocation) <= 5000 // 5km 이내
        }
        self.nearRestaurant = restaurantData.filter { restaurant in
            let restaurantLocation = CLLocation(latitude: restaurant.lat, longitude: restaurant.lng)
            return currentLocation.distance(from: restaurantLocation) <= 5000
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        DispatchQueue.main.async {
            // 현재 위치가 업데이트되면 근처 주차장 필터링
            if let userLocation = self.userLocation {
                self.filterNearALL(currentLocation: userLocation)
            }
        }
        
    
    
}
} // VM



    

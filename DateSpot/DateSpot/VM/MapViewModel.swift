//
//  MapViewModel.swift
//  DateSpot
// Tabbar Map 
//  Created by 신정섭 on 12/27/24.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class TabMapViewModel: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 기본 좌표 (서울)
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    

    
    @Published var userLocation: CLLocation?  // 사용자 위치
    let tabMapLoc = CLLocationManager()  // 지도관리
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()  // 지도 영역
    
    // 필터링된 명소와 레스토랑 배열
    @Published var nearPlace: [PlaceData] = []
    @Published var nearRestaurant: [Restaurant] = []
    
    override init() {
        super.init()
        tabMapLoc.delegate = self
        tabMapLoc.desiredAccuracy = kCLLocationAccuracyBest
        tabMapLoc.requestWhenInUseAuthorization()
        tabMapLoc.startUpdatingLocation()
    }
    
    // 마커 필터링  (View에서 placeData, restaurantData 입력)
    func filterNearALL(currentLocation: CLLocation, placeData: [PlaceData], restaurantData: [Restaurant]) {
        // 명소 필터링
        self.nearPlace = placeData.filter { place in
            let placeLocation = CLLocation(latitude: place.lat, longitude: place.lng)
            return currentLocation.distance(from: placeLocation) <= 5000 // 5km 이내
        }
        
        // 식당 필터링
        self.nearRestaurant = restaurantData.filter { restaurant in
            let restaurantLocation = CLLocation(latitude: restaurant.lat, longitude: restaurant.lng)
            return currentLocation.distance(from: restaurantLocation) <= 5000
        }
    }

    // CLLocationManagerDelegate 함수 - 사용자 위치 업데이트 시 호출
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        DispatchQueue.main.async {
            self.userLocation = newLocation
            
            // 카메라 위치를 사용자 위치로 업데이트
            self.cameraPosition = .region(
                MKCoordinateRegion(
                    center: newLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
            
            // 지도 영역
            self.region.center = newLocation.coordinate
            
//            print("Camera position updated to user location:", newLocation.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location:", error.localizedDescription)
    }
} // VM
    
    
    
    


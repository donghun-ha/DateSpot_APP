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
    
    @StateObject var placeVM = PlaceViewModel()
    @StateObject var restaurantVM = RestaurantViewModel()
    
    
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 기본 좌표 (서울)
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @Published var userLocation: CLLocation?  // 사용자 위치
    @Published var region: MKCoordinateRegion = MKCoordinateRegion()  // 지도 영역
    
    // 필터링된 명소와 레스토랑
    @Published var nearPlace: [PlaceData] = []
    @Published var nearRestaurant: [Restaurant] = []
    
    
    // 검색 기능 변수
    @Published var searchText = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var selectedResult: MKMapItem?
    
    
    // 지도
    let tabMapLoc = CLLocationManager()  // 지도관리
    
    @Published var selectHname: String = ""
    @Published var apivalue: Bool = false
    @Published var capacity: Int = 0
    @Published var totalAvailableParking: Int = 0
    @Published var maxTemp: Double = 0
    @Published var parkingCapacity: [Double] = []
    @Published var parkingInfo: [ParkingInfo] = []
    @Published var predvalue: Bool = false
    @Published var timeList: [String] = ["1시간","2시간","3시간"] // ㅅ
    @Published var selectedTime: Int = 0 // 시간 입력
    @Published var predictedParking: Int?
    @Published var predictedCongestion: [String: String] = [:]
    
    override init() {
        super.init()
        tabMapLoc.delegate = self
        tabMapLoc.desiredAccuracy = kCLLocationAccuracyBest
        tabMapLoc.requestWhenInUseAuthorization()
        tabMapLoc.startUpdatingLocation()
    }
    
    // 마커 필터링  (View에서 placeData, restaurantData 입력)
    func filterNearALL(currentLocation: CLLocation, placeData : [PlaceData], restaurantData : [Restaurant]) async {
        // 명소 필터링
        
        self.nearPlace = placeData.filter { place in
            let placeLocation = CLLocation(latitude: place.lat, longitude: place.lng)
            return currentLocation.distance(from: placeLocation) <= 2000 // 5km 이내
        }
        
        // 식당 필터링
        self.nearRestaurant = restaurantData.filter { restaurant in
            let restaurantLocation = CLLocation(latitude: restaurant.lat, longitude: restaurant.lng)
            return currentLocation.distance(from: restaurantLocation) <= 2000
            
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
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
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
    
    // 검색기능
    //    func searchLocations() {
    //           let request = MKLocalSearch.Request()
    //           request.naturalLanguageQuery = searchText
    //           request.region = region
    //
    //           let search = MKLocalSearch(request: request)
    //           search.start { [weak self] response, error in
    //               guard let self = self else { return }
    //
    //               if let error = error {
    //                   print("Search error: \(error)")
    //                   return
    //               }
    //
    //               if let response = response {
    //                   DispatchQueue.main.async {
    //                       self.searchResults = response.mapItems
    //
    //                       // 검색 결과가 있으면 카메라 이동
    //                       if let firstResult = response.mapItems.first?.placemark.coordinate {
    //                           self.cameraPosition = .region(
    //                               MKCoordinateRegion(
    //                                   center: firstResult,
    //                                   span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
    //                               )
    //                           )
    //                       }
    //                   }
    //               }
    //           }
    //       }
    func searchLocations() {
        // 먼저 로컬 마커들에서 검색
        let localResults = searchLocalMarkers(searchText)
        if !localResults.isEmpty {
            self.searchResults = localResults
            if let firstResult = localResults.first,
               let coordinate = firstResult.placemark.location?.coordinate {
                self.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
            return
        }
        
        
        
        
    } // VM
//    func searchLocalMarkers(_ query: String) -> [MKMapItem] {
//        let lowercaseQuery = query.lowercased()
//        var results: [MKMapItem] = []
//        
//        // 레스토랑 검색
//        for restaurant in nearRestaurant {
//            if restaurant.name.lowercased().contains(lowercaseQuery) {
//                let placemark = MKPlacemark(
//                    coordinate: CLLocationCoordinate2D(
//                        latitude: restaurant.lat,
//                        longitude: restaurant.lng
//                    )
//                )
//                let mapItem = MKMapItem(placemark: placemark)
//                mapItem.name = restaurant.name
//                results.append(mapItem)
//            }
//        }
//        
//        // 명소 검색
//        for place in nearPlace {
//            if place.name.lowercased().contains(lowercaseQuery) {
//                let placemark = MKPlacemark(
//                    coordinate: CLLocationCoordinate2D(
//                        latitude: place.lat,
//                        longitude: place.lng
//                    )
//                )
//                let mapItem = MKMapItem(placemark: placemark)
//                mapItem.name = place.name
//                results.append(mapItem)
//            }
//        }
//        
//        return results
//    }
    
    func searchLocalMarkers(_ query: String) -> [MKMapItem] {
        let lowercaseQuery = query.lowercased()
        var results: [MKMapItem] = []
        
        // 레스토랑 검색
        for restaurant in nearRestaurant {
            if restaurant.name.lowercased().contains(lowercaseQuery) {
                let placemark = MKPlacemark(
                    coordinate: CLLocationCoordinate2D(
                        latitude: restaurant.lat,
                        longitude: restaurant.lng
                    )
                )
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = restaurant.name
                results.append(mapItem)
            }
        }
        
        // 명소 검색
        for place in nearPlace {
            if place.name.lowercased().contains(lowercaseQuery) {
                let placemark = MKPlacemark(
                    coordinate: CLLocationCoordinate2D(
                        latitude: place.lat,
                        longitude: place.lng
                    )
                )
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = place.name
                results.append(mapItem)
            }
        }
        
        return results
    }
    
}

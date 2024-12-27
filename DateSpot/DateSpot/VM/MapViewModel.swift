//
//  MapViewModel.swift
//  DateSpot
//
//  Created by 신정섭 on 12/27/24.
//

import SwiftUI
import MapKit
import CoreLocation

class TabMapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.498454033368, longitude: 127.03229336072), // 기본 좌표
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // 지도에 표시할 범위
        )
    )
    @Published var places: [Place] = [] // 마커로 표시할 장소 목록
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        DispatchQueue.main.async {
            self.cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
            self.filterNearbyPlaces(currentLocation: location)
        }
    }
    
    func filterNearbyPlaces(currentLocation: CLLocation) {
        
        // 마커 테스트 데이터
        let testData = [
            Place(name: "Test 1", coordinate: CLLocationCoordinate2D(latitude: 37.4985, longitude: 127.0323)),
            Place(name: "Test 2", coordinate: CLLocationCoordinate2D(latitude: 37.49849, longitude: 127.0333)),
            Place(name: "Test 3", coordinate: CLLocationCoordinate2D(latitude: 37.49847, longitude: 127.0328))
        ]
        
        
        // 장소 거리 필터링
        self.places = testData.filter { place in
            let placeLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            return currentLocation.distance(from: placeLocation) <= 5000 // 5km 이내
        }
    }
    
    func initdata(){
        
    }
    
    
// map에 사용될 장소 모델
    struct Place: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }
}

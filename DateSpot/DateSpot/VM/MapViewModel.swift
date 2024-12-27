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
    @Published var parkingData: [Parking] = [] // 해당구의 전체 주차장 목록
    @Published var nearParking: [Parking] = [] // 주차장 marker
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
            // 장소 거리 필터링
            self.nearParking = parkingData.filter { parking in
                let parkingLocation = CLLocation(latitude: parking.lat, longitude: parking.lng)
                return currentLocation.distance(from: parkingLocation) <= 5000 // 5km 이내
            }
        }
    
    
    // 주차장 목록 API 호출
    func fetchParkingInfo(region: String) {
        guard let url = URL(string: "http://127.0.0.1:8000/select_parkinginfo?region=\(region)") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data:", error)
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            do {
                // FastAPI 응답 데이터 디코딩
                let decodedResponse = try JSONDecoder().decode([String: [Parking]].self, from: data)
                DispatchQueue.main.async {
                    self.parkingData = decodedResponse["result"] ?? []
                }
            } catch {
                print("Error decoding JSON:", error)
            }
        }.resume()
    }
    
    
    
    
    
    
    
// map에 사용될 장소 모델
    struct Place: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }
}

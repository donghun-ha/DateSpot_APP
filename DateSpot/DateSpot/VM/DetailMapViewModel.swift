//
//  PakringViewModel.swift
//  DateSpot
//
//  Created by 신정섭 on 12/27/24.
//

import SwiftUI
import MapKit

class DetailMapViewModel : NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 기본 좌표 (서울)
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @Published var parkingData: [Parking] = [] // FastAPI에서 가져온 전체 주차장 데이터
    @Published var nearParking: [Parking] = [] // 현재 위치 기준 5km 이내의 주차장 데이터

    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
   

    
    
    // 지도 설정
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        // 현재 위치가 업데이트되면 근처 주차장 필터링
                    if let userLocation = self.userLocation {
                        self.filterNearbyParking(currentLocation: userLocation)
                    }
    }
    
    
    // 카메라 포지션 변경 함수
    func updateCameraPosition(latitude: Double, longitude: Double) {
           DispatchQueue.main.async {
               self.cameraPosition = .region(
                   MKCoordinateRegion(
                       center: CLLocationCoordinate2D(
                           latitude: latitude,
                           longitude: longitude
                       ),
                       span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                   )
               )
           }
       }

    // 주차장 정보 불러오기
    func fetchParkingInfo(lat : Double, lng : Double)  {
        guard let url = URL(string: "http://fastapi.fre.today/parking/select_parkinginfo?") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("주차장 로드 에러", error)
                return
            }

            guard let data = data else {
                print("일치하는 주차장 데이터 없음")
                return
            }

            do {
                // FastAPI
                let decodedResponse = try JSONDecoder().decode([String: [Parking]].self, from: data)
                DispatchQueue.main.async {
                    self.parkingData = decodedResponse["result"] ?? []
                    let  location = CLLocation(latitude: lat, longitude: lng)
                    // 주차장 필터링
                    if self.userLocation != nil {
                        self.filterNearbyParking(currentLocation: location)
                    }
                }
            } catch {
                print("주차장정보 불러오기 Error :", error)
            }
        }.resume()
    }

    
    // 마커 거리 필터링
    func filterNearbyParking(currentLocation: CLLocation) {
        self.nearParking = parkingData.filter { parking in
            let parkingLocation = CLLocation(latitude: parking.latitude, longitude: parking.longitude)
            
            return currentLocation.distance(from: parkingLocation) <= 1000 // 5km 이내
        }
    }
}

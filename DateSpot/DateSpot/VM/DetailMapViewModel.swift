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
            
            return currentLocation.distance(from: parkingLocation) <= 2000 // 5km 이내
        }
    }
    
    
    
        func fetchParkingData() async {
            guard let encodedPname = selectHname.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }
            apivalue = false
            var result: [Double] = []
    
            guard let url = URL(string: "http://127.0.0.1:8000/citydata/여의도한강공원") else { return }
    
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decodedData = try JSONDecoder().decode(ParkingResponse.self, from: data)
    
                var total = 100
                var totalCapacity = 0
                for parking in decodedData.parkingStatus {
                    let capacity = Int(parking.capacity) ?? 0
                    let currentParking = Int(parking.currentParkingCount) ?? 0
                    total += (capacity - currentParking)
                    totalCapacity += capacity
    
                    if capacity > 0 {
                        result.append((1 - (Double(currentParking) / Double(capacity))) * 100)
                    } else {
                        result.append(0)
                    }
                }
    
                DispatchQueue.main.async {
                    self.capacity = totalCapacity
                    self.totalAvailableParking = total
                    self.maxTemp = decodedData.maxTemperature
                    self.parkingCapacity = result
                    self.apivalue = true
                    self.objectWillChange.send()
                }
            } catch {
                print("Failed to fetch data: \(error)")
            }
        }
    
        func predictYeouido() async {
            let parkingCapacity = [462, 171, 800]
            let time =  getTimeOfDay()
            let holiday =  isHoliday()
    
            predvalue = false
    
            for (index, parking) in parkingInfo.enumerated() {
                let queryParameters: [String: String] = [
                    "요일": "\(Calendar.current.component(.weekday, from: Date()) - 1)",
                    "휴일여부": "\(holiday)",
                    "주차장명": parking.pname,
                    "연도": "\(Calendar.current.component(.year, from: Date()))",
                    "월": "\(Calendar.current.component(.month, from: Date()))",
                    "일": "\(Calendar.current.component(.day, from: Date()))",
                    "주차구획수": "\(parkingCapacity[index])"
                ]
    
                guard let url = URL(string: "http://127.0.0.1:8000/predict_yeouido") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
                do {
                            request.httpBody = try JSONSerialization.data(withJSONObject: queryParameters)
                            let (data, _) = try await URLSession.shared.data(for: request)
                            let decodedData = try JSONDecoder().decode(PredictionResponse.self, from: data)
                    print(decodedData)
                            DispatchQueue.main.async {
                                self.parkingInfo[index].predictParking = decodedData.predictedParking[time] ?? 0
                                self.parkingInfo[index].predictMessage = decodedData.congestion["예측 아침 혼잡도"] ?? ""
                                self.predictedCongestion = decodedData.congestion
                            }
                        } catch {
                            print("Failed to predict: \(error)")
                        }
    
                        DispatchQueue.main.async {
                            self.predvalue = true
                            self.objectWillChange.send()
                        }
                    }
    
            print(parkingInfo[0].predictMessage)
            print(parkingInfo[0].predictParking)
        }
    
        func predict() {
            Task {
                if selectHname == "여의도공원앞(구)" {
                    await predictYeouido()
                }
            }
        }
    
        func isHoliday() -> Int {
            let weekday = Calendar.current.component(.weekday, from: Date())
            return (weekday == 1 || weekday == 7) ? 1 : 0
        }
    
    
    
        func getTimeOfDay() -> String {
            let currentHour = Calendar.current.component(.hour, from: Date())
            let addHour = Int(timeList[selectedTime].split(separator: "시간")[0]) ?? 0
            let newHour = (currentHour + addHour) % 24
    
            switch newHour {
            case 6..<11: return "아침"
            case 11..<18: return "낮"
            default: return "저녁"
            }
        }
        
}
struct ParkingInfo: Identifiable {
    let id = UUID()
    let pname: String
    var predictParking: Int = 0
    var predictMessage: String = ""
}

struct ParkingResponse: Codable {
    let parkingStatus: [ParkingStatus]
    let maxTemperature: Double
    
    enum CodingKeys: String, CodingKey {
        case parkingStatus = "주차장 현황"
        case maxTemperature = "최고기온"
    }
}

struct ParkingStatus: Codable {
    let capacity: String
    let currentParkingCount: String
    
    enum CodingKeys: String, CodingKey {
        case capacity = "CPCTY"
        case currentParkingCount = "CUR_PRK_CNT"
    }
}

struct PredictionResponse: Codable {
    let predictedParking: [String: Int]
    let congestion: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case predictedParking = "예측 주차대수"
        case congestion = "혼잡도"
    }
    
}



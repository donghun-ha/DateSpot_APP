//
//  PlaceViewModel.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//
//


import SwiftUI

protocol PlaceQueryModelProtocol {
    func itemDownloaded(items: [PlaceData])
}

@MainActor
class PlaceViewModel: ObservableObject {
    var delegate: PlaceQueryModelProtocol?
    @Published var places: [PlaceData] = [] // 전체 장소 리스트
    @Published var nearbyPlaces: [PlaceData] = [] // 가까운 장소 리스트
    @Published var images: [String: UIImage] = [:] // 장소 이름을 키로 하는 이미지 딕셔너리
    let urlPath = "https://fastapi.fre.today/place"

    func downloadItems() async {
        let url = URL(string: "\(urlPath)/select")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decodedData = try? JSONDecoder().decode([PlaceData].self, from: data) {
                print("✅ 데이터 다운로드 성공: \(decodedData)")
                delegate?.itemDownloaded(items: decodedData)
            } else {
                print("❌ 데이터 파싱 실패")
            }
        } catch {
            print("❌ 데이터 다운로드 실패: \(error.localizedDescription)")
        }
    }
    
    // 전체 데이터를 다운로드하고 가까운 5개의 명소를 필터링
    func fetchPlaces(currentLat: Double, currentLng: Double) async {
        do {
            let fetchedPlaces = try await fetchPlacesFromAPI()
            let sortedPlaces = fetchedPlaces.sorted {
                calculateDistance(lat: $0.lat, lng: $0.lng, currentLat: currentLat, currentLng: currentLng) <
                calculateDistance(lat: $1.lat, lng: $1.lng, currentLat: currentLat, currentLng: currentLng)
            }
            
            // 메인 스레드에서 UI 상태 업데이트
            await MainActor.run {
                self.places = fetchedPlaces
                self.nearbyPlaces = Array(sortedPlaces.prefix(5))
            }
        } catch {
            print("❌ 데이터 다운로드 실패: \(error.localizedDescription)")
        }
    }

    
    // Fetch Places
    func fetchPlace() async {
        do {
            let fetchedPlace = try await fetchPlacesFromAPI()
            self.places = fetchedPlace
            print("✅ 데이터 다운로드 성공")
        } catch {
            print("❌ 데이터 다운로드 실패: \(error.localizedDescription)")
        }
    }
    
    // 이미지 로드
    func fetchImage(for placeName: String) async {
        guard images[placeName] == nil else { return } // 이미 로드된 경우
        print(placeName)
        let imageUrl = "https://fastapi.fre.today/place/image?name=\(placeName)"
        guard let url = URL(string: imageUrl) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.images[placeName] = image // 메인 스레드에서 업데이트
                }
            }
        } catch {
            print("❌ 이미지 다운로드 실패: \(error.localizedDescription)")
        }
    }



    // 거리 계산 함수
    func calculateDistance(lat: Double, lng: Double, currentLat: Double, currentLng: Double) -> Double {
        let deltaLat = lat - currentLat
        let deltaLng = lng - currentLng
        return sqrt(deltaLat * deltaLat + deltaLng * deltaLng) * 111 // 대략적인 거리(km)
    }
    
    private func fetchPlacesFromAPI() async throws -> [PlaceData] {
       guard let url = URL(string: "\(urlPath)/select") else {
           throw URLError(.badURL)
       }

       let (data, response) = try await URLSession.shared.data(from: url)

       guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
           throw URLError(.badServerResponse)
       }

       let decoder = JSONDecoder()
       return try decoder.decode([PlaceData].self, from: data)
   }

}


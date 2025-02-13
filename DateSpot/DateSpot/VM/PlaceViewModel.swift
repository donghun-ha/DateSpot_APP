//
//  PlaceViewModel.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI
import Foundation
import Combine



@MainActor
class PlaceViewModel: ObservableObject {
    @Published var nearbyPlaces: [PlaceData] = [] // 근처 명소 데이터
    @Published var bookmarkedPlaces: [BookmarkedPlace] = [] // 북마크 데이터
    @Published private(set) var places: [PlaceData] = [] // 전체 명소 리스트
    @Published private(set) var selectedPlace: PlaceData? // 선택된 명소 상세 정보
    @Published var images: [UIImage] = [] // 로드된 이미지 리스트
    @Published private(set) var images1: [String: UIImage] = [:] // 명소 이름별 첫 번째 이미지를 저장
    @Published var homeimage: [String: UIImage] = [:] // 명소 이름별 이미지 저장
    @Published var isBookmarked: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://port-0-datespot-m6k2ohs83ef13aeb.sel4.cloudtype.app/place/" // 기본 API URL

    // 전체 데이터를 다운로드하고 가까운 5개의 명소를 필터링
    func fetchPlaces(currentLat: Double, currentLng: Double) async {
        do {
            let fetchedPlaces = try await fetchPlacesFromAPI(currentLat: currentLat, currentLng: currentLng)
            
            // 거리 기준으로 정렬하고 상위 5개만 가져오기
            let sortedPlaces = fetchedPlaces
                .sorted {
                    calculateDistance(lat: $0.lat, lng: $0.lng, currentLat: currentLat, currentLng: currentLng) <
                    calculateDistance(lat: $1.lat, lng: $1.lng, currentLat: currentLat, currentLng: currentLng)
                }
                .prefix(5) // 상위 5개만 선택

            // 메인 스레드에서 UI 상태 업데이트
            await MainActor.run {
                self.places = fetchedPlaces
                self.nearbyPlaces = Array(sortedPlaces)
            }
        } catch {
            print("❌ 데이터 다운로드 실패: \(error.localizedDescription)")
        }
    }
    
    // Fetch Places
//    func fetchPlace() async {
//        do {
//            let fetchedPlace = try await fetchPlacesFromAPI(currentLat: currentLat, currentLng: currentLng)
//            self.places = fetchedPlace
//            print("✅ 데이터 다운로드 성공")
//        } catch {
//            print("❌ 데이터 다운로드 실패: \(error.localizedDescription)")
//        }
//    }
    
    func fetchFirstImage(for name: String) async {
        print("찾아야 할 명소 :\(name)")
        guard self.homeimage[name] == nil else { return } // 이미 로드된 경우 스킵
//        print("찾는 이미지 : \(homeimage[name])")
        let imageKeys = await fetchImageKeys(for: name)
        guard let firstKey = imageKeys.first else {
            print("No image keys found for place: \(name)")
            return
        }

        if let image = await fetchImage(fileKey: firstKey) {
            await MainActor.run {
                self.homeimage[name] = image // 명소 이름별 이미지 저장
            }
        }
    }
    

    /// 이미지 키 가져오기
    func fetchImageKeys(for name: String) async -> [String] {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        guard let url = URL(string: "\(baseURL)images?name=\(encodedName)") else {
            print("Invalid URL for fetchImageKeys")
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print(data)

            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }

            if let response = try? JSONDecoder().decode([String: [String]].self, from: data),
               let images = response["images"] {
                return images
            }

            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let errorDetail = errorResponse["detail"] {
                print("Server Error: \(errorDetail)")
            }

            return []
        } catch {
            print("Failed to fetch image keys: \(error)")
            return []
        }
    }

    /// 특정 이미지 키로 이미지 가져오기
    func fetchImage(fileKey: String) async -> UIImage? {
        guard let url = URL(string: "\(baseURL)image?file_key=\(fileKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fileKey)") else {
            print("Invalid URL for fetchImage")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Failed to fetch image: \(error)")
            return nil
        }
    }

    func loadImages(for name: String) async {
        let imageKeys = await fetchImageKeys(for: name)

        guard !imageKeys.isEmpty else {
            print("No image keys found for place: \(name)")
            return
        }

        var loadedImages: [UIImage] = []

        for key in imageKeys {
            if let image = await fetchImage(fileKey: key) {
                loadedImages.append(image)
            } else {
                print("Failed to load image for key: \(key)")
            }
        }

        if loadedImages.isEmpty {
            print("No images loaded for place: \(name)")
        }

        self.images = loadedImages
    }

    func fetchPlaceDetail(name: String) async {
        print("명소 디테일 가져오기")
        Task {
            do {
                let fetchedDetails = try await fetchPlaceDetailFromAPI(name: name)
                print("Response : \(fetchedDetails)")
                self.selectedPlace = fetchedDetails.first // 첫 번째 명소 선택
            } catch {
                print("Failed to fetch place detail: \(error.localizedDescription)")
            }
        }
    }


    func fetchNearbyPlaces(lat: Double, lng: Double, radius: Double = 1000) async {
        let endpoint = "\(baseURL)nearby_places/"
        guard let url = URL(string: endpoint) else {
            print("Invalid URL")
            return
        }

        let parameters: [String: Any] = [
            "lat": lat,
            "lng": lng,
            "radius": radius
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, _) = try await URLSession.shared.data(for: request)

            let decodedResponse = try JSONDecoder().decode([PlaceData].self, from: data)
            self.nearbyPlaces = decodedResponse
        } catch {
            print("Failed to fetch nearby places: \(error)")
        }
    }
    
    // 거리 계산 함수
    func calculateDistance(lat: Double, lng: Double, currentLat: Double, currentLng: Double) -> Double {
        let deltaLat = lat - currentLat
        let deltaLng = lng - currentLng
        return sqrt(deltaLat * deltaLat + deltaLng * deltaLng) * 111 // 대략적인 거리(km)
    }
}

// MARK: - Private Methods
extension PlaceViewModel {
    private func fetchPlacesFromAPI(currentLat: Double, currentLng: Double, limit: Int = 5) async throws -> [PlaceData] {
        guard var urlComponents = URLComponents(string: "\(baseURL)select") else {
            throw URLError(.badURL)
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "lat", value: "\(currentLat)"),
            URLQueryItem(name: "lng", value: "\(currentLng)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode([PlaceData].self, from: data)
    }


    private func fetchPlaceDetailFromAPI(name: String) async throws -> [PlaceData] {
        print("가져올 명소 : \(name)")
        guard var urlComponents = URLComponents(string: "\(baseURL)go_detail") else {
            throw URLError(.badURL)
        }

        urlComponents.queryItems = [URLQueryItem(name: "name", value: name)]

        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let jsonString = String(data: data, encoding: .utf8) {
            print("서버 응답 데이터: \(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // JSON 데이터에서 "results" 키 추출 및 디코딩
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let resultsArray = jsonObject?["results"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        // "results" 데이터를 JSON으로 다시 변환
        let resultsData = try JSONSerialization.data(withJSONObject: resultsArray, options: [])
        
        let decoder = JSONDecoder()
        return try decoder.decode([PlaceData].self, from: resultsData)
    }
    
    func addBookmark(userEmail: String, placeName: String, name: String) {
        // API URL
        guard let url = URL(string: "\(baseURL)add_bookmark/") else { return }
        
        // 요청 데이터
        let requestBody: [String: Any] = [
            "user_email": userEmail,
            "place_name": placeName,
            "name": name
        ]
        
        // JSON 데이터 생성
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // API 호출
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Bookmark added successfully")
                case .failure(let error):
                    print("Failed to add bookmark: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] _ in
                self?.isBookmarked = true
            })
            .store(in: &cancellables)
    }
    
    func checkBookmark(userEmail: String, placeName: String) {
        // API URL
        print("북마크 확인")
        guard let url = URL(string: "\(baseURL)check_bookmark/") else { return }
        
        // 요청 데이터
        let requestBody: [String: Any] = [
            "user_email": userEmail,
            "place_name": placeName
        ]
        
        // JSON 데이터 생성
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else { return }
        
        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // API 호출
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: [String: Bool].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Bookmark status checked successfully")
                case .failure(let error):
                    print("Failed to check bookmark: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                self?.isBookmarked = response["is_bookmarked"] ?? false
            })
            .store(in: &cancellables)
    }
    
    
    func fetchBookmarkedPlaces(userEmail: String) {
        // URL 구성 및 쿼리 파라미터 추가
        guard var urlComponents = URLComponents(string: "\(baseURL)get_user_bookmarks/") else {
            print("Invalid URL for fetching user bookmarks")
            return
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "user_email", value: userEmail)]
        
        guard let url = urlComponents.url else {
            print("Failed to construct URL with query parameters")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 빈 바디 추가 (FastAPI POST 요청에서 바디가 비어있을 때 오류 발생 가능)
        request.httpBody = Data()
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                // HTTP 응답 처리
                guard let response = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: [String: [BookmarkedPlace]].self, decoder: JSONDecoder()) // JSON 디코딩
            .receive(on: DispatchQueue.main) // UI 업데이트는 메인 스레드에서 수행
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error occurred: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                if let results = response["results"] {
                    print("Fetched bookmarked place: \(results)")
                    self?.bookmarkedPlaces = results
                } else {
                    print("No results found in response")
                    self?.bookmarkedPlaces = []
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteBookmark(userEmail: String, placeName: String, name: String) {
        // API URL
        guard let url = URL(string: "\(baseURL)delete_bookmark/") else {
            print("Invalid URL for deleting bookmark")
            return
        }
        
        // 요청 데이터
        let requestBody: [String: Any] = [
            "user_email": userEmail,
            "place_name": placeName,
            "name": name
        ]
        
        // JSON 데이터 생성
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to serialize JSON data")
            return
        }
        
        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // API 호출
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Bookmark deleted successfully")
                case .failure(let error):
                    print("Failed to delete bookmark: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] _ in
                // 삭제 후 로컬 북마크 상태 업데이트
                self?.isBookmarked = false
                self?.bookmarkedPlaces.removeAll { $0.name == placeName }
            })
            .store(in: &cancellables)
    }
}

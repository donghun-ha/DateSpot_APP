//
//  RestaurantViewModel.swift
//  DateSpot
//
//  Created by 이원영 on 12/27/24.
//

import SwiftUI
import Foundation
import Combine

protocol RestaurantViewModelProtocol: ObservableObject {
    var restaurants: [Restaurant] { get } // 전체 레스토랑 리스트
    var selectedRestaurant: Restaurant? { get } // 선택된 레스토랑 상세 정보
    var images: [UIImage] { get } // 로드된 이미지 리스트

    func fetchImageKeys(for name: String) async -> [String]
    func fetchImage(fileKey: String) async -> UIImage?
    func loadImages(for name: String) async
    func fetchRestaurants() async
    func fetchRestaurantDetail(name: String) async
}

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var bookmarkedRestaurants: [BookmarkedRestaurant] = [] // 북마크 데이터
    @Published private(set) var restaurants: [Restaurant] = [] // 전체 레스토랑 리스트
    @Published private(set) var selectedRestaurant: Restaurant? // 선택된 레스토랑 상세 정보
    @Published var images: [UIImage] = [] // 로드된 이미지 리스트
    @Published private(set) var images1: [String: UIImage] = [:] // 맛집 이름별 첫 번째 이미지를 저장
    @Published var homeimage: [String: UIImage] = [:] // 레스토랑 이름별 이미지 저장
    @Published var isBookmarked: Bool = false
//    @Published var bookmarkedRestaurants: [Restaurant] = [] // 북마크된 레스토랑 리스트
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://fastapi.fre.today/restaurant/" // 기본 API URL

    
    func fetchRestaurants() async {
        Task {
            do {
                let fetchedRestaurants = try await fetchRestaurantsFromAPI()
                self.restaurants = Array(fetchedRestaurants.prefix(30)) // 최대 30개로 제한
            } catch {
                print("Failed to fetch restaurants: \(error.localizedDescription)")
            }
        }
    }

    
    func fetchFirstImage(for name: String) async {
        guard homeimage[name] == nil else { return } // 이미 로드된 경우 스킵

            let imageKeys = await fetchImageKeys(for: name)
            guard let firstKey = imageKeys.first else {
                print("No image keys found for restaurant: \(name)")
                return
            }

            if let image = await fetchImage(fileKey: firstKey) {
                await MainActor.run {
                    self.homeimage[name] = image // 레스토랑 이름별 이미지 저장
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
                let response = try JSONDecoder().decode([String: [String]].self, from: data)
                return response["images"] ?? []
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
            print("No image keys found for restaurant: \(name)")
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
            print("No images loaded for restaurant: \(name)")
        }

        self.images = loadedImages
    }

//    func fetchRestaurants() async {
//        Task {
//            do {
//                let fetchedRestaurants = try await fetchRestaurantsFromAPI()
//                self.restaurants = fetchedRestaurants
//            } catch {
//                print("Failed to fetch restaurants: \(error.localizedDescription)")
//            }
//        }
//    }

    func fetchRestaurantDetail(name: String) async {
        Task {
            do {
                let fetchedDetail = try await fetchRestaurantDetailFromAPI(name: name)
                self.selectedRestaurant = fetchedDetail
            } catch {
                print("Failed to fetch restaurant detail: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Private Methods
extension RestaurantViewModel {
    private func fetchRestaurantsFromAPI() async throws -> [Restaurant] {
        guard let url = URL(string: "\(baseURL)restaurant_select_all") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // JSON 응답 디버깅용 출력
            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Response JSON: \(jsonString)")
            }

        let decoder = JSONDecoder()
        return try decoder.decode([String:[Restaurant]].self, from: data)["results"] ?? []
    }

    private func fetchRestaurantDetailFromAPI(name: String) async throws -> Restaurant {
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

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let decodedResponse = try decoder.decode([String: [Restaurant]].self, from: data)
            guard let restaurant = decodedResponse["results"]?.first else {
                throw URLError(.cannotDecodeContentData)
            }
            return restaurant
        } catch {
            print("Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Response JSON: \(jsonString)")
            }
            throw error
        }
    }
    
    
    
    func addBookmark(userEmail: String, restaurantName: String, name: String) {
        // API URL
        guard let url = URL(string: "\(baseURL)add_bookmark/") else { return }

        // 요청 데이터
        let requestBody: [String: Any] = [
            "user_email": userEmail,
            "restaurant_name": restaurantName,
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
    
    func checkBookmark(userEmail: String, restaurantName: String) {
        // API URL
        print("북마크 확인")
        guard let url = URL(string: "\(baseURL)check_bookmark/") else { return }

        // 요청 데이터
        let requestBody: [String: Any] = [
            "user_email": userEmail,
            "restaurant_name": restaurantName
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
    
    
    func fetchBookmarkedRestaurants(userEmail: String) {
        // URL 구성 및 쿼리 파라미터 추가
        guard var urlComponents = URLComponents(string: "https://fastapi.fre.today/restaurant/get_user_bookmarks/") else {
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
                print("HTTP Status Code: \(response.statusCode)") // 상태 코드 출력
                guard response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: [String: [BookmarkedRestaurant]].self, decoder: JSONDecoder()) // JSON 디코딩
            .receive(on: DispatchQueue.main) // UI 업데이트는 메인 스레드에서 수행
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error occurred: \(error.localizedDescription)")
                }
            }, receiveValue: { [weak self] response in
                if let results = response["results"] {
                    print("Fetched bookmarked restaurants: \(results)")
                    self?.bookmarkedRestaurants = results
                } else {
                    print("No results found in response")
                    self?.bookmarkedRestaurants = []
                }
            })
            .store(in: &cancellables)
    }
}


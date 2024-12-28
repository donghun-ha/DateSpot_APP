//
//  RestaurantViewModel.swift
//  DateSpot
//
//  Created by 이종남 on 12/27/24.
//

import SwiftUI
import Foundation

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = [] // 전체 레스토랑 리스트
    @Published var selectedRestaurant: Restaurant? // 선택된 레스토랑 상세 정보
    @Published var images: [UIImage] = [] // 로드된 이미지 리스트
    
    private let baseURL = "https://fastapi.fre.today/restaurant/" // 기본 API URL

    // 이미지 키 목록 가져오기
    func fetchImageKeys(for name: String) async -> [String] {
        // 이름 인코딩
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        guard let url = URL(string: "\(baseURL)images/?name=\(encodedName)") else {
            print("Invalid URL for fetchImageKeys")
            return []
        }
        
        do {
            print("Fetching image keys for name: \(name)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Image keys HTTP response status code: \(httpResponse.statusCode)")
            }

            let returnresponse = try JSONDecoder().decode([String: [String]].self, from: data)
            let keys = returnresponse["images"] ?? []
            print("Fetched image keys: \(keys)")
            return keys
        } catch {
            print("Failed to fetch image keys: \(error)")
            return []
        }
    }

    // S3에서 이미지를 가져오기
    func fetchImage(fileKey: String) async -> UIImage? {
        guard let url = URL(string: "\(baseURL)image/?file_key=\(fileKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fileKey)") else {
            print("Invalid URL for fetchImage")
            return nil
        }
        
        do {
            print("Fetching image for fileKey: \(fileKey)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Image HTTP response status code: \(httpResponse.statusCode)")
            }

            guard let image = UIImage(data: data) else {
                print("Failed to convert data to UIImage for fileKey: \(fileKey)")
                return nil
            }

            print("Successfully fetched image for fileKey: \(fileKey)")
            return image
        } catch {
            print("Failed to fetch image: \(error)")
            return nil
        }
    }

    // 전체 이미지 로드
    func loadImages(for name: String) async {
        print("Loading images for restaurant: \(name)")
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
        } else {
            print("Successfully loaded \(loadedImages.count) images for restaurant: \(name)")
        }

        self.images = loadedImages
    }
    
    // Fetch Restaurants
    func fetchRestaurants() async{
        Task {
            do {
                let fetchedRestaurants = try await fetchRestaurantsFromAPI()
                self.restaurants = fetchedRestaurants
            } catch {
                print("Failed to fetch restaurants: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetch Restaurant Detail
    func fetchRestaurantDetail(name: String = "3대삼계장인") async{
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

extension RestaurantViewModel {
    // Fetch Restaurants from API
    private func fetchRestaurantsFromAPI() async throws -> [Restaurant] {
        guard let url = URL(string: baseURL) else {
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
        return try decoder.decode([Restaurant].self, from: data)
    }

    // Fetch Restaurant Detail from API
    private func fetchRestaurantDetailFromAPI(name: String) async throws -> Restaurant {
        guard var urlComponents = URLComponents(string: "\(baseURL)go_detail") else {
            throw URLError(.badURL)
        }

        // 쿼리 파라미터 추가
        urlComponents.queryItems = [
            URLQueryItem(name: "name", value: name)
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

        // JSON 디코딩
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // JSON 키를 스네이크 케이스에서 카멜 케이스로 자동 변환
        do {
            let decodedResponse = try decoder.decode([String: [Restaurant]].self, from: data)
            // "results" 키의 첫 번째 레스토랑 반환
            guard let restaurant = decodedResponse["results"]?.first else {
                throw URLError(.cannotDecodeContentData)
            }
            return restaurant
        } catch {
            print("Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            throw error
        }


    }


}

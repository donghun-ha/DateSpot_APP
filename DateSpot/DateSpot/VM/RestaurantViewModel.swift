//
//  RestaurantViewModel.swift
//  DateSpot
//
//  Created by 이원영 on 12/27/24.
//

import SwiftUI
import Foundation

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
    @Published private(set) var restaurants: [Restaurant] = [] // 전체 레스토랑 리스트
    @Published private(set) var selectedRestaurant: Restaurant? // 선택된 레스토랑 상세 정보
    @Published private(set) var images: [UIImage] = [] // 로드된 이미지 리스트
    
    
    private let baseURL = "https://fastapi.fre.today/restaurant/" // 기본 API URL

    
    func fetchImageKeys(for name: String) async -> [String] {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        guard let url = URL(string: "\(baseURL)images/?name=\(encodedName)") else {
            print("Invalid URL for fetchImageKeys")
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let returnresponse = try JSONDecoder().decode([String: [String]].self, from: data)
            let keys = returnresponse["images"] ?? []
            return keys
        } catch {
            print("Failed to fetch image keys: \(error)")
            return []
        }
    }

    func fetchImage(fileKey: String) async -> UIImage? {
        guard let url = URL(string: "\(baseURL)image/?file_key=\(fileKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fileKey)") else {
            print("Invalid URL for fetchImage")
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                print("Failed to convert data to UIImage for fileKey: \(fileKey)")
                return nil
            }

            return image
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

    func fetchRestaurants() async {
        Task {
            do {
                let fetchedRestaurants = try await fetchRestaurantsFromAPI()
                self.restaurants = fetchedRestaurants
            } catch {
                print("Failed to fetch restaurants: \(error.localizedDescription)")
            }
        }
    }

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
                print("Response JSON: \(jsonString)")
            }
            throw error
        }
    }
}

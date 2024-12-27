//
//  RestaurantViewModel.swift
//  DateSpot
//
//  Created by 이종남 on 12/27/24.
//

import Foundation

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = [] // 전체 레스토랑 리스트
    @Published var selectedRestaurant: Restaurant? // 선택된 레스토랑 상세 정보
    private let baseURL = "https://fastapi.fre.today/restaurant" // 기본 API URL

    // Fetch Restaurants
    func fetchRestaurants() {
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
    func fetchRestaurantDetail(name: String = "3대삼계장인") {
        print("fetching restaurant detail")
        Task {
            do {
                let fetchedDetail = try await fetchRestaurantDetailFromAPI(name: name)
                self.selectedRestaurant = fetchedDetail
                print(fetchedDetail)
                print(selectedRestaurant!)
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
        guard var urlComponents = URLComponents(string: "https://fastapi.fre.today/restaurant/") else {
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

        // 디버깅용 JSON 응답 출력
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }

        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode([String: [Restaurant]].self, from: data)

        // "results" 키의 첫 번째 레스토랑 반환
        guard let restaurant = decodedResponse["results"]?.first else {
            throw URLError(.cannotDecodeContentData)
        }
        print(restaurant)
        return restaurant
    }

}

//
//  RestaurantViewModel.swift
//  DateSpot
//
//  Created by 이종남 on 12/27/24.
//

import Foundation

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    
    // 예시: 서버 주소
    private let baseURL = "https://fastapi.fre.today/restaurant/restaurant_select_all"
    private let defaultEmail = "jongnam16@gmail.com" // 테스트용 (필요시)
    
    // MARK: - Fetch (GET)
    func fetchRestaurants(for email: String? = nil) {
        let userEmail = email ?? defaultEmail
        
        Task {
            do {
                let fetched = try await fetchRestaurantsFromAPI(userEmail: userEmail)
                self.restaurants = fetched
            } catch {
                print("Failed to fetch restaurants:", error.localizedDescription)
            }
        }
    }
}

extension RestaurantViewModel {
    // MARK: - 실제 서버 통신 로직

    // [1] Fetch from API
    private func fetchRestaurantsFromAPI(userEmail: String) async throws -> [Restaurant] {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        // 필요하다면 email 파라미터를 쿼리로 추가
        urlComponents.queryItems = [
            URLQueryItem(name: "user_email", value: userEmail)
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard
          let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        // 디버깅용
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON (fetchRestaurants): \(jsonString)")
        }
        
        let decoder = JSONDecoder()
        
        // 아래와 같이 Dictionary 형태로 먼저 디코드하고 "results" 키를 꺼냄
        let decoded = try decoder.decode([String: [Restaurant]].self, from: data)
        return decoded["results"] ?? []
    }
    
}

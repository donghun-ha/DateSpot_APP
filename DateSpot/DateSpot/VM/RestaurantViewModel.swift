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
    private let baseURL = "https://fastapi.fre.today/restaurant/" // 기본 API URL

    // Fetch Restaurants
    func fetchRestaurants() async{
        Task {
            do {
                let fetchedRestaurants = try await fetchRestaurantsFromAPI()
                self.restaurants = fetchedRestaurants
                print(self.restaurants)
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
        guard let url = URL(string: "\(baseURL)restaurant_select_all") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        // HTTP 상태 코드 확인
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()

        // JSON 데이터를 파싱하여 수동 매핑
        do {
            // FastAPI 응답 디코딩
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let resultArray = jsonResponse["result"] as? [[Any]] {
                
                // `result` 배열의 각 항목을 Restaurant 모델로 변환
                return resultArray.compactMap { item in
                    guard item.count == 10,
                          let name = item[0] as? String,
                          let address = item[1] as? String,
                          let lat = item[2] as? Double,
                          let lng = item[3] as? Double,
                          let parking = item[4] as? String,
                          let operatingHour = item[5] as? String,
                          let closedDays = item[6] as? String,
                          let contactInfo = item[7] as? String else {
                        return nil
                    }
                    let breakTime = item[8] as? String
                    let lastOrder = item[9] as? String

                    return Restaurant(
                        name: name,
                        address: address,
                        lat: lat,
                        lng: lng,
                        parking: parking,
                        operatingHour: operatingHour,
                        closedDays: closedDays,
                        contactInfo: contactInfo,
                        breakTime: breakTime,
                        lastOrder: lastOrder
                    )
                }
            } else {
                throw URLError(.cannotParseResponse)
            }
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
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
            throw error
        }


    }


}

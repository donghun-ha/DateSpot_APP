//
//  RatingViewModel.swift
//  DateSpot
//

import Foundation

@MainActor
class RatingViewModel: ObservableObject {
    @Published var ratings: [Rating] = [] // View에서 바인딩 가능
    private let baseURL = "https://fastapi.fre.today/rating" // API URL
    private let defaultEmail = "dnjsd97@gmail.com" // 테스트용 이메일
    
    // Fetch Ratings
    func fetchRatings(for email: String? = nil) {
        let userEmail = email ?? defaultEmail
        Task {
            do {
                let ratings = try await fetchRatingsFromAPI(userEmail: userEmail)
                self.ratings = ratings
            } catch {
                print("Failed to fetch ratings: \(error.localizedDescription)")
            }
        }
    }
    
    // Insert Rating
    func insertRating(_ rating: Rating) {
        Task {
            do {
                let success = try await insertRatingToAPI(rating)
                if success {
                    print("Rating successfully inserted")
                    // Fetch 업데이트된 데이터
                    await fetchRatings(for: rating.userEmail)
                }
            } catch {
                print("Failed to insert rating: \(error.localizedDescription)")
            }
        }
    }
}

extension RatingViewModel {
    // Fetch Ratings from API
    private func fetchRatingsFromAPI(userEmail: String) async throws -> [Rating] {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }

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
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // 디버깅: 응답 데이터 출력
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response JSON: \(jsonString)")
        }

        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode([String: [Rating]].self, from: data)
        return decodedResponse["results"] ?? []
    }
    
    // Insert Rating to API
    private func insertRatingToAPI(_ rating: Rating) async throws -> Bool {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(rating)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
            print("Failed response: \(httpResponse.statusCode), Message: \(errorMessage)")
            throw URLError(.badServerResponse)
        }
        
        return true
    }
    
    func updateRating(_ rating: Rating) async throws {
        guard let url = URL(string: "\(baseURL)/\(rating.id)") else { // ID를 기반으로 URL 생성
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(rating)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
            print("Failed response: \(httpResponse.statusCode), Message: \(errorMessage)")
            throw URLError(.badServerResponse)
        }

        // 서버 업데이트 성공 후, 로컬 데이터를 갱신
        await fetchRatings(for: rating.userEmail)
    }
}

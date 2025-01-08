//
//  RatingViewModel.swift
//  DateSpot
//

import SwiftUI
import Foundation


protocol RatingViewModelProtocol {
    var ratings: [Rating] { get } // 별점 리스트
    var userRating: Int? { get }  // 현재 사용자의 별점
    
    func restaurantfetchUserRating(for email: String, restaurantName: String) async
    func restaurantupdateUserRating(for email: String, restaurantName: String, rating: Int) async
    
    func placefetchUserRating(for email: String, placeName: String) async
    func placeupdateUserRating(for email: String, placeName: String, rating: Int) async
}



@MainActor
class RatingViewModel: ObservableObject {
    @Published var ratings: [Rating] = [] // 서버에서 가져온 별점 리스트
    @Published var userRating: Int? // 현재 사용자의 별점
    private let baseURL = "https://fastapi.fre.today/rating" // API URL

    // 특정 레스토랑의 별점 가져오기
    func restaurantfetchUserRating(for email: String, restaurantName: String) async {
        guard let url = URL(string: "\(baseURL)/get_detail?user_email=\(email)&book_name=\(restaurantName)") else {
            print("Invalid URL for fetchUserRating")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch user rating: Server error")
                return
            }

            let decodedResponse = try JSONDecoder().decode([String: [Rating]].self, from: data)
            if let userRating = decodedResponse["results"]?.first?.evaluation {
                self.userRating = Int(userRating)
            }
        } catch {
            print("Failed to fetch user rating: \(error.localizedDescription)")
        }
    }
    
    // 특정 명소의 별점 가져오기
    func placefetchUserRating(for email: String, placeName: String) async {
        guard let url = URL(string: "\(baseURL)/get_detail?user_email=\(email)&book_name=\(placeName)") else {
            print("Invalid URL for fetchUserRating")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch user rating: Server error")
                return
            }

            let decodedResponse = try JSONDecoder().decode([String: [Rating]].self, from: data)
            if let userRating = decodedResponse["results"]?.first?.evaluation {
                self.userRating = Int(userRating)
            }
        } catch {
            print("Failed to fetch user rating: \(error.localizedDescription)")
        }
    }
    
    // 레스토랑 별점 업데이트
    func restaurantupdateUserRating(for email: String, restaurantName: String, rating: Int) async {
        guard let url = URL(string: "\(baseURL)/update_detail") else {
            print("Invalid URL for updateUserRating")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newRating = Rating(
            userEmail: email,
            bookName: restaurantName,
            evaluation: Double(rating)
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(newRating)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to update user rating: Server error")
                return
            }
            // 업데이트 후 새로 가져오기
            await restaurantfetchUserRating(for: email, restaurantName: restaurantName)
        } catch {
            print("Failed to update user rating: \(error.localizedDescription)")
        }
    }
    
    // 명소 별점 업데이트
    func placeupdateUserRating(for email: String, placeName: String, rating: Int) async {
        guard let url = URL(string: "\(baseURL)/update_detail") else {
            print("Invalid URL for updateUserRating")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newRating = Rating(
            userEmail: email,
            bookName: placeName,
            evaluation: Double(rating)
        )
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(newRating)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to update user rating: Server error")
                return
            }
            // 업데이트 후 새로 가져오기
            await placefetchUserRating(for: email, placeName: placeName)
        } catch {
            print("Failed to update user rating: \(error.localizedDescription)")
        }
    }
}

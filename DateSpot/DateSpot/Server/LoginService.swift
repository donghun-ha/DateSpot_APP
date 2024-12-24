//
//  LoginService.swift
//  DateSpot
//
//  Created by 하동훈 on 24/12/2024.
//

import Foundation

class LoginService {
    /*
     사용자 데이터 백엔드 전송
     - Parameters:
        - email : 사용자 이메일
        - name : 사용자 이름
     */
    func sendUserData(email: String, name: String) async throws -> [String: Any]{
        guard let url = URL(string: "https://fastapi.fre.today/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = ["email": email, "name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        return jsonResponse
    }
    
} // LoginService

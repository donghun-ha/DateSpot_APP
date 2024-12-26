//
//  LoginService.swift
//  DateSpot
//
//  Created by 하동훈 on 24/12/2024.
//

import Foundation


// FastAPI 서버로 사용자 정보를 전송
class LoginService {
    /*
     사용자 데이터 백엔드 전송
     - Parameters:
        - email : 사용자 이메일
        - name : 사용자 이름
     */
    
    // 서버에 이메일, 이름 전송 후 JSON 응답
    func sendUserData(email: String, name: String) async throws -> [String: Any]{
        // FastApi 주소 설정
        guard let url = URL(string: "https://fastapi.fre.today/login") else {
            throw URLError(.badURL)
        }
        
        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        // JSON 바디 구성
        let requestBody: [String: Any] = ["email": email, "name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        // 비동기 네트워크 통신
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 응답 상태 확인
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // JSON 파싱
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        return jsonResponse
    }
    
} // LoginService

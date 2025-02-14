//
//  UserViewModel.swift
//  DateSpot
//

import Foundation
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    @Published var userImage: String = "" // 사용자 이미지 URL
    @Published var isUploading: Bool = false // 업로드 상태 플래그
    
    private let backendBaseURL = "https://port-0-datespot-m6k2ohs83ef13aeb.sel4.cloudtype.app"
    
    // 사용자 이미지 가져오기
    func fetchUserImage(email: String) async {
        guard let url = URL(string: "\(backendBaseURL)/get-profile-image") else {
            print("❌ 잘못된 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "user_id=\(email)"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ 서버 응답 오류: \(response)")
                return
            }
            
            let json = try JSONDecoder().decode(UserResponse.self, from: data)
            DispatchQueue.main.async {
                self.userImage = json.image_url
            }
        } catch {
            print("❌ 사용자 이미지 가져오기 실패: \(error.localizedDescription)")
        }
    }
    
    // 이미지 업로드
    func uploadImage(email: String, image: UIImage) async {
        isUploading = true
        guard let url = URL(string: "\(backendBaseURL)/upload-profile") else {
            print("❌ 잘못된 URL")
            isUploading = false
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 이미지 변환 실패")
            isUploading = false
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(email)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ 서버 응답 오류: \(response)")
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let imageUrl = jsonResponse["image_url"] as? String {
                DispatchQueue.main.async {
                    self.userImage = imageUrl
                }
            } else {
                print("❌ JSON 응답 파싱 실패")
            }
        } catch {
            print("❌ 네트워크 요청 실패: \(error.localizedDescription)")
        }
        
        isUploading = false
    }
    
    // 사용자 계정 로그아웃
    func logoutUser(email: String) async {
        guard let url = URL(string: "\(backendBaseURL)/logout") else {
            print("사용자 로그아웃 잘못된 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "user_id=\(email)"
        request.httpBody = body.data(using: .utf8)
        
        do{
            let(data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("사용자 로그아웃 서버: \(response)")
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let message = jsonResponse["message"] as? String {
                print("사용자 로그아웃 성공: \(message)")
            } else {
                print("Logout JSON 응답 파싱 실패")
            }
        } catch {
            print("logout 네트워크 요청 실패 : \(error.localizedDescription)")
        }
    }
    
    // 사용자 계정 탈퇴
    func deleteUser(email: String) async {
        guard let url = URL(string: "\(backendBaseURL)/account_delete") else {
            print("사용자 계정 탈퇴 잘못된 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "user_id=\(email)"
        request.httpBody = body.data(using: .utf8)
        
        do{
            let(data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("사용자 탈퇴 서버 응답 오류: \(response)")
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let message = jsonResponse["message"] as? String {
                print("사용자 계정 삭제 성공: \(message)")
            } else {
                print("JSON 응답 파싱 실패")
            }
        } catch {
            print("네트워크 요청 실패: \(error.localizedDescription)")
        }
    }
}

// 사용자 데이터를 디코딩하기 위한 구조체
struct UserResponse: Codable {
    let image_url: String
}

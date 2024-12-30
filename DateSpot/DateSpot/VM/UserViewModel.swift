//
//  UserViewModel.swift
//  DateSpot
//

import Foundation
import SwiftUI
import RealmSwift

class UserViewModel: ObservableObject {
    @EnvironmentObject var appState: AppState // AppState 인스턴스
    @Published var userName: String = "" // 사용자 이름
    @Published var userImage: String = "" // 사용자 이미지 URL
    @Published var isUploading: Bool = false // 업로드 상태 플래그
    private let realm = try! Realm() // Realm 인스턴스

    // FastAPI 엔드포인트 URL
    private let backendBaseURL = "https://fastapi.fre.today"

    // 백엔드에서 사용자 데이터 로드
    func loadUserDataFromBackend(email: String) async {
        guard let url = URL(string: "\(backendBaseURL)/upload-profile") else {
            print("❌ 잘못된 URL")
            return
        }

        // POST 요청 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 요청 본문에 user_id 추가
        let requestBody: [String: String] = ["user_id": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        print("ℹ️ 요청 본문: \(requestBody)")

        do {
            // URLSession으로 요청 실행
            print("ℹ️ 백엔드로 데이터 요청 시작")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 응답이 HTTP 응답이 아님")
                return
            }

            print("ℹ️ 서버 응답 코드: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("❌ 서버 응답 오류: \(response)")
                print("❌ 응답 데이터: \(String(data: data, encoding: .utf8) ?? "No Data")")
                return
            }

            // JSON 응답 디코딩
            let json = try JSONDecoder().decode(UserResponse.self, from: data)
            print("✅ 사용자 데이터 로드 성공: \(json)")

            // AppState와 Realm 업데이트
            DispatchQueue.main.async {
                print("ℹ️ AppState와 Realm 업데이트 시작")
                self.appState.userName = json.name
                self.appState.userImage = json.image
                self.updateUserInRealm(email: email, imageUrl: json.image)
                print("✅ AppState와 Realm 업데이트 완료")
            }
        } catch {
            print("❌ 사용자 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    // 프로필 이미지 업로드 (FastAPI 호출)
    func uploadProfileImage(email: String, image: UIImage) async {
        isUploading = true
        guard let url = URL(string: "\(backendBaseURL)/upload-profile") else {
            print("❌ 잘못된 URL")
            isUploading = false
            return
        }

        // UIImage를 JPEG 데이터로 변환
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 이미지 변환 실패")
            isUploading = false
            return
        }

        // Boundary 생성
        let boundary = UUID().uuidString
        print("ℹ️ 생성된 Boundary: \(boundary)")

        // URLRequest 설정
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Multipart Form Data Body 생성
        var body = Data()

        // user_id 필드 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(email)\r\n".data(using: .utf8)!)
        print("ℹ️ user_id 추가 완료")

        // image 필드 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        print("ℹ️ 이미지 데이터 추가 완료")

        // Boundary 종료
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // Body 설정
        request.httpBody = body
        print("ℹ️ HTTP 요청 Body 구성 완료")

        // URLSession으로 요청 전송
        do {
            print("ℹ️ 이미지 업로드 요청 시작")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 응답이 HTTP 응답이 아님")
                return
            }

            print("ℹ️ 서버 응답 코드: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                print("❌ 서버 응답 오류: \(response)")
                print("❌ 응답 데이터: \(String(data: data, encoding: .utf8) ?? "No Data")")
                return
            }

            // JSON 응답 파싱
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let imageUrl = jsonResponse["image_url"] as? String {
                print("✅ 이미지 업로드 성공: \(imageUrl)")

                // AppState와 Realm 업데이트
                DispatchQueue.main.async {
                    print("ℹ️ AppState와 Realm 업데이트 시작")
                    self.appState.userImage = imageUrl
                    self.updateUserInRealm(email: email, imageUrl: imageUrl)
                    print("✅ AppState와 Realm 업데이트 완료")
                }
            } else {
                print("❌ JSON 응답 파싱 실패")
            }
        } catch {
            print("❌ 네트워크 요청 실패: \(error.localizedDescription)")
        }

        isUploading = false
    }

    // Realm에 사용자 데이터 업데이트
    private func updateUserInRealm(email: String, imageUrl: String) {
        if let user = realm.objects(UserData.self).filter("userEmail == %@", email).first {
            do {
                try realm.write {
                    user.userImage = imageUrl
                }
                DispatchQueue.main.async {
                    print("ℹ️ Realm 데이터 업데이트 시작")
                    self.userImage = imageUrl
                    print("✅ Realm 사용자 데이터 업데이트 완료")
                }
            } catch {
                print("❌ Realm 사용자 데이터 업데이트 실패: \(error.localizedDescription)")
            }
        } else {
            print("❌ Realm에 해당 사용자가 존재하지 않습니다.")
        }
    }
}

// 사용자 데이터를 디코딩하기 위한 구조체
struct UserResponse: Codable {
    let name: String
    let image: String
}

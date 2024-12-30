//
//  UserViewModel.swift
//  DateSpot
//

import Foundation
import SwiftUI
import RealmSwift

class UserViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userImage: String = ""
    @Published var isUploading: Bool = false
    private let realm = try! Realm()

    // FastAPI 엔드포인트 URL
    private let backendBaseURL = "https://fastapi.fre.today"

    // Realm에서 사용자 데이터 로드
    func loadUserDataFromBackend(email: String) async {
        guard let url = URL(string: "\(backendBaseURL)/get-profile?email=\(email)") else {
            print("❌ 잘못된 URL")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ 서버 응답 오류")
                return
            }

            let json = try JSONDecoder().decode(UserResponse.self, from: data)
            DispatchQueue.main.async {
                self.userName = json.name
                self.userImage = json.image
                self.updateUserInRealm(email: email, name: json.name, imageUrl: json.image)
            }
        } catch {
            print("❌ 사용자 데이터 로드 실패: \(error.localizedDescription)")
        }
    }

    // 프로필 이미지 업로드 (FastAPI 호출)
    func uploadProfileImage(email: String, image: UIImage) {
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

        // Multipart Form Data 구성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
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

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isUploading = false
            }
            if let error = error {
                print("❌ 이미지 업로드 실패: \(error.localizedDescription)")
                return
            }

            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ 서버 응답 오류")
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let imageUrl = jsonResponse["image_url"] as? String {
                    print("✅ Image uploaded successfully: \(imageUrl)")
                    self?.updateUserInRealm(email: email, imageUrl: imageUrl)
                } else {
                    print("❌ JSON 응답 파싱 실패")
                }
            } catch {
                print("❌ 이미지 업로드 처리 실패: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Realm에 사용자 데이터 업데이트
    private func updateUserInRealm(email: String, imageUrl: String) {
        if let user = realm.objects(UserData.self).filter("userEmail == %@", email).first {
            do {
                try realm.write {
                    user.userImage = imageUrl
                }
                DispatchQueue.main.async {
                    self.userImage = imageUrl
                }
                print("✅ Realm 사용자 데이터 업데이트 성공")
            } catch {
                print("❌ Realm 사용자 데이터 업데이트 실패: \(error.localizedDescription)")
            }
        } else {
            print("❌ Realm에 해당 사용자가 존재하지 않습니다.")
        }
    }
}

//
//  UserService.swift
//  DateSpot
//
//  Created by 하동훈 on 30/12/2024.
//  Description : S3와 MySQL에 이미지를 업로드하기 위해 UIImage를 Data로 변환하고, 서버와의 통신을 통해 URL을 반환

import Foundation
import UIKit

class UserService {
    static let shared = UserService()

    private init() {}

    func uploadProfileImage(email: String, image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://fastapi.fre.today/upload-profile") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        // UIImage를 JPEG 데이터로 변환
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Invalid Image", code: -1, userInfo: nil)))
            return
        }

        // Multipart Form Data 구성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 이메일 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"email\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(email)\r\n".data(using: .utf8)!)

        // 이미지 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 백엔드 호출
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "Invalid Response", code: -1, userInfo: nil)))
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let imageUrl = jsonResponse["image_url"] as? String {
                    completion(.success(imageUrl))
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

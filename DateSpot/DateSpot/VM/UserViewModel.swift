//
//  UserViewModel.swift
//  DateSpot
//
//  Created by 하동훈 on 30/12/2024.
//

import SwiftUI
import RealmSwift

class UserViewModel: ObservableObject {
    @Published var currentUser: UserData? // 현재 사용자
    @Published var errorMessage: String = "" // 오류 메시지
    
    // 사용자 데이터 로드
    func loadCurrentUSer(email: String) {
        if let user = RealmService.shared.fetchUser(byEmail: email) {
            DispatchQueue.main.async {
                self.currentUser = user
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "사용자를 찾을 수 없습니다."
            }
        }
    }
    
    // 사용자 데이터 추가 또는 업데이트
    func saveUser(email: String, name: String, image: String) {
        let user = UserData(userEmail: email, userName: name, userImage: image)
        RealmService.shared.saveUser(user)
        loadCurrentUSer(email: email) // 저장 후 다시 로드
    }
    
    // 사용자 데이터 삭제
    func deleteUser(email: String) {
        RealmService.shared.deleteUser(byEmail: email)
        DispatchQueue.main.async {
            self.currentUser = nil
        }
    }
    
    func uploadProfileImage(email: String, name: String, image: UIImage) {
        UserService.shared.uploadProfileImage(email: email, image: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageUrl):
                    print("✅ Image uploaded successfully: \(imageUrl)")
                    // 서버에 저장된 URL을 반영
                    self.updateUser(email: email, name: name, image: imageUrl)
                case .failure(let error):
                    print("❌ Error uploading image: \(error.localizedDescription)")
                }
            }
        }
    }

    func updateUser(email: String, name: String, image: String) {
        // 여기서 서버와 Realm 데이터 동기화 처리 가능
        print("✅ User updated with name: \(name), image: \(image)")
    }
}

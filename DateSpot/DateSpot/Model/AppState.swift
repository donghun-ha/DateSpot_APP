//
//  AppState.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//

import SwiftUI
import RealmSwift

// 앱의 전역 상태를 관리하는 클래스
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false // 로그인 여부
    @Published var userEmail: String? = nil // 로그인한 사용자 이메일
    @Published var userName: String? = nil // 로그인한 사용자 이름
    @Published var userImage: String? = nil // 로그인한 사용자 프로필 이미지
    @AppStorage("isDarkMode") var isDarkMode: Bool = false // Dark Mode
    
    private let realm: Realm

    init() {
        // Realm 초기화 및 자동 로그인 처리
        do {
            self.realm = try Realm()
            loadUserDataIfAvailable()
        } catch {
            fatalError("Realm 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    // Realm에서 사용자 데이터 로드
    func loadUserDataIfAvailable() {
        print("🔍 Realm 데이터 로드 시작")
        let users = realm.objects(UserData.self)
        guard let user = users.first else {
            print("❌ 저장된 사용자 데이터 없음")
            return
        }

        DispatchQueue.main.async {
            self.updateUserData(email: user.userEmail, name: user.userName, image: user.userImage)
            print("✅ Realm 데이터 로드 성공: \(user)")
        }
    }

    // Realm에 사용자 데이터 저장
    func saveUserData(email: String, name: String, image: String) {
        print("🔍 AppState의 saveUserData 호출됨")
        let data = UserData(userEmail: email, userName: name, userImage: image)
        do {
            try realm.write {
                realm.add(data, update: .modified) // 중복 데이터 업데이트
            }
            print("✅ AppState UserData 저장 성공")
            
            // UI 업데이트
            DispatchQueue.main.async {
                self.updateUserData(email: email, name: name, image: image)
            }
        } catch {
            print("❌ AppState UserData 저장 실패: \(error.localizedDescription)")
        }
    }
    
    // ✅ UI 상태 업데이트 함수
       private func updateUserData(email: String, name: String, image: String) {
           self.isLoggedIn = true
           self.userEmail = email
           self.userName = name
           self.userImage = image
           self.objectWillChange.send()
       }
    
    // Realm에서 사용자 로그아웃 및 탈퇴 (데이터 삭제)
    func deleteUser() {
        do {
            try realm.write {
                realm.deleteAll()
            }
            DispatchQueue.main.async {
                self.userEmail = nil
                self.userName = nil
                self.userImage = nil
                self.isLoggedIn = false
            }
            print("✅ UserData 삭제 성공")
        } catch {
            print("❌ UserData 삭제 실패: \(error.localizedDescription)")
        }
    }
    
}

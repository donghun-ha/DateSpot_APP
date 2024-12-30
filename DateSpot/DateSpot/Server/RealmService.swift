//
//  RealmService.swift
//  DateSpot
//
//  Created by 하동훈 on 30/12/2024.
//

import RealmSwift

class RealmService {
    static let shared = RealmService() // 싱글톤으로 관리
    private let realm: Realm
    
    private init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Realm 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    // 모든 사용자 데이터 가져오기
    func fetchAllUsers() -> [UserData] {
        let users = realm.objects(UserData.self)
        return Array(users)
    }
    
    // 특정 사용자 데이터 가져오기
    func fetchUser(byEmail email: String) -> UserData? {
        return realm.objects(UserData.self).filter("userEmail == %@", email).first
    }
    
    // 사용자 데이터 추가 또는 업데이트
    func saveUser(_ user: UserData) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(user, update: .modified)
            }
            print("User 저장 성공")
        } catch {
            print("사용자 저장 실패: \(error.localizedDescription)")
        }
    }
    
    // 사용자 데이터 삭제
    func deleteUser(byEmail email:String) {
        if let user = fetchUser(byEmail: email) {
            do {
                try realm.write {
                    realm.delete(user)
                }
            } catch {
                print("사용자 삭제 실패: \(error.localizedDescription)")
            }
        }
    }
    
} // RealmService

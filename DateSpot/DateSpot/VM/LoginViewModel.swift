//
//  LoginViewModel.swift
//  DateSpot
//
//  Created by 하동훈 on 24/12/2024.
//  Google + Apple 로그인 로직

import SwiftUI
import GoogleSignIn
import AuthenticationServices
import RealmSwift

// MainActor 비동기 처리
@MainActor
class LoginViewModel: NSObject, ObservableObject {
    
    // MARK: - Properties
    // Published : 변수의 변경 사항을 자동으로 알릴 수 있는 프로퍼티 래퍼
    @Published var alertMessage: String = "" // Alert 등에 표시할 메세지
    @Published var showAlert: Bool = false   // Alert 표시 여부
    
    // Login AppState
    @Published var isLoginSuccessful: Bool = false // 로그인 상태
    @Published var loggedInUserEmail: String? = nil    // 로그인한 사용자 이메일
    @Published var loggedInUserName : String? = nil    // 로그인한 사용자 이름
    @Published var loggedInUserImage: String? = nil // 로그인한 사용자 프로필 이미지
    
//    // MARK: -Realm
//    private let realm: Realm
//    
//    override init() {
//        do {
//            self.realm = try Realm()
//            print("Realm 초기화 성공")
//        } catch {
//            fatalError("Realm 초기화 실패: \(error.localizedDescription)")
//        }
//    }
//    
//    // Realm에서 사용자 데이터 로드
//    func loadUserDataIfAvailable() {
//        // ----------- Realm 데이터 로드 시 로그 추가 -----------
//        print("🔍 Realm 데이터 로드 시작")
//        let users = realm.objects(UserData.self)
//        guard let user = users.first else {
//            print("❌ 저장된 사용자 데이터 없음") // 데이터 없음 로그
//            return
//        }
//
//        DispatchQueue.main.async {
//            self.loggedInUserEmail = user.userEmail
//            self.loggedInUserName = user.userName
//            self.loggedInUserImage = user.userImage
//            self.isLoginSuccessful = true
//            print("✅ Realm 데이터 로드 성공: \(user)")
//        }
//    }
//
//    // Realm에 사용자 데이터 저장
//    func saveUserData(email: String, name: String, image: String) {
//        // ----------- saveUserData 호출 여부 로그 추가 -----------
//        print("🔍 saveUserData 호출됨: email=\(email), name=\(name), image=\(image)") // 호출 여부 확인
//        let data = UserData(userEmail: email, userName: name, userImage: image)
//        do {
//            try realm.write {
//                realm.add(data, update: .modified) // 중복 데이터 업데이트
//            }
//            print("✅ UserData 저장 성공: \(data)")
//        } catch {
//            print("❌ UserData 저장 실패: \(error.localizedDescription)")
//        }
//    }
//    
//    // Realm에서 사용자 로그아웃 및 탈퇴 (데이터 삭제)
//    func deleteUser() {
//        do {
//            try realm.write {
//                realm.deleteAll()
//            }
//            print("로그아웃 : 로컬 데이터 삭제 완료")
//            self.isLoginSuccessful = false
//        } catch {
//            print("Realm 로그아웃 실패: \(error.localizedDescription)")
//        }
//    }
//    
    // MARK: - Service
    private let loginService = LoginService()
    private let appState: AppState // AppState주입
    
    // 초기화 시 AppState를 주입
    init(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Google Login
    
    /// Google 로그인 요청
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({$0 as? UIWindowScene}).first(where: { $0.activationState == .foregroundActive}),
              let rootVC = windowScene.windows.first?.rootViewController else {
            showError("Google 로그인 : 활성화된 윈도우 없음")
            return
        }
              
        // Google 로그인 팝업
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.showError("Google 로그인 실패: \(error.localizedDescription)")
                return
            }
            
            // 사용자 정보
          guard let user = result?.user,
                let email = user.profile?.email,
                let name = user.profile?.name,
                let imageURL = user.profile?.imageURL(withDimension: 100)?.absoluteString
            else {
                self.showError("Google 사용자 정보 누락")
                return
            }
            
            // 사용자 정보 저장
            self.appState.saveUserData(
                email: email,
                name: name,
                image: imageURL
            )
            
            // ----------- saveUserData 호출 추가 및 로그 -----------
            self.appState.saveUserData(
                email: email,
                name: name,
                image: imageURL
            )
            self.appState.isLoggedIn = true
            
            print("✅ Google 로그인 데이터 저장 완료: \(email), \(name), \(imageURL)")
            
            // 서버로 전송
            Task {
                do {
                    let response = try await self.loginService.sendUserData(
                        email: email,
                        name: name,
                        userIdentifier: email, // 구글은 이메일 가리기가 없으므로 user_identifier에 이메일 사용
                        loginType: "google" // 로그인 타입으로 고유식별자 사용
                    )
                    self.showSuccess("Google 로그인 성공: \(response)")
                } catch {
                    self.showError("Google 로그인 서버 전송 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // MARK: - Apple Login
    
    /// Apple 로그인 요청
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        
        // ASAuthorizaionController 생성
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Alert
    func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    func showSuccess(_ message: String) {
        alertMessage = message
        showAlert = true
        isLoginSuccessful = true
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension LoginViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Apple 로그인 성공 시
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = credential.user
            let email = credential.email ?? "No email provided" // 이메일이 없으면 기본 문자열 사용
            let fullName = credential.fullName?.formatted() ?? "No full name provided" // 이름이 없으면 기본 문자열 사용
            
            // 사용자 정보 저장
            self.loggedInUserEmail = email
            self.loggedInUserName = fullName
            self.loggedInUserImage = "" // Apple 로그인에서는 이미지 제공하지 않음.
            
            // ----------- saveUserData 호출 추가 및 로그 -----------
            self.appState.saveUserData(
                email: email,
                name: fullName,
                image: ""
            )
            self.appState.isLoggedIn = true
            
            print("✅ Apple 로그인 데이터 저장 완료: \(email), \(fullName)")
            
            // 디버깅 정보 출력
            print("User Identifier: \(userIdentifier)")
            print("Email received: \(email)")
            print("Full name: \(fullName)")

            // 서버 전송
            Task {
                do {
                    let response = try await loginService.sendUserData(
                        email: email,
                        name: fullName,
                        userIdentifier: userIdentifier,
                        loginType: "apple" // 로그인 타입 설정 
                    )
                    showSuccess("Apple 로그인 성공: \(response)")
                } catch {
                    showError("Apple 로그인 서버 전송 실패: \(error.localizedDescription)")
                }
            }
        } else {
            // 크리덴셜이 제대로 받아지지 않았을 경우
            showError("Apple 로그인 실패: Credential 없음")
        }
    }
    
    // Apple 로그인 실패
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Apple 로그인 실패 시
        showError("Apple 로그인 실패: \(error.localizedDescription)")
    }
    
    
}// LoginViewModel

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension LoginViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive}),
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}


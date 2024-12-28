//
//  LoginViewModel.swift
//  DateSpot
//
//  Created by 하동훈 on 24/12/2024.
//  Google + Apple 로그인 로직

import SwiftUI
import GoogleSignIn
import AuthenticationServices

// MainActor 비동기 처리
@MainActor
class LoginViewModel: NSObject, ObservableObject {
    
    // MARK: - Properties
    // Published : 변수의 변경 사항을 자동으로 알릴 수 있는 프로퍼티 래퍼
    @Published var alertMessage: String = "" // Alert 등에 표시할 메세지
    @Published var showAlert: Bool = false   // Alert 표시 여부
    @Published var isLoginSuccessful: Bool = false
    // MARK: - Service
    private let loginService = LoginService()
    
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
                let name = user.profile?.name
            else {
                self.showError("Google 사용자 정보 누락")
                return
            }
            
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
}

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


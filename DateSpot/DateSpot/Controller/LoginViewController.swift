//
//  LoginViewController.swift
//  DateSpot
//
//  Created by 하동훈 on 21/12/2024.
//

import UIKit
import AuthenticationServices // Apple Login
import GoogleSignIn // Google Login

class LoginViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    // MARK: - Properties
    // Google 로그인 버튼
    let googleButton = UIButton()
    // Apple 로그인 버튼
    let authorizationAppleIDButton = ASAuthorizationAppleIDButton()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI() // UI 설정
    }
    
    // MARK: - UI Configuration
    /// 화면의 UI 요소들을 구성하는 메서드
    private func configureUI() {
        view.backgroundColor = .white // 배경 색상 설정
        setupGoogleLoginButton() // Google 버튼 추가
        setupAppleLoginButton()  // Apple 버튼 추가
    }
    
    // MARK: - Google
    /// Google 로그인 버튼 구성 및 레이아웃 설정
    private func setupGoogleLoginButton() {
        // 이미지 추가
        let googleLogo = UIImage(named: "google") // 로컬 이미지 사용
        googleButton.setImage(googleLogo, for: .normal)
        googleButton.imageView?.contentMode = .scaleAspectFit
        
        // Google 버튼 Auto Layout 활성화
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside) // Google 로그인 동작 추가
        view.addSubview(googleButton)
        
        // Google 버튼 제약 조건 설정
        NSLayoutConstraint.activate([
            googleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor), // 화면 중앙에 정렬
            googleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40), // 화면 중심보다 위로 40pt
            googleButton.widthAnchor.constraint(equalToConstant: 200), // 버튼 너비 200pt
            googleButton.heightAnchor.constraint(equalToConstant: 50)  // 버튼 높이 50pt
        ])
    }
    
    // MARK: - Apple
    /// Apple 로그인 버튼 구성 및 레이아웃 설정
    private func setupAppleLoginButton() {
        let appleLoginButton = ASAuthorizationAppleIDButton(type: .signIn, style: .whiteOutline)
        appleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        appleLoginButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButtonPress), for: .touchUpInside)

        // 버튼을 화면에 추가
        self.view.addSubview(appleLoginButton)

        // 오토레이아웃 설정
        NSLayoutConstraint.activate([
            appleLoginButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            appleLoginButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            appleLoginButton.heightAnchor.constraint(equalToConstant: 50),
            appleLoginButton.widthAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    // MARK: - Selectors
    /// Apple 로그인 버튼 동작 처리
    @objc func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email] // 사용자 이름과 이메일 요청
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self // 결과 처리 delegate 연결
        authorizationController.presentationContextProvider = self // 현재 화면 context 제공
        authorizationController.performRequests() // 애플 로그인 요청 시작
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    /// Apple 로그인 인증 성공 처리
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("User Identifier: \(userIdentifier)")
            print("Full Name: \(String(describing: fullName))")
            print("Email: \(email ?? "None")")
            
            // UserDefaults에 사용자 정보 저장
            let defaults = UserDefaults.standard
            
            // 이름 저장 (Optional 처리)
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                let completeName = "\(givenName) \(familyName)"
                defaults.set(completeName, forKey: "fullName")
                print("Saved Full Name: \(completeName)")
            } else {
                defaults.set("", forKey: "fullName") // 이름이 없을 경우 빈 문자열 저장
                print("Saved Full Name as empty string")
            }
            
            // 이메일 저장
            if let email = email {
                defaults.set(email, forKey: "email")
                print("Saved Email: \(email)")
            } else {
                defaults.set("", forKey: "email") // 이메일이 없을 경우 빈 문자열 저장
                print("Saved Email as empty string")
            }
            
        default:
            print("Apple Login did not return valid credentials.")
        }
    }
    
    /// Apple 로그인 인증 실패 처리
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Login Failed: \(error.localizedDescription)")
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    /// Apple 로그인 창을 표시할 윈도우 지정
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    // MARK: - Google
    /// Google 로그인 처리
    @objc private func handleGoogleSignIn() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                print("Google 로그인 실패: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let profile = user.profile,
                  let idToken = user.idToken?.tokenString else {
                print("Google 사용자 정보 또는 토큰 없음")
                return
            }

            // 사용자 정보 출력
            print("사용자 이름: \(profile.name)")
            print("사용자 이메일: \(profile.email)")
            print("ID 토큰: \(idToken)")

            // Redis에 사용자 정보 저장
            let redisKey = "user:\(user.userID ?? "")"
            let redisValue = "name=\(profile.name), email=\(profile.email), token=\(idToken)"
            RedisManager.shared.setValue(key: redisKey, value: redisValue) { success in
                if success {
                    print("사용자 정보를 Redis에 저장 성공")
                } else {
                    print("사용자 정보를 Redis에 저장 실패")
                }

                // Redis에서 저장된 데이터 조회
                RedisManager.shared.getValue(key: redisKey) { value in
                    if let value = value {
                        print("Redis에서 조회된 데이터: \(value)")
                    } else {
                        print("Redis에서 데이터를 찾을 수 없습니다.")
                    }
                }
            }
        }
    }
}

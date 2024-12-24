//
//  LoginViewController.swift
//  DateSpot
//
//  Created by 하동훈 on 2024/12/24.
//

import UIKit
import AuthenticationServices // Apple Login
import GoogleSignIn // Google Login

class LoginViewController: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    // MARK: - Properties
    private let googleSignInButton = UIButton() // Google 로그인 버튼
    private let appleSignInButton = ASAuthorizationAppleIDButton() // Apple 로그인 버튼
    private let loginService = LoginService() // 로그인 관련 Service 객체
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        let googlelogo = UIImage(named: "google")
        
        // Google Sign-In 버튼 설정i
        googleSignInButton.setImage(googlelogo, for: .normal)
        googleSignInButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        googleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(googleSignInButton)
        
        // Apple Sign-In 버튼 설정
        appleSignInButton.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
        appleSignInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appleSignInButton)
        
        // 버튼 레이아웃
        NSLayoutConstraint.activate([
            googleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleSignInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            googleSignInButton.widthAnchor.constraint(equalToConstant: 250),
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            
            appleSignInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleSignInButton.topAnchor.constraint(equalTo: googleSignInButton.bottomAnchor, constant: 20),
            appleSignInButton.widthAnchor.constraint(equalToConstant: 250),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Google Sign-In
    @objc private func handleGoogleSignIn() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(message: "Google 로그인 실패: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let email = user.profile?.email,
                  let name = user.profile?.name else {
                self.showAlert(message: "Google 사용자 정보 누락")
                return
            }

            // 서버로 사용자 데이터 전송
            Task {
                do {
                    let response = try await self.loginService.sendUserData(email: email, name: name)
                    self.showAlert(message: "로그인 성공: \(response)")
                } catch {
                    self.showAlert(message: "로그인 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In
    @objc private func handleAppleSignIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email, .fullName]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            showAlert(message: "Apple 로그인 실패")
            return
        }
        
        let email = appleIDCredential.email ?? "hidden@appleid.com"
        let name = appleIDCredential.fullName?.formatted() ?? "Unknown"
        
        Task {
            do {
                let response = try await loginService.sendUserData(email: email, name: name)
                showAlert(message: "로그인 성공: \(response)")
            } catch {
                showAlert(message: "로그인 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showAlert(message: "Apple 로그인 실패: \(error.localizedDescription)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    // MARK: - Helper
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

//
//  UserViewController.swift
//  DateSpot
//
//  Created by 하동훈 on 20/12/2024.
//

import UIKit
import AuthenticationServices

class UserViewController: UIViewController {
    // MARK: - Properties
    let authorizationAppleIDButton = ASAuthorizationAppleIDButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupAppleLoginButton()
    }
    // MARK: - Apple UI
    private func configureUI() {
//        setAdditionalPropertyAttributes()
//        setConstraints()
        setupAppleLoginButton()
    }
    
    func setupAppleLoginButton() {
        // ASAuthorizationAppleIDButton을 사용해 애플 로그인 버튼 생성
        let appleLoginButton = ASAuthorizationAppleIDButton(type: .signIn, style: .whiteOutline)
        appleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        appleLoginButton.addTarget(self, action: #selector(handleAuthorizationAppleIDButton(_:)), for: .touchUpInside)

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
    
    @IBAction func btnLogin(_ sender: Any) {
        print("Login Button")
        // 로그인 화면으로 이동
        let loginViewController = LoginViewController()
        self.navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    // MARK: - Selectors
    @objc private func handleAuthorizationAppleIDButton(_ sender: ASAuthorizationAppleIDButton) {
        print(#function)
    }
    
    
}// UserViewController


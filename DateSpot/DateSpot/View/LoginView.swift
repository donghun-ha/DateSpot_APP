//
//  LoginView.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI
import GoogleSignIn
import AuthenticationServices


// Login 화면
struct LoginView: View {
//    // VM (Google 로그인 로직)
//    // 새로운 상태 객체를 생성해야 할 때는 @StateObject, 이미 생성된 객체를 감시할 때는 @ObservedObject를 사용합니다.
    @StateObject var viewModel = LoginViewModel()
    

    // 본문
    var body: some View {
        VStack(spacing: 24, content: {
            // Google Login Button
            GoogleLoginButtonView(viewModel: viewModel)
            
            // Apple Login Button
            AppleLoginButtonView(viewModel: viewModel)
        })
    } // body
} // LoginContentView

#Preview {
    LoginView()
}

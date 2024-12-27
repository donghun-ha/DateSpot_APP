//
//  SocialLoginButton.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI

struct SocialLoginButton: View {
    let icon: Image
    let text: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8, content: {
                icon
                    .resizable()
                    .renderingMode(.original) // 원본 색상
                    .frame(width: 20, height: 20)
                    .padding(40)
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
            })
            .foregroundColor(.black)
            .frame(width: 300, height: 50)
            .background(backgroundColor)
            .cornerRadius(30)
        }
    }
}

// 구글 로그인 버튼
struct GoogleLoginButtonView : View {
    @ObservedObject var viewModel: LoginViewModel
    
    var body: some View {
        SocialLoginButton(
            icon: Image("googleLogo"),
            text: "구글로 로그인",
            backgroundColor: .white
        ) {
            viewModel.signInWithGoogle()
        }
    }
}

// 애플 로그인 버튼
struct AppleLoginButtonView : View {
    @ObservedObject var viewModel: LoginViewModel
    
    var body: some View {
        SocialLoginButton(
            icon: Image(systemName: "applelogo"),
            text: "애플로 로그인",
            backgroundColor: .white
        ) {
            viewModel.signInWithApple()
        }
    }
}

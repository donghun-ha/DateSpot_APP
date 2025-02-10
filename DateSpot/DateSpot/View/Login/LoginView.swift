//
//  LoginView.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI
import GoogleSignIn
import AuthenticationServices
import RealmSwift

// Login 화면
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: LoginViewModel
    // 이미지 배열
    let images = ["tripImage1", "tripImage2", "tripImage3", "tripImage4"]
    @State private var currentImageIndex = 0
    @State private var navigateToTabBar = false // TabBarView로 이동 여부

    // 초기화 메서드 추가
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(appState: appState))
    }

    var body: some View {
        ZStack {
            if navigateToTabBar {
                // TabBarView로 이동
                TabBarView()
            } else {
                // 로그인 화면
                Image(images[currentImageIndex])
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .animation(.easeInOut, value: currentImageIndex)
                
                VStack {
                    Text("""
                         오늘, 어디로 떠나볼까요?
                         함께할 장소를 찾아보세요.
                         """)
                        .bold()
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .padding(.top, 120)

                    Spacer()

                    VStack(spacing: 15) {
                        GoogleLoginButtonView(viewModel: viewModel)
                        AppleLoginButtonView(viewModel: viewModel)
                    }
                    .padding(.bottom, 50)
                    .padding(.horizontal, 20)
                }
                .onChange(of: viewModel.isLoginSuccessful) { _, isSuccess in
                    if isSuccess {
                        appState.isLoggedIn = true
                        appState.userEmail = viewModel.loggedInUserEmail
                        appState.userName = viewModel.loggedInUserName ?? ""
                        appState.userImage = viewModel.loggedInUserImage ?? ""
                        navigateToTabBar = true // TabBarView로 이동
                        print("navigateToTabBar: \(navigateToTabBar)")
                    }
                }
            }
        }
        .onAppear {
            startImageRotation()
        }
    }

    // 이미지를 주기적으로 변경하는 함수
    private func startImageRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation {
                currentImageIndex = (currentImageIndex + 1) % images.count
            }
        }
    }
}

// #Preview {
//     LoginView(appState: AppState()).environmentObject(AppState())
// }

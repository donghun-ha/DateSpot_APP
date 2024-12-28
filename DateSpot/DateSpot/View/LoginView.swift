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
    // VM (Google 로그인 로직)
    // 새로운 상태 객체를 생성해야 할 때는 @StateObject, 이미 생성된 객체를 감시할 때는 @ObservedObject를 사용합니다.
    @StateObject var viewModel = LoginViewModel()
    @EnvironmentObject var appState: AppState
    
    // 이미지 배열
    let images = ["tripImage1", "tripImage2", "tripImage3", "tripImage4"]
    // 이미지 상태
    @State private var currentImageIndex = 0

    // 본문
    var body: some View {
        ZStack {
            // 배경 이미지
            Image(images[currentImageIndex])
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .animation(.easeInOut, value: currentImageIndex) // 애니메이션 효과 추가
            
               VStack() {
                   // 문구
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
                       // Google Login Button
                       GoogleLoginButtonView(viewModel: viewModel)
                       // Apple Login Button
                       AppleLoginButtonView(viewModel: viewModel)
                   }
                   .padding(.bottom, 50)
                   .padding(.horizontal, 20) // 버튼 좌우 간격 조정
               }
           }
        .onAppear {
            startImageRotation()
        }
        .onChange(of: viewModel.isLoginSuccessful) { isSuccess in
            if isSuccess {
                appState.isLoggedIn = true // 로그인 성공 시 상태 업데이트
            }
        }
    } // body
    
    // 이미지를 주기적으로 변경하는 함수
    private func startImageRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) {_ in
            withAnimation{
                currentImageIndex = (currentImageIndex + 1) % images.count
            }
        }
    } // startImageRotation
    
} // LoginContentView


#Preview {
    LoginView().environmentObject(AppState())
}

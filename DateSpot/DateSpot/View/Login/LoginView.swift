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
    let realm = try! Realm() 
    @StateObject var viewModel = LoginViewModel()
    @EnvironmentObject var appState: AppState
    
    // 이미지 배열
    let images = ["tripImage1", "tripImage2", "tripImage3", "tripImage4"]
    @State private var currentImageIndex = 0
    @State private var navigateToTabBar = false // TabBarView로 이동 여부

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
            }
        }
        .onAppear {
            startImageRotation()
            loadUserDataIfAvailable() // Realm에서 데이터 로드
        }
        .onChange(of: viewModel.isLoginSuccessful) { isSuccess in
            if isSuccess {
                appState.isLoggedIn = true
                appState.userEmail = viewModel.loggedInUserEmail
                appState.userName = viewModel.loggedInUserName
                appState.userImage = viewModel.loggedInUserImage
                Task {
                    await saveUserData()
                    navigateToTabBar = true
                }
            }
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

    // Realm에 저장된 데이터 확인 및 AppState 업데이트
       private func loadUserDataIfAvailable() {
           let users = realm.objects(UserData.self)
           guard let user = users.first else { return } // 저장된 사용자 데이터가 없는 경우 종료

           DispatchQueue.main.async {
               appState.isLoggedIn = true
               appState.userEmail = user.userEmail
               appState.userName = user.userName
               appState.userImage = user.userImage
               navigateToTabBar = true // TabBarView로 이동
           }
       }

       // Realm에 사용자 데이터 저장
       func saveUserData() async {
           let data = UserData(userEmail: viewModel.loggedInUserEmail, userName: viewModel.loggedInUserName, userImage: viewModel.loggedInUserImage)
           DispatchQueue.main.async {
               do {
                   try realm.write {
                       realm.add(data, update: .modified) // 중복 데이터 업데이트
                   }
                   print("✅ UserData 저장 성공")
               } catch {
                   print("❌ UserData 저장 실패: \(error.localizedDescription)")
               }
           }
       }
   }


   #Preview {
       LoginView().environmentObject(AppState())
   }


//
//  UserSettings.swift
//  DateSpot
//
//  Created by 하동훈 on 2/1/2025.
//  Description : 유저 페이지에서 톱니바퀴 아이콘 클릭시 이동되는 페이지.

import SwiftUI

struct UserSettings: View {
    // Properties
    @EnvironmentObject var appState: AppState // 앱 상태 관리
    @State private var isLogoutAlertPresented: Bool = false
    @State private var isDeleteAccountAlertPresented: Bool = false
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationView(content: {
            VStack(content: {
                List(content: {
                    // 계졍 관리 섹션
                    Section(header: Text("계정 관리"), content: {
                        Button("로그아웃") {
                            isLogoutAlertPresented = true
                        }
                        .alert("로그아웃", isPresented: $isLogoutAlertPresented) {
                            Button("취소", role: .cancel) {}
                            Button("확인", role: .destructive){
                                // Logout logic
                                Task {
                                    // 비동기 호출로 로그아웃 로직 실행
                                    await viewModel.logoutUser(email: appState.userEmail ?? "")
                                    appState.isLoggedIn = false // 로그인 상태를 false로 설정
                                    print("Logged out")
                                }
                            }
                        } message: {
                            Text("로그아웃 하시겠습니까?")
                        }
                        Button("계정 삭제") {
                            isDeleteAccountAlertPresented = true
                        }
                        .alert("계정삭제", isPresented: $isDeleteAccountAlertPresented) {
                            Button("취소", role: .cancel) {}
                            Button("확인", role: .destructive) {
                                // 계정 삭제 로직 추가
                                Task{
                                    await viewModel.deleteUser(email: appState.userEmail ?? "")
                                    appState.isLoggedIn = false // 로그인 상태를 false로 설정
                                    print("Account deleted")
                                }
                            }
                        } message: {
                            Text("계정을 삭제하면 복구할 수 없습니다. 계속하시겠습니까?")
                        }
                    })
                    // Theme 설정 섹션
                    Section(header: Text("테마 설정"), content: {
                        Toggle("다크 모드 활성화", isOn: $appState.isDarkMode)
                    })
                })
                .listStyle(InsetGroupedListStyle()) // 깔끔한 iOS 스타일의 리스트 적용
                
                // 앱 버전 표시
                Text("Version 1.0.0")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .padding()
            })
            .navigationTitle("설정")
        })
    }
}

//#Preview {
//    UserSettings()
//}

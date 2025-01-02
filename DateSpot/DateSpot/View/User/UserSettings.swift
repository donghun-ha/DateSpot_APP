//
//  UserSettings.swift
//  DateSpot
//
//  Created by 하동훈 on 2/1/2025.
//  Description : 유저 페이지에서 톱니바퀴 아이콘 클릭시 이동되는 페이지.

import SwiftUI

struct UserSettings: View {
    // Properties
    @Environment(\.colorScheme) var colorScheme // 현재 앱의 Dark/Light Model 확인
    @EnvironmentObject var appState: AppState
    @State private var isLogoutAlertPresented: Bool = false
    @State private var isDeleteAccountAlertPresented: Bool = false
    @State private var viewModel = UserViewModel()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false // Dark Mode 상태 저장
    
    var body: some View {
        NavigationView(content: {
            VStack(content: {
                List(content: {
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
                                    print("Account deleted")
                                }
                            }
                        } message: {
                            Text("계정을 삭제하면 복구할 수 없습니다. 계속하시겠습니까?")
                        }
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

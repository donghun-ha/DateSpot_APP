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
    @State private var showLoginView = false // 로그인 화면 시트
    @State private var showLoginSuccessAlert = false // 로그인 성공 여부
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationView(content: {
            VStack(content: {
                List(content: {
                    // 계정 관리 섹션
                    Section(header: Text("계정 관리"), content: {
                        // 로그인 버튼
                        if !appState.isLoggedIn {
                            Button("로그인") {
                                showLoginView = true
                            }
                        }
                
                        
                        // 로그아웃 버튼
                        Button("로그아웃") {
                            isLogoutAlertPresented = true
                        }
                        .disabled(!appState.isLoggedIn) // 로그인 상태가 아니라면 비활성화
                        .foregroundStyle(appState.isLoggedIn ? .red : .gray)
                        .alert("로그아웃", isPresented: $isLogoutAlertPresented) {
                            Button("취소", role: .cancel) {}
                            Button("확인", role: .destructive) {
                                // Logout logic
                                Task {
                                    await viewModel.logoutUser(email: appState.userEmail ?? "")
                                    appState.deleteUser()
                                    appState.isLoggedIn = false // 로그인 상태를 false로 설정
                                    print("Logged out")
                                }
                            }
                        } message: {
                            Text("로그아웃 하시겠습니까?")
                        }
                        .foregroundStyle(.red)
                        
                        // 개인정보처리방침 버튼
                        Button("개인정보처리방침") {
                            if let url = URL(string: "https://alabaster-chocolate-fe8.notion.site/17ab5e9490658007806eff51192312f7?pvs=73") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(.blue) // 버튼 텍스트 색상
                        
                        // 계정 탈퇴 버튼
                        Button("계정 탈퇴") {
                            isDeleteAccountAlertPresented = true
                        }
                        .disabled(!appState.isLoggedIn)
                        .foregroundStyle(appState.isLoggedIn ? .red : .gray)
                        .alert("계정 탈퇴", isPresented: $isDeleteAccountAlertPresented, actions: {
                            Button("취소", role: .cancel) {}
                            Button("확인", role: .destructive) {
                                // 계정 탈퇴 로직
                                Task {
                                    await viewModel.deleteUser(email: appState.userEmail ?? "")
                                    appState.deleteUser()
                                    appState.isLoggedIn = false // 계정 탈퇴
                                    print("계정 탈퇴 성공")
                                }
                            }
                        }, message: {
                            Text("""
                            계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.
                            진행하시겠습니까?
                            """)
                        })
                        .foregroundStyle(.red)
                    })
                    
                    // Theme 설정 섹션
                    Section(header: Text("테마 설정"), content: {
                        Toggle("다크 모드 활성화", isOn: $appState.isDarkMode)
                    })
                })
                .listStyle(InsetGroupedListStyle()) // 깔끔한 iOS 스타일의 리스트 적용
                .onAppear {
                    print("UserSettings : isLoggedIn = \(appState.isLoggedIn), email = \(appState.userEmail ?? "nil")")
                          }
                .onChange(of: appState.isLoggedIn) { _, newValue in
                    if newValue {
                        print("로그인 상태 변경됨: \(newValue)")
                        showLoginSuccessAlert = true
                        showLoginView = false
                    }
                }
                .sheet(isPresented: $showLoginView) {
                    LoginView(appState: appState)
                }
                .alert("로그인 성공", isPresented: $showLoginSuccessAlert) {
                    Button("확인", role: .cancel) {}
                }
                
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

#Preview {
    UserSettings()
}

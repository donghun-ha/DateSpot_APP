//
//  UserView.swift
//  DateSpot
//
// Author : 하동훈
// Description : AppState에서 호출한 Email, UserName 표시 및 S3에서 받아온 Image URL을 MySQL 연동 처리하여 보여주는 View

import SwiftUI

struct ParentView: View {
    var body: some View {
        NavigationStack {
            UserView()
        }
    }
}

struct UserView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = UserViewModel()
    @State private var showImagePicker = false
    @State private var showLoginSheet = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            // 상단 프로필 섹션
            HStack {    
                // 프로필 이미지
                if let imageURL = URL(string: viewModel.userImage), !viewModel.userImage.isEmpty {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                .onTapGesture {
                                    handleProfileImageTap()
                                }
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        default:
                            ProgressView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            handleProfileImageTap()
                        }
                }
                
                // 유저 정보
                VStack(alignment: .leading) {
                    Text(appState.userName ?? "로그인이 필요합니다!")
                        .font(.headline)
                    Text(appState.userEmail ?? "이메일 정보 없음")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 8)
                
                
                Spacer()
                
                // 설정 아이콘
                    NavigationLink(destination: UserSettings(), label: {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    })
            }
            
            .padding()
    
            
            Divider()


            // 공지사항 섹션
            VStack(alignment: .leading, spacing: 10) { // 왼쪽 정렬로 변경
                Text("공지사항")
                    .font(.headline)
                    .padding(.leading)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                        Text("새로운 업데이트를 확인하세요!")
                            .font(.subheadline)
                    }

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.green)
                        Text("앱 사용 팁: 프로필 이미지를 눌러 변경해보세요.")
                            .font(.subheadline)
                    }
                }
                .padding(.leading)
            }
            
            Spacer()
        }
        .onAppear {
            Task {
                if appState.userEmail != nil {
                    await viewModel.fetchUserImage(email: appState.userEmail!)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    guard appState.userEmail != nil else {
                        showLoginSheet = true
                        return
                    }
                    
                    if let selectedImage = selectedImage {
                        Task {
                            await viewModel.uploadImage(email: appState.userEmail!, image: selectedImage)
                        }
                    }
                }
        }
        .alert("로그인이 필요합니다!", isPresented: $showLoginSheet) {
            Button("확인", role: .cancel) {}
        }
    }
    
    // 로그인이 Alert 표시 함수
    private func handleProfileImageTap() {
        if let _ = appState.userEmail {
            // 로그인 상태 -> 이미지 선택 화면 표시
            showImagePicker = true
        } else {
            // 로그인이 안 된 상태 -> 경고(Alert) 표시
            showLoginSheet = true
        }
    }
}

//#Preview {
//    UserView()
//}

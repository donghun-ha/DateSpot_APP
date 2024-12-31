//
//  UserView.swift
//  DateSpot
//
// Author : 하동훈
// Description : AppState에서 호출한 Email, UserName 표시 및 S3에서 받아온 Image URL을 MySQL 연동 처리하여 보여주는 View

import SwiftUI

struct UserView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = UserViewModel()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack {
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
                                    showImagePicker = true
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
                            showImagePicker = true
                        }
                }

                VStack(alignment: .leading) {
                    // 유저 이름과 이메일
                    Text(appState.userName)
                        .font(.headline)
                    Text(appState.userEmail ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 8)

                Spacer()

                // 설정 아이콘
                Button(action: {
                    // 설정 동작
                }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                }
            }
            .padding()

            Divider()

            VStack(spacing: 16) {
                // 데이터 로그 / 큐레이션 탭
                HStack {
                    Spacer()
                    Text("데이로그")
                        .font(.headline)
                    Spacer()
                    Text("큐레이션")
                        .font(.headline)
                    Spacer()
                }
                .padding(.vertical)

                Divider()

                Spacer()

                Text("내가 방문한 공간을 기록해보세요")
                    .foregroundColor(.gray)
                    .padding()

                // 버튼
                Button(action: {
                    // 첫 데이로그 남기기 동작
                }) {
                    Text("첫 데이로그 남기기")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.top)

            Spacer()

            // 탭 바 공간 확보
            Spacer(minLength: 50)
        }
        .onAppear {
            Task {
                await viewModel.fetchUserImage(email: appState.userEmail!)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if let selectedImage = selectedImage {
                        Task {
                            await viewModel.uploadImage(email: appState.userEmail!, image: selectedImage)
                        }
                    }
                }
        }
    }
}

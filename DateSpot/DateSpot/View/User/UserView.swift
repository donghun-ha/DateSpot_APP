//
//  UserView.swift
//  DateSpot
//

import SwiftUI

struct UserView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = UserViewModel() // UserViewModel 연결
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            if let email = appState.userEmail, !email.isEmpty {
                VStack(spacing: 16) {
                    Text("사용자 정보")
                        .font(.title)
                        .padding()

                    // AsyncImage를 사용하여 S3에서 불러온 프로필 이미지 표시
                    if let imageURL = URL(string: appState.userImage), !appState.userImage.isEmpty {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            default:
                                ProgressView()
                            }
                        }
                        .padding()
                    } else {
                        // 기본 이미지 표시
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .padding()
                    }

                    Button("Change Image") {
                        isImagePickerPresented = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // 이메일 표시 (수정 불가)
                    TextField("Email", text: .constant(email))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                        .padding()

                    // 이름 입력 필드
                    TextField("Name", text: $appState.userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("Save Changes", action: {
                        Task {
                            guard let selectedImage = selectedImage else { return }
                            await viewModel.uploadProfileImage(
                                email: email,
                                image: selectedImage
                            )
                        }
                    })
                    .padding()
                    .background(viewModel.isUploading ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(viewModel.isUploading) // 업로드 중에는 버튼 비활성화
                }
                .padding()
            } else {
                Text("로그인된 사용자 정보가 없습니다.")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            Task {
                // Realm에서 사용자 데이터 로드
                await viewModel.loadUserDataFromBackend(email: appState.userEmail ?? "")
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

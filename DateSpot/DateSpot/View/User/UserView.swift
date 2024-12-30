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
                        .onAppear {
                            print("✅ S3 이미지 로드 성공: \(appState.userImage)")
                        }
                    } else {
                        // 기본 이미지 표시
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .padding()
                            .onAppear {
                                print("❌ 기본 이미지 표시: 이미지 URL이 비어있음")
                            }
                    }

                    Button("Change Image") {
                        print("ℹ️ Change Image 버튼 클릭됨")
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

                    Button("Save Changes") {
                        print("ℹ️ Save Changes 버튼 클릭됨")
                        guard let selectedImage = selectedImage else {
                            print("❌ Save Changes 실패: 선택된 이미지가 없음")
                            return
                        }
                        Task {
                            print("ℹ️ Save Changes 작업 시작: 이메일 - \(email)")
                            await viewModel.uploadProfileImage(
                                email: email,
                                image: selectedImage
                            )
                        }
                    }
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
                .onAppear {
                    print("❌ 로그인된 사용자 정보가 없음")
                }
            }
        }
        .onAppear {
            Task {
                print("ℹ️ UserView가 나타남. 데이터 로드 시작")
                await viewModel.loadUserDataFromBackend(email: appState.userEmail ?? "")
                print("✅ 데이터 로드 완료")
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

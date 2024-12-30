//
//  UserView.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//
// 이 뷰는 사용자의 프로필 정보를 표시하며, 프로필 이미지를 눌러 사진 앨범에서 이미지를 선택할 수 있는 기능을 제공합니다.
//

import SwiftUI

struct UserView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = UserViewModel()
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            // 사용자 정보 섹션
            if let currentUser = appState.userEmail {
                VStack(spacing: 16) {
                    Text("사용자 정보")
                        .font(.title)
                        .padding()

                    HStack {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }

                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            Text("Change Image")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()

                    TextField("Email", text: .constant(currentUser))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                        .padding()

                    TextField("Name", text: $appState.userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: {
                        guard let selectedImage = selectedImage else { return }
                        viewModel.uploadProfileImage(
                            email: currentUser,
                            name: appState.userName,
                            image: selectedImage
                        )
                    }) {
                        Text("Save Changes")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else {
                Text("로그인된 사용자 정보가 없습니다.")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            // 초기 데이터 로드
            appState.userName = appState.userName
            appState.userImage = appState.userImage
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}


#Preview {
    UserView().environmentObject(AppState())
}

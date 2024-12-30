//
//  UserView.swift
//  DateSpot
//

import SwiftUI

struct UserView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            // 사용자 이미지 표시
            if let imageURL = URL(string: viewModel.userImage), !viewModel.userImage.isEmpty {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .onTapGesture {
                                showImagePicker = true
                            }
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
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchUserImage(email: "harukax1999@gmail.com")
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if let selectedImage = selectedImage {
                        Task {
                            await viewModel.uploadImage(email: "harukax1999@gmail.com", image: selectedImage)
                        }
                    }
                }
        }
    }
}

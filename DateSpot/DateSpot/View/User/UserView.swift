//
//  UserView.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//
// 이 뷰는 사용자의 프로필 정보를 표시하며, 프로필 이미지를 눌러 사진 앨범에서 이미지를 선택할 수 있는 기능을 제공합니다.
//

import SwiftUI
import PhotosUI

struct UserView: View {
    @EnvironmentObject var appState: AppState // 전역 상태 사용
    @State private var profileImage: UIImage? = nil // 사용자가 선택한 프로필 이미지
    @State private var isPhotoPickerPresented: Bool = false // 사진 선택 화면 표시 여부

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    // 프로필 이미지
//                    Button(action: {
//                        isPhotoPickerPresented = true // 사진 선택 화면 열기
//                    }) {
//                        if let profileImage = appState.userImage {
//                            // 사용자가 선택한 이미지 표시
//                            Image(uiImage: profileImage)
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 100, height: 100)
//                                .clipShape(Circle())
//                        } else {
//                            // 기본 프로필 이미지
//                            Image(systemName: "person.crop.circle.fill")
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 100, height: 100)
//                                .foregroundColor(.gray)
//                                .clipShape(Circle())
//                        }
//                    }
//                    .buttonStyle(PlainButtonStyle()) // 버튼 스타일 기본값 제거
//                    .sheet(isPresented: $isPhotoPickerPresented) {
//                        PhotoPicker(selectedImage: $profileImage)
//                    }

                    VStack(alignment: .leading, spacing: 5) {
                        // 이메일
                        Text(appState.userEmail!)
                            .font(.headline)
                            .foregroundColor(.gray)

                        // 이름
                        Text(appState.userName)
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Spacer() // 오른쪽 정렬용
                }
                .padding(.top, 30)

                Spacer()
            }
            .padding()
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 설정 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 설정 화면으로 이동
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}

// MARK: - PhotoPicker: 사진 선택기
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // 이미지만 선택 가능
        configuration.selectionLimit = 1 // 한 번에 하나의 이미지 선택

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

// 미리보기 제공
#Preview{
    UserView().environmentObject(AppState())
}

import SwiftUI

//struct CardView: View {
//    var imageUrl: String? // 이미지 URL 전달
//    var category: String
//    var heading: String
//    var author: String
//
//    @State private var loadedImage: UIImage? = nil // 로드된 이미지 저장
//    @State private var isLoading = true // 로딩 상태
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            // 이미지 섹션
//            if let image = loadedImage {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(height: 150)
//                    .clipped()
//            } else if isLoading {
//                // 로딩 중인 경우
//                Rectangle()
//                    .fill(Color.gray.opacity(0.3))
//                    .frame(height: 150)
//                    .overlay(
//                        ProgressView()
//                            .progressViewStyle(CircularProgressViewStyle())
//                    )
//            } else {
//                // 로드 실패한 경우
//                Rectangle()
//                    .fill(Color.gray.opacity(0.3))
//                    .frame(height: 150)
//                    .overlay(
//                        Text("No Image")
//                            .foregroundColor(.white)
//                            .font(.caption)
//                    )
//            }
//
//            // 텍스트 섹션
//            VStack(alignment: .leading) {
//                Text(category)
//                    .font(.caption)
//                    .fontWeight(.bold)
//                    .foregroundColor(.secondary)
//                Text(heading)
//                    .font(.title3)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//                Text(author)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            .padding([.horizontal, .bottom])
//        }
//        .background(Color(.systemBackground))
//        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
//        .onAppear {
//            loadImage()
//        }
//    }
//
//    /// 비동기 이미지 로드
//    private func loadImage() {
//        guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else {
//            isLoading = false
//            return
//        }
//
//        Task {
//            do {
//                let (data, _) = try await URLSession.shared.data(from: url)
//                if let image = UIImage(data: data) {
//                    DispatchQueue.main.async {
//                        self.loadedImage = image
//                        self.isLoading = false
//                    }
//                } else {
//                    print("Failed to convert data to UIImage")
//                    self.isLoading = false
//                }
//            } catch {
//                print("Failed to load image: \(error.localizedDescription)")
//                self.isLoading = false
//            }
//        }
//    }
//}
//
struct CardView: View {
    var image: UIImage?
    var category: String
    var heading: String
    var author: String

    var body: some View {
        VStack(alignment: .leading) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(
                        Text("No Image Available")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }

            VStack(alignment: .leading) {
                Text(category)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text(heading)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(author)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

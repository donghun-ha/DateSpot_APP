import SwiftUI

struct CardView: View {
    var image: UIImage? // 이미지를 UIImage로 받음
    var category: String
    var heading: String
    var author: String

    var body: some View {
        VStack(alignment: .leading) {
            // 이미지가 있을 경우 표시
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
            } else {
                // 기본 플레이스홀더 이미지
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .overlay(
                        Text("No Image")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }

            // 텍스트 정보
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


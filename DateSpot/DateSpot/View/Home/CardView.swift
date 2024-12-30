import SwiftUI

struct CardView: View {
    var image: UIImage?
    var category: String
    var heading: String
    var author: String

    var body: some View {
        VStack(alignment: .leading) {
            // 이미지 로드
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

import SwiftUI

struct CardView: View {
    let image: UIImage?
    let category: String
    let heading: String
    let author: String

    var body: some View {
        VStack(alignment: .leading) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 200)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 300, height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    )
            }

            Text(heading)
                .font(.headline)
                .fontWeight(.bold)
                .padding([.top, .horizontal])

            Text(category)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Text(author)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}


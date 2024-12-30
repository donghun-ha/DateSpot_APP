import SwiftUI

struct ImageSliderView: View {
    var images: [UIImage]
    @Binding var selection: Int
    @StateObject private var viewModel = RestaurantViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            InfinitePageView(
                selection: $selection,
                before: { $0 == 0 ? images.count - 1 : $0 - 1 },
                after: { $0 == images.count - 1 ? 0 : $0 + 1 }
            ) { index in
                GeometryReader { geometry in
                    Image(uiImage: images[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 260)
                        .clipped()
                }
                .frame(height: 260)
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
            Button(action: {
               viewModel.addBookmark(
                   userEmail: "test@example.com",
                   restaurantName: "Delicious Restaurant",
                   name: "My Favorite Spot"
               )
           }) {
               Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                   .foregroundColor(.white)
                   .font(.system(size: 30))
           }
            .padding([.trailing, .top], 16) // 아이콘 위치
            .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(6)
            Text("\(selection + 1)/\(images.count)")
                .font(.caption)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding([.trailing, .bottom], 16)
        }
    }
}

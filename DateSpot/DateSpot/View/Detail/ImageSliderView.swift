import SwiftUI

struct ImageSliderView: View {
    var currentItem: String // 외부에서 값을 파라미터로 입력받아 처리하는 파라미터(명소 이름, 레스토랑 이름 받는 역할)
    var currentType: String // 아이템 타입 ("restaurant" 또는 "place")
    var images: [UIImage]
    @Binding var selection: Int
    @StateObject private var RestaurantviewModel = RestaurantViewModel() // 맛집 뷰모델 참조
    @StateObject private var PlaceviewModel = PlaceViewModel() // 명소 뷰모델 참조
    @EnvironmentObject var appState: AppState // 전역 상태 사용

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
                // 맛집 북마크
                if currentType == "restaurant" {
                    if RestaurantviewModel.isBookmarked {
                        RestaurantviewModel.deleteBookmark(
                            userEmail: appState.userEmail ?? "",
                            restaurantName: currentItem,
                            name: "My Favorite Spot"
                        )
                    } else {
                        RestaurantviewModel.addBookmark(
                            userEmail: appState.userEmail ?? "",
                            restaurantName: currentItem,
                            name: "My Favorite Spot"
                        )
                    }
                }
                // 명소 북마크
                else if currentType == "place" {
                    if PlaceviewModel.isBookmarked {
                        PlaceviewModel.deleteBookmark(
                            userEmail: appState.userEmail ?? "",
                            placeName: currentItem,
                            name: "My Favorite Spot"
                        )
                    } else {
                        PlaceviewModel.addBookmark(
                            userEmail: appState.userEmail ?? "",
                            placeName: currentItem,
                            name: "My Favorite Spot"
                        )
                    }
                }
                
            }) {
                // 현재 타입에 따라 북마크 상태 아이콘 표시
                Image(systemName: (currentType == "restaurant" && RestaurantviewModel.isBookmarked) ||
                                  (currentType == "place" && PlaceviewModel.isBookmarked)
                      ? "bookmark.fill"
                      : "bookmark")
                .foregroundStyle(.white)
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
        .onAppear {
            // 북마크 상태 확인
            RestaurantviewModel.checkBookmark(
                userEmail: appState.userEmail ?? "",
                restaurantName: currentItem
            )
            PlaceviewModel.checkBookmark(
                userEmail: appState.userEmail ?? "",
                placeName: currentItem
            )
        }
    }
}

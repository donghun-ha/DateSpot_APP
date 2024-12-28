import SwiftUI

struct DetailView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var selection: Int = 0
    @State private var isLoading = true
    var restaurantName: String = "[백년가게]만석장"

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...").font(.headline)
            } else if let restaurant = restaurantViewModel.selectedRestaurant {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !restaurantViewModel.images.isEmpty {
                                // 이미지 슬라이더
                                ZStack(alignment: .bottomTrailing) {
                                    InfinitePageView(
                                        selection: $selection,
                                        before: { $0 == 0 ? restaurantViewModel.images.count - 1 : $0 - 1 },
                                        after: { $0 == restaurantViewModel.images.count - 1 ? 0 : $0 + 1 }
                                    ) { index in
                                        GeometryReader { geometry in
                                            Image(uiImage: restaurantViewModel.images[index])
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

                                    Text("\(selection + 1)/\(restaurantViewModel.images.count)")
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .padding([.trailing, .bottom], 16)
                                }
                            } else {
                                Text("No images available")
                                    .foregroundColor(.gray)
                                    .frame(height: 260)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .padding()
                            }

                            // 레스토랑 상세 정보
                            VStack(alignment: .leading) {
                                Text(restaurant.name)
                                    .font(.title)
                                    .fontWeight(.bold)

                                Text(restaurant.address)
                                    .font(.subheadline)
                                Text("운영 시간: \(restaurant.operatingHour)")
                                    .font(.subheadline)
                                Text("휴무일: \(restaurant.closedDays)")
                                    .font(.subheadline)
                                Text("주차: \(restaurant.parking)")
                                    .font(.subheadline)
                                Text("연락처: \(restaurant.contactInfo)")
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                    }
                    .navigationBarHidden(true)
                    .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                Text("Restaurant not found.")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            Task {
                print("DetailView appeared. Loading data for: \(restaurantName)")
                isLoading = true
                await restaurantViewModel.fetchRestaurantDetail(name: restaurantName)
                print("Restaurant detail fetched: \(String(describing: restaurantViewModel.selectedRestaurant))")
                await restaurantViewModel.loadImages(for: restaurantName)
                isLoading = false
                print("Images loaded: \(restaurantViewModel.images.count)")
            }
        }
    }
}

#Preview {
    DetailView()
}

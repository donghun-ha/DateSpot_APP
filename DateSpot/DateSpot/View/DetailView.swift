import SwiftUI

struct DetailView: View {
    var images = ["2025 서울 카페&베이커리페어_1_공공1유형", "2025 서울 카페&베이커리페어_2_공공1유형", "2025 서울 카페&베이커리페어_3_공공1유형", "2025 서울 카페&베이커리페어_4_공공1유형"]
    @State private var selection: Int = 0 // 현재 페이지 인덱스 추적
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var rates: Int = 0 // StarRatingView와 바인딩할 별점 값
    @State private var isLoading = true // 로딩 상태를 관리하는 변수
    var restaurantName: String = "3대삼계장인" // 테스트용 레스토랑 이름

    var body: some View {
        Group {
            if isLoading {
                // 로딩 중 표시
                ProgressView("Loading...")
                    .font(.headline)
            } else {
                if let restaurant = restaurantViewModel.selectedRestaurant {
                    NavigationView {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // 이미지 슬라이더
                                ZStack(alignment: .bottomTrailing) {
                                    InfinitePageView(
                                        selection: $selection,
                                        before: { $0 == 0 ? images.count - 1 : $0 - 1 },
                                        after: { $0 == images.count - 1 ? 0 : $0 + 1 }
                                    ) { index in
                                        GeometryReader { geometry in
                                            Image(images[index])
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
                                    // 인디케이터
                                    Text("\(selection + 1)/\(images.count)")
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .padding([.trailing, .bottom], 16)
                                }

                                // 레스토랑 상세 정보
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(restaurant.name)
                                            .font(.title)
                                            .fontWeight(.bold)
                                        Spacer()
                                        Button(action: {
                                            // Navigate 버튼 동작 추가 가능
                                        }) {
                                            HStack {
                                                Image(systemName: "paperplane.fill")
                                                    .foregroundColor(.white)
                                                Text("Navigate")
                                                    .foregroundColor(.white)
                                            }
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                        }
                                    }
                                    VStack(alignment: .leading) {
                                        Text("별점")
                                            .font(.headline)
                                        StarRatingView(rating: Binding(
                                            get: { rates },
                                            set: { newRating in
                                                rates = newRating
                                                // 서버에 별점 업데이트
                                            }
                                        ))
                                        .frame(height: 20)
                                        .onAppear {
                                            rates = 4 // 기본 별점 설정
                                        }
                                    }
                                    Spacer()
                                    Text(restaurant.address)
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

                                // 별점 표시
                               
                                // About 섹션 (맛집은 About이 없음
//                                VStack(alignment: .leading, spacing: 8) {
//                                    Text("About")
//                                        .font(.headline)
//                                    Text("카페&베이커리페어는 카페 창업주와 바이어를 대상으로 한 전문 전시회로, 카페 운영에 필요한 원두, 로스팅 머신, 장비, 인테리어 소품 등 다양한 품목을 선보인다.")
//                                        .font(.subheadline)
//                                        .foregroundColor(.gray)
//                                        .lineLimit(3)
//                                        .truncationMode(.tail)
//                                }
//                                .padding()

                                // Nearby Places 섹션
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Nearby Places")
                                            .font(.headline)
                                        Spacer()
                                        Button(action: {
                                            // View all 동작 추가 가능
                                        }) {
                                            HStack {
                                                Text("View all")
                                                    .font(.subheadline)
                                                    .foregroundColor(.blue)
                                                Image(systemName: "arrow.right")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            VStack {
                                                Image("royal-gardens")
                                                    .resizable()
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                                Text("Royal Gardens")
                                                    .font(.subheadline)
                                                Text("0.3 miles away")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            VStack {
                                                Image("historic-cafe")
                                                    .resizable()
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                                Text("Historic Café")
                                                    .font(.subheadline)
                                                Text("0.5 miles away")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
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
        }
        .onAppear {
            Task {
                isLoading = true
                await restaurantViewModel.fetchRestaurantDetail(name: restaurantName)
                isLoading = false
            }
        }
    }
}


#Preview {
    DetailView()
}

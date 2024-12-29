import SwiftUI

struct RestaurantDetailInfoView: View {
    var restaurant: Restaurant
    @EnvironmentObject var appState: AppState
    @State private var rates: Int = 0 // StarRatingView와 바인딩할 별점 값

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(restaurant.name)
                    .font(.title)
                    .fontWeight(.bold)

                Spacer() // 이름과 버튼 사이 간격 확보

                Button(action: {
                    // Navigate 버튼 동작 추가 가능
                    print(appState.userEmail)
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
                    .frame(height: 15)
                }

            }

            VStack(alignment: .leading) {
                StarRatingView(rating: Binding(
                    get: { rates },
                    set: { newRating in
                        rates = newRating
                        // 서버에 별점 업데이트
                    }
                ))
                .frame(height: 15)
                .onAppear {
                    rates = 4 // 기본 별점 설정
                }
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("운영 시간: \(restaurant.operatingHour)")
                    .font(.subheadline)
            }

            HStack(spacing: 4) {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                Text(restaurant.address)
                    .font(.subheadline)
            }

            if !restaurant.closedDays.isEmpty {
                Text("휴무일: \(restaurant.closedDays)")
                    .font(.subheadline)
            }
            if !restaurant.parking.isEmpty {
                Text("주차: \(restaurant.parking)")
                    .font(.subheadline)
            }
            if !restaurant.contactInfo.isEmpty {
                Text("연락처: \(restaurant.contactInfo)")
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

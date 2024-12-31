//
//  BookMarkView.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI

struct BookMarkView: View {
    @EnvironmentObject var restaurantViewModel: RestaurantViewModel // 뷰모델 참조
    @State private var isLoading = true // 로딩 상태 표시
    @State private var selectedRestaurant: Restaurant? = nil // 선택된 레스토랑 정보

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("북마크 로드 중...")
                        .font(.headline)
                        .padding()
                } else if restaurantViewModel.bookmarkedRestaurants.isEmpty {
                    Text("저장된 북마크가 없습니다.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(restaurantViewModel.bookmarkedRestaurants) { restaurant in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(restaurant.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(restaurant.address ?? "주소 정보 없음")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                selectedRestaurant = restaurant // 선택된 레스토랑 설정
                            }) {
                                Text("보기")
                                    .font(.footnote)
                                    .padding(8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
            }
            .navigationTitle("북마크")
            .onAppear {
                loadBookmarks()
            }
            .background(
                NavigationLink(
                    destination: DetailView(restaurants: selectedRestaurant!),
                    isActive: Binding(
                        get: { selectedRestaurant != nil },
                        set: { if !$0 { selectedRestaurant = nil } }
                    )
                ) {
                    EmptyView()
                }
            )
        }
    }

    private func loadBookmarks() {
        guard let userEmail = UserDefaults.standard.string(forKey: "user_email") else {
            print("유저 이메일이 설정되지 않았습니다.")
            isLoading = false
            return
        }

        isLoading = true
        restaurantViewModel.fetchBookmarkedRestaurants(userEmail: userEmail)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 간단한 로딩 시뮬레이션
            isLoading = false
        }
    }
}

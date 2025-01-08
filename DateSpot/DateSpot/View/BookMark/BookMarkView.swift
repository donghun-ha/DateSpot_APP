//
//  BookMarkView.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI

struct BookMarkView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var restaurantViewModel: RestaurantViewModel // 뷰모델 참조
    @State private var isLoading = true
    @State private var selectedRestaurant: BookmarkedRestaurant? = nil // BookmarkedRestaurant로 변경

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
                        NavigationLink(
                            destination: RestaurantDetailView(
                                name: restaurant.name
                            )
                        ) {
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
        }
    }

    private func loadBookmarks() {
        guard let userEmail = appState.userEmail else {
            print("유저 이메일이 설정되지 않았습니다.")
            isLoading = false
            return
        }
        isLoading = true
        restaurantViewModel.fetchBookmarkedRestaurants(userEmail: userEmail)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }
}

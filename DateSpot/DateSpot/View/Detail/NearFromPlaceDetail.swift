//
//  NearFromPlaceDetail.swift
//  DateSpot
//
//  Created by 이종남 on 1/10/25.
//

import SwiftUI

struct NearFromPlaceDetails: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var isLoading = true
    
    
    var currentLat: Double = 37.5665 // 현재 위도
    var currentLng: Double = 126.9780 // 현재 경도

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text("근처의 레스토랑")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    Text("해당 장소와 가까운 레스토랑들을 확인하세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }

                // 컨텐츠
                if isLoading {
                    ProgressView("Loading restaurants...")
                        .font(.headline)
                        .padding()
                } else if !restaurantViewModel.nearbyRestaurants.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(restaurantViewModel.nearbyRestaurants, id: \.name) { restaurant in
                            NearRestaurantRow(
                                restaurant: restaurant,
                                restaurantViewModel: restaurantViewModel,
                                currentLat: currentLat,
                                currentLng: currentLng
                            )
                        }

                    }
                } else {
                    VStack {
                        Text("근처 레스토랑을 찾을 수 없습니다.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
            .padding(.top)
        }
        .onAppear {
            Task {
                isLoading = true
                await restaurantViewModel.fetchNearbyRestaurants(lat: currentLat, lng: currentLng)
                isLoading = false
            }
        }
    }
}

struct NearRestaurantRow: View {
    let restaurant: Restaurant
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @EnvironmentObject var appState: AppState
    let currentLat: Double
    let currentLng: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목 및 북마크 버튼
            HStack {
                Text(restaurant.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    restaurantViewModel.addBookmark(userEmail: "user@example.com", restaurantName: restaurant.name, name: restaurant.name, state: appState.isLoggedIn)
                }) {
                    Image(systemName: restaurantViewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(.blue)
                }
            }

            // 주소 및 거리
            HStack {
                Text(restaurant.address)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
                Text("\(String(format: "%.2fkm", calculateDistance()))")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            // 이미지
            if let image = restaurantViewModel.homeimage[restaurant.name] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .cornerRadius(12)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                        .cornerRadius(12)
                    Text("이미지 로드 중...")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .onAppear {
                            Task {
                                await restaurantViewModel.fetchFirstImage(for: restaurant.name)
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }

    // 거리 계산
    private func calculateDistance() -> Double {
        return restaurantViewModel.calculateDistance(
            lat: restaurant.lat,
            lng: restaurant.lng,
            currentLat: currentLat,
            currentLng: currentLng
        )
    }
}

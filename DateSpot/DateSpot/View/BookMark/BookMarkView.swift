//
//  BookMarkView.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI

struct BookMarkView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var restaurantViewModel: RestaurantViewModel // 맛집 뷰모델 참조
    @EnvironmentObject var placeViewModel: PlaceViewModel // 명소 뷰모델 참조
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var navigateToMyPage = false // 마이페이지 이동 여부
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("북마크 로드 중...")
                        .font(.headline)
                        .padding()
                } else if restaurantViewModel.bookmarkedRestaurants.isEmpty && placeViewModel.bookmarkedPlaces.isEmpty {
                    // 북마크가 없을 경우
                    Text("저장된 북마크가 없습니다.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // 맛집 섹션과 명소 섹션을 구분
                    List {
                        // 맛집 섹션
                        if !restaurantViewModel.bookmarkedRestaurants.isEmpty {
                            Section(header: Text("맛집")) {
                                ForEach(restaurantViewModel.bookmarkedRestaurants, id: \.id) { restaurant in
                                    NavigationLink(
                                        destination: RestaurantDetailView(
                                            name: restaurant.name,
                                            type: "restaurant"
                                        )
                                    ) {
                                        BookmarkRowView(
                                            title: restaurant.name,
                                            subtitle: restaurant.address ?? "주소 정보 없음"
                                        )
                                    }
                                }
                            }
                        }
                        
                        // 명소 섹션
                        if !placeViewModel.bookmarkedPlaces.isEmpty {
                            Section(header: Text("명소")) {
                                ForEach(placeViewModel.bookmarkedPlaces, id: \.id) { place in
                                    NavigationLink(
                                        destination: PlaceDetailView(
                                            placeName: place.name,
                                            type: "place"
                                        )
                                    ) {
                                        BookmarkRowView(
                                            title: place.name,
                                            subtitle: place.address ?? "주소 정보 없음"
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
            }
            .navigationTitle("북마크")
            .onAppear {
                loadBookmarks()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("로그인 필요"),
                    message: Text("북마크를 보려면 로그인이 필요합니다."),
                    dismissButton: .default(Text("확인")) {
                        navigateToMyPage = true // 활성화
                    }
                )
            }
            .navigationDestination(
                isPresented: $navigateToMyPage){
                    UserView()
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
        
        Task {
            restaurantViewModel.fetchBookmarkedRestaurants(userEmail: userEmail)
            placeViewModel.fetchBookmarkedPlaces(userEmail: userEmail)
            
            print("Loaded Restaurants: \(restaurantViewModel.bookmarkedRestaurants.count)")
            print("Loaded Places: \(placeViewModel.bookmarkedPlaces.count)")
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    // 북마크 셀 뷰
    struct BookmarkRowView: View {
        let title: String
        let subtitle: String
        
        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
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

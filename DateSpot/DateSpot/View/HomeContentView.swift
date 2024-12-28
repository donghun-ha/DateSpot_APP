//
//  SocialLoginButton.swift
//  DateSpot
//
//  Created by 이종남 on 26/12/2024.
//

import SwiftUI

struct HomeContentView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .font(.headline)
            } else {
                if !restaurantViewModel.restaurants.isEmpty {
                    NavigationView {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("맛집")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(restaurantViewModel.restaurants, id: \.self) { restaurant in
                                            CardView(
                                                category: restaurant.parking,
                                                heading: restaurant.name,
                                                author: restaurant.address
                                            )
                                            .frame(width: 300)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                } else {
                    Text("No restaurants available.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
        }
        .onAppear {
            Task {
                isLoading = true
                await restaurantViewModel.fetchRestaurants()
                isLoading = false
            }
        }
    }
}

    // MARK: - 미리보기
    #Preview {
        HomeContentView()
    }


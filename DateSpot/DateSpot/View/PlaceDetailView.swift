//
//  PlaceDetailView.swift
//  DateSpot
//
//  Created by 하동훈 on 8/1/2025.
//

import SwiftUI
import RealmSwift

struct PlaceDetailView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @StateObject private var placeViewModel = PlaceViewModel()
    @State private var selection: Int = 0
    @State private var isLoading = true
    @State private var nearbyRestaurants: [Restaurant] = []
    var placeName: String = "남산서울타워"


    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading...")
                    .font(.headline)
            } else if let place = placeViewModel.selectedPlace {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 이미지 슬라이더
                        if !placeViewModel.images.isEmpty {
                            ImageSliderView(
                                currentRestaurant: placeName,
                                images: placeViewModel.images,
                                selection: $selection
                            )
                        } else {
                            Text("No images available")
                                .foregroundColor(.gray)
                                .frame(height: 260)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .padding()
                        }
                        
                        // 명소 상세 정보
                        PlaceDetailInfoView(place: place, images: $placeViewModel.images[0])

                        // 근처 명소
                        if !nearbyRestaurants.isEmpty {
                            NearFromPlaceDetails()
                        } else {
                            Text("No nearby places found.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                }
            } else {
                Text("Restaurant not found.")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            print("Detail뷰 받은 레스토랑 이름: \(placeName)")
            Task {
                await placeViewModel.fetchPlaceDetail(name: placeName)
                isLoading = true
                // 명소 세부 정보 및 이미지 가져오기
                await placeViewModel.loadImages(for: placeName)

                // 명소 데이터 가져오기
                await placeViewModel.fetchPlaces(currentLat: placeViewModel.selectedPlace?.lat ?? 37.5665, currentLng: placeViewModel.selectedPlace?.lng ?? 126.9780)
                // 명소를 기준으로 근처 레스토랑 데이터 가져오기
                 if let place = placeViewModel.selectedPlace {
                     await restaurantViewModel.fetchNearbyRestaurants(
                         lat: place.lat,
                         lng: place.lng
                     )
                     nearbyRestaurants = calculateNearbyRestaurant(
                         restaurants: restaurantViewModel.nearbyRestaurants,
                         placeLat: place.lat,
                         placeLng: place.lng
                     )
                 }

                 isLoading = false
             }
         }
     }

     // 근처 레스토랑 계산 함수
     private func calculateNearbyRestaurant(restaurants: [Restaurant], placeLat: Double, placeLng: Double) -> [Restaurant] {
         return restaurants
             .map { restaurant in
                 (restaurant, calculateDistance(lat1: placeLat, lng1: placeLng, lat2: restaurant.lat, lng2: restaurant.lng))
             }
             .sorted(by: { $0.1 < $1.1 }) // 거리 기준 정렬
             .prefix(5) // 가장 가까운 5개 선택
             .map { $0.0 }
     }
    // 거리 계산 함수
    private func calculateDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let deltaLat = lat2 - lat1
        let deltaLng = lng2 - lng1
        return sqrt(deltaLat * deltaLat + deltaLng * deltaLng) * 111 // 대략적인 거리(km)
    }
}




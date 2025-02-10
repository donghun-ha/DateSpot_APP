//
// PlaceDetailInfoView.swift
//  DateSpot
//
//  Created by 하동훈 on 8/1/2025.
//

import SwiftUI

struct PlaceDetailInfoView: View {
    @State var place: PlaceData
    @EnvironmentObject var appState: AppState
    @StateObject private var ratingViewModel = RatingViewModel()
    @State private var rates: Int = 0 // StarRatingView와 바인딩할 별점 값
    @Binding var images :  UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(place.name)
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                   print(appState.userEmail ?? "")
               }) {
                   NavigationLink(destination: PlaceDetailMap(place: $place, images: $images, rates: $rates), label: {
                   HStack {
                       Image(systemName: "paperplane.fill")
                           .foregroundColor(.white)
                       Text("Navigate")
                           .foregroundColor(.white)
                   }
                   })
                   .padding()
                   .background(Color.blue)
                   .cornerRadius(8)
               }

            }

            VStack(alignment: .leading) {
                StarRatingView(rating: Binding(
                    get: { rates },
                    set: { newRating in
                        rates = newRating
                    }
                )) { newRating in
                    Task {
                        if let email = appState.userEmail {
                            print("Updating rating to \(newRating)")
                            await ratingViewModel.placeupdateUserRating(for: email, placeName: place.name, rating: newRating)
                            await ratingViewModel.placefetchUserRating(for: email, placeName: place.name)
                            rates = ratingViewModel.userRating ?? 0
                        } else {
                            print("User email is not available")
                        }
                    }
                }
                .frame(height: 20)
                .onAppear {
                    Task {
                        if let email = appState.userEmail {
                            await ratingViewModel.placefetchUserRating(for: email, placeName: place.name)
                            rates = ratingViewModel.userRating ?? 0
                        }
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("운영 시간: \(place.operating_hour)")
                    .font(.subheadline)
            }

            HStack(spacing: 4) {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                Text(place.address)
                    .font(.subheadline)
            }

//            if !restaurant.closedDays.isEmpty {
//                Text("휴무일: \(restaurant.closedDays)")
//                    .font(.subheadline)
//            }
            if !place.parking.isEmpty {
                Text("주차: \(place.parking)")
                    .font(.subheadline)
            }
            if !place.contact_info.isEmpty {
                Text("연락처: \(place.contact_info)")
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

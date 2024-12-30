//
//  DetailMap.swift
//  DateSpot
//
//  Created by 신정섭 on 12/26/24.
//
import SwiftUI
import MapKit


struct DetailMap: View {
    @StateObject private var viewModel = DetailMapViewModel()
    @Binding var restaurants : Restaurant
//    @Binding var place : PlaceData
    @State var loadingStatus = false
    
    var body: some View {
        NavigationView {
            if loadingStatus == false{
                ProgressView("Loading...")
                    .font(.headline)
            }
            ZStack {
                Map(position:$viewModel.cameraPosition) {
                    UserAnnotation()
                    
                    ForEach(viewModel.nearParking, id: \.id) { parking in
                        Marker(parking.name, systemImage: "car.fill", coordinate: parking.coordinate)
                            .tint(.blue)
                    }
                    Marker(restaurants.name, systemImage: "star.fill", coordinate: CLLocationCoordinate2D(latitude: restaurants.lat, longitude: restaurants.lng))
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    // 하단 카드 뷰
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(restaurants.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(restaurants.parking)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            //                            Image("") //이미지
                            //                                .resizable()
                            
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text(restaurants.address)
                            }
                            
                            HStack {
                                Image(systemName: "clock.fill")
                                Text(restaurants.operatingHour)
                            }
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                Text(restaurants.contactInfo)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding()
                }
            }
            .onAppear {
                viewModel.updateCameraPosition(latitude: restaurants.lat, longitude: restaurants.lng)
                viewModel.fetchParkingInfo(lat: restaurants.lat, lng: restaurants.lng)
                loadingStatus = true
                
            }
        }
        .navigationTitle("지도")
    } // View
    
} // End

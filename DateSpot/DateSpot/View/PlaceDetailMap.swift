//
//  PlaceDetailMap.swift
//  DateSpot
//
//  Created by 하동훈 on 8/1/2025.
//

import SwiftUI
import MapKit


struct PlaceDetailMap: View {
    @StateObject private var viewModel = DetailMapViewModel()
    @Binding var place : PlaceData
    @Binding var images : UIImage
    @Binding var rates : Int
    @State var selectedMarker : String?
    @State var selectValue = false
    @State var selectedParkingId : String?

    @State var loadingStatus = false
    
    var body: some View {
        NavigationView {
            if loadingStatus == false{
                ProgressView("Loading...")
                    .font(.headline)
            }else{
                ZStack {
                    Map(position:$viewModel.cameraPosition) {
                        UserAnnotation()
                        
                        ForEach(viewModel.nearParking, id: \.id) { parking in
                            Marker(parking.name, systemImage: "car.fill", coordinate: parking.coordinate)
                                .tint(.blue)
                            
                        }
                        Marker(place.name, systemImage: "star.fill", coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lng))
                            
                    }
                    .ignoresSafeArea()
                    .onChange(of: selectedMarker) { _, newValue in
                        selectValue = newValue != nil
                                        }
                    if selectedMarker == "여의도공원앞(구)" {
                        if selectValue, let selectedName = selectedMarker {
                            VStack {
                                Text("혼잡")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                Spacer()
                            }
                            .padding(.top, 50)
                        }
                    }
                    VStack {
                        Spacer()
                        // 하단 카드 뷰
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(place.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(uiImage: images)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text(place.address)
                                }
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                    Text(place.operating_hour)
                                }
                                
                                
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(place.contact_info)
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
            }
        }
        .navigationTitle("지도")
        .onAppear {
                viewModel.updateCameraPosition(latitude: place.lat, longitude: place.lng)
                viewModel.fetchParkingInfo(lat: place.lat, lng: place.lng)
                loadingStatus = true
            
        }
    } // View
} // End

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
    @Binding var place: PlaceData
    @Binding var images: UIImage
    @Binding var rates: Int
    @State var selectedMarker: String?
    @State var selectValue = false
    @State var selectedParkingId: String?

    @State var loadingStatus = false

    var body: some View {
        NavigationView {
            if loadingStatus == false {
                ProgressView("Loading...")
                    .font(.headline)
            } else {
                ZStack {
                    // 지도 렌더링
                    Map(position: $viewModel.cameraPosition) {
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
                    
                    // 하단 카드 뷰
                    VStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(place.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primary) // 다크모드/라이트모드 자동 대응
                                    
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        rates != 0 ? Text("\(String(rates)).0") : Text("별점을 입력하세요")
                                            .foregroundColor(Color.primary)
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
                                        .foregroundColor(Color.primary)
                                }
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                    Text(place.operating_hour)
                                        .foregroundColor(Color.primary)
                                }
                                
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(place.contact_info)
                                        .foregroundColor(Color.primary)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground)) // 다크모드/라이트모드 자동 대응
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
    }
}

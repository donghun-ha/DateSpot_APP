//
//  RestaurantDetailMap.swift
//  DateSpot
//
//  Created by 신정섭 on 12/26/24.
//
import SwiftUI
import MapKit

struct RestaurantDetailMap: View {
    @StateObject private var viewModel = DetailMapViewModel()
    @Binding var restaurants: Restaurant
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
                        
                        Marker(restaurants.name, systemImage: "star.fill", coordinate: CLLocationCoordinate2D(latitude: restaurants.lat, longitude: restaurants.lng))
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
                                    Text(restaurants.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primary) // 다크모드/라이트모드 대응
                                    
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        rates != 0 ? Text("\(String(rates)).0") : Text("별점을 입력하세요")
                                            .foregroundColor(Color.primary) // 다크모드/라이트모드 대응
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
                                    Text(restaurants.address)
                                        .foregroundColor(Color.primary) // 다크모드/라이트모드 대응
                                }
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                    Text(restaurants.operatingHour)
                                        .foregroundColor(Color.primary) // 다크모드/라이트모드 대응
                                }
                                
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text(restaurants.contactInfo)
                                        .foregroundColor(Color.primary) // 다크모드/라이트모드 대응
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground)) // 다크모드/라이트모드 대응
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("지도")
        .onAppear {
            viewModel.updateCameraPosition(latitude: restaurants.lat, longitude: restaurants.lng)
            viewModel.fetchParkingInfo(lat: restaurants.lat, lng: restaurants.lng)
            loadingStatus = true
        }
    }
}

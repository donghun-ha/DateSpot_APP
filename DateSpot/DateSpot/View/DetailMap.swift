//
//  DetailMap.swift
//  DateSpot
//
//  Created by 신정섭 on 12/26/24.
//
import SwiftUI
import MapKit

struct DetailMap : View {
    @StateObject private var viewModel = DetailMapViewModel()
    
    var body: some View {
        NavigationView {
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation() // 내위치 표시
                
                ForEach(viewModel.nearParking, id: \.id) { parking in
                    Marker(parking.name, systemImage: "car.fill", coordinate: parking.coordinate)
                        .tint(.blue) // 마커 설정
                }
            }
            .ignoresSafeArea()
            .onAppear {
                // 지역 정보를 입력하여 주차장 데이터 가져오기
                viewModel.fetchParkingInfo()
            }
        }
    }
}


            


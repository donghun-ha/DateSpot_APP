//
//  TabbarMap.swift
//  DateSpot
//
//  Created by 신정섭 on 12/26/24.
//

//import Foundation

import SwiftUI
import MapKit
import CoreLocation


struct TabbarMapView: View {
    @StateObject private var viewModel = TabMapViewModel()

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            ForEach(viewModel.places) { place in
                Marker(place.name, coordinate: place.coordinate)
                    .tint(.blue) // 마커 색상 설정
            }
        }
        .ignoresSafeArea()
    }
}




#Preview{
    TabbarMapView()
}

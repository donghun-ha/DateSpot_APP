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

//
//  test.swift
//  DateSpot
//
//  Created by 신정섭 on 12/27/24.
//



struct TabbarMapView : View {
    @StateObject private var maptest = TabMapViewModel()
    var body: some View {
        NavigationView{
            Map(position: $maptest.cameraPosition) {
                ForEach(maptest.places) { place in
                    Marker(place.name, coordinate: place.coordinate)
                        .tint(.blue) // 마커 색상 설정
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview{
    TabbarMapView()
}

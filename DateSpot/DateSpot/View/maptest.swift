//
//  test.swift
//  DateSpot
//
//  Created by 신정섭 on 12/27/24.
//

import SwiftUI

struct MapTest: View {
    @StateObject private var maptest = TabMapViewModel()

    var body: some View {
        NavigationView {
            List(maptest.parkingData) { parking in
                VStack(alignment: .leading) {
                    Text(parking.name)
                        .font(.headline)
                    Text(parking.address)
                        .font(.subheadline)
                    Text("Latitude: \(parking.lat)")
                        .font(.caption)
                    Text("Longitude: \(parking.lng)")
                        .font(.caption)
                }
            }
            .navigationTitle("Parking Info")
//            .onAppear {
//                maptest.nearParking
//            }
        }
    }
}


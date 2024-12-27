//
//  Parking.swift
//  DateSpot
//
//  Created by 신정섭 on 12/27/24.
//

import Foundation

class Parking : Decodable, Identifiable{
    
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    
    init(name: String, address: String, lat: Double, lng: Double) {
        self.name = name
        self.address = address
        self.lat = lat
        self.lng = lng
    }
}


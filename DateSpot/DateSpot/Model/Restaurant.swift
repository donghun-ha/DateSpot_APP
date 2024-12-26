//
//  Restaurant.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//

import Foundation

struct Restaurant: Decodable{
    var name: String
    var address: String
    var lat: Double
    var lng: Double
    var parking: String
    var operatingHours: String
    var closedDays: String
    var contactInfo: String
    var breakTime: String
    var lastOrder: String
}

extension Restaurant: Hashable{
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

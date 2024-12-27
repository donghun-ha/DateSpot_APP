//
//  Restaurant.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//

import Foundation

struct Restaurant: Codable, Hashable {
    var name: String
    var address: String
    var lat: Double
    var lng: Double
    var parking: String
    var operatingHour: String
    var closedDays: String
    var contactInfo: String
    var breakTime: String?
    var lastOrder: String?
}

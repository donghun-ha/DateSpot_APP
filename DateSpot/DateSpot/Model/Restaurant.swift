//
//  Restaurant.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//

import Foundation

struct Restaurant: Codable, Hashable, Identifiable {
    var id: String { name } // 고유 식별자
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

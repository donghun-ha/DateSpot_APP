//
//  RestaurantData.swift
//  DateSpot
//
//  Created by 이종남 on 12/26/24.
//

import Foundation

struct PlaceData: Decodable {
    var name: String
    var address: String
    var lat: Double
    var lng: Double
    var description: String
    var contact_info: String
    var operating_hours: String
    var parking: String
    var closing_time: String
}

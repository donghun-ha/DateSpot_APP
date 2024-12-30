//
//  Restaurant_Book.swift
//  DateSpot
//
//  Created by mac on 12/30/24.
//

import Foundation

struct RestaurantBook: Codable, Hashable {
    var id: Int?
    var userEmail: String
    var restaurantName: String
    var name: String
    var createdAt: Date
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//
//  Rating.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//

import Foundation

struct Rating: Codable, Hashable {
    var id: Int?
    var userEmail: String
    var bookName: String
    var evaluation: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

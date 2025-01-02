//
//  BookmarkedRestaurant.swift
//  DateSpot
//
//  Created by 하동훈 on 31/12/2024.
//

import Foundation

struct BookmarkedRestaurant: Codable, Identifiable, Hashable {
    var id: String {name} // Identifiable을 위한 고유 ID
    var name: String
    var address: String?
}

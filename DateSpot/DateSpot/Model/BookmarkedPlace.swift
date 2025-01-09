//
//  BookmarkedPlace.swift
//  DateSpot
//
//  Created by 하동훈 on 9/1/2025.
//

struct BookmarkedPlace: Codable, Identifiable, Hashable {
    var id: String {name} // Identifiable을 위한 고유 ID
    var name: String
    var address: String?
}

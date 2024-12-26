//
//  Rating.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//

import Foundation

struct Rating: Decodable{
    var id: Int
    var userEmail: String
    var bookName: String
    var evaluation: Double
    
}

extension Rating: Hashable{
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

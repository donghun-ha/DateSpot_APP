//
//  Parking.swift
//  DateSpot
//
//  Created by 신정섭 on 12/27/24.
//

import Foundation
import CoreLocation

struct Parking: Identifiable, Decodable {
    var id = UUID() // 고유 식별자 
    var address : String
    var name: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), address: String, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.address = address
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    
    
    enum CodingKeys: CodingKey {
        case address
        case name
        case latitude
        case longitude
    }
   }

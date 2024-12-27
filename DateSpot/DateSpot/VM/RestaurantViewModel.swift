//
//  RestaurantViewModel.swift
//  DateSpot
//
//  Created by 이종남 on 12/27/24.
//

import SwiftUI
import Combine

class RestaurantViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    
    // 로컬 JSON에서 가져오기 (예: "restaurants.json")
    func fetchRestaurants() {
        guard let url = Bundle.main.url(forResource: "restaurants", withExtension: "json") else {
            print("로컬 restaurants.json 파일을 찾을 수 없습니다.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Restaurant].self, from: data)
            self.restaurants = decoded
        } catch {
            print("Restaurant JSON 디코딩 에러:", error.localizedDescription)
        }
    }
}

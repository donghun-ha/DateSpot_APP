//
//  PlaceViewModel.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI

protocol PlaceQueryModelProtocol {
    func itemDownloaded(items: [PlaceData])
}

class PlaceViewModel: ObservableObject {
    var delegate: PlaceQueryModelProtocol?
    let urlPath = "https://fastapi.fre.today/place/select"

    func downloadItems() async {
        let url = URL(string: urlPath)!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decodedData = try? JSONDecoder().decode([PlaceData].self, from: data) {
                print("✅ 데이터 다운로드 성공: \(decodedData)")
                delegate?.itemDownloaded(items: decodedData)
            } else {
                print("❌ 데이터 파싱 실패")
            }
        } catch {
            print("❌ 데이터 다운로드 실패: \(error.localizedDescription)")
        }
    }
}

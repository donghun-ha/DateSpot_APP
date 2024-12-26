//
//  QueryRating.swift
//  DateSpot
//
//  Created by mac on 12/26/24.
//

import Foundation

protocol MainQueryModelProtocol {
    func itemDownloaded(items: [Restaurant])
}

class QueryRating{
    var delegate: MainQueryModelProtocol!
    let urlPath = "https://fastapi.fre.today/rating"
    
    func downloadItems()async{
        let url = URL(string: urlPath)!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await parseJSON(data)
        } catch {
            print("Failed to download data : \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func parseJSON(_ data: Data)async{
        
        let decoder = JSONDecoder()
        var locations : [Address] = []
        do{
            let addresses = try decoder.decode([MainJson].self, from : data)
            for address in addresses{
                // 이미지 Base64 디코딩
                if let imageString = address.image,
                   let imageDataDecoded = Data(base64Encoded: imageString, options: .ignoreUnknownCharacters),
                   let wow  = UIImage(data: imageDataDecoded)
                {
                    let query = Address(id : address.seq, name: address.name, phoneNumber: address.phone, address: address.address, relation: address.relationship, photo: wow )
                    locations.append(query)
                }else{
                    let query = Address(id : address.seq, name: address.name, phoneNumber: address.phone, address: address.address, relation: address.relationship, photo: UIImage(named: "lamp_on")!)
                    locations.append(query)}
            }
            
        } catch{
            print("Failed : \(error.localizedDescription)")
        }
        self.delegate.itemDownloaded(items: locations)
    }
    
}/// MainQueryModel

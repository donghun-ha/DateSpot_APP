//
//  CardView.swift
//  DateSpot
//
//  Created by 이종남 on 12/27/24.
//

import SwiftUI

struct CardView: View {
    //    var image: String
    var category: String
    var heading: String
    var author: String
    
    var body: some View {
        VStack(alignment: .leading) {
            //            Image(image)
            //                .resizable()
            //                .scaledToFill()
            //                .frame(height: 150)
            //                .clipped()
            //
            VStack(alignment: .leading) {
                Text(category)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text(heading)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(author)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

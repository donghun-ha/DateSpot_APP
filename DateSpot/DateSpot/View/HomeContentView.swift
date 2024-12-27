//
//  HomeContentView.swift
//  DateSpot
//
//  Created by 이종남 on 26/12/2024.
//

import SwiftUI

struct HomeContentView: View {
    @EnvironmentObject var appState: AppState // AppState를 사용

    var body: some View {
        NavigationView {
            VStack(content: {
                Text("Home Page")
                    .font(.title)
                    .padding()
            })
            .navigationTitle("홈")
        }
    }
}


#Preview {
    HomeContentView()
}


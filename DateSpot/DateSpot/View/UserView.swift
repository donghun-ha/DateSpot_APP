//
//  UserView.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//

import SwiftUI

import SwiftUI

struct UserView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("프로필 화면")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("프로필")
        }
    }
}

#Preview {
    UserView()
}

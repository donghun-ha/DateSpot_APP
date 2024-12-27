//
//  TabBarView.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            HomeContentView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            TabbarMapView()
                .tabItem {
                    Label("지도", systemImage: "map.fill")
                }

            BookMarkView()
                .tabItem {
                    Label("북마크", systemImage: "bookmark.fill")
                }

            UserView()
                .tabItem {
                    Label("프로필", systemImage: "person.fill")
                }
        }
    }
}



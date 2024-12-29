//
//  TabBarView.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appState: AppState // 전역 상태 사용
    
    var body: some View {
        TabView {
            DetailView()
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
        .environmentObject(appState) // 전역 상태 전달
    }
}



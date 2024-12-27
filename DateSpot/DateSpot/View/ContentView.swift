//
//  ContentView.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState // 앱 상태 접근

    var body: some View {
        if appState.isLoggedIn {
            TabBarView() // 로그인 후 TabBar로 이동
        } else {
            LoginView() // 로그인 화면
        }
    }
}

#Preview {
    ContentView().environmentObject(AppState())
}

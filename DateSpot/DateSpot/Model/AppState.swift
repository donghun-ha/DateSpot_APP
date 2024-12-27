//
//  AppState.swift
//  DateSpot
//
//  Created by 하동훈 on 27/12/2024.
//

import SwiftUI

// 앱의 전역 상태를 관리하는 클래스
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false // 로그인 여부
}

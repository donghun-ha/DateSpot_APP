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
    @Published var userEmail: String = "" // 로그인한 사용자 이메일
    @Published var userName: String =  "" // 로그인한 사용자 이름
    @Published var userImage: UIImage? = nil // 로그인한 사용자 프로필 이미지
}

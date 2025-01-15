//
//  DateSpotApp.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI
import FirebaseCore // import Firebase
import GoogleSignIn // import Google

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            // Firebase 초기화
            FirebaseApp.configure()
            print("Firebase 연결 성공")
            
            // GoogleSignIn 초기화
            if let clientID = FirebaseApp.app()?.options.clientID {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
                print("Google ClientID 초기화 성공: \(clientID)")
            }else{
                print("Google ClientID 초기화 실패")
            }
            return true
        }
}

// MARK: - Google Login
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}
    
// MARK: - Main
@main
struct DateSpotApp: App {
    @StateObject private var appState = AppState() // AppSate 초기화
    @StateObject private var restaurantViewModel = RestaurantViewModel() // 뷰모델 초기화
    @StateObject private var placeViewModel = PlaceViewModel()           // 뷰모델 초기화
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // AppDelegate 연결
    
    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                TabBarView() // 로그인 후 홈 화면으로 이동
                    .environmentObject(appState) // 앱 상태를 전달
                    .environmentObject(restaurantViewModel) // environmentObject로 전달
                    .environmentObject(placeViewModel)      // environmentObject로 전달
            } else {
                LoginView() // 로그인 화면
                    .environmentObject(appState) // 앱 상태를 전달
            }
        }
    }
}

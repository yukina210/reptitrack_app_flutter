//
//  reptitrack_appApp.swift
//  reptitrack_app
//
//  Created by 後藤由希菜 on 2025/04/13.
//

// import SwiftUI

//@main
//struct reptitrack_appApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

import SwiftUI
import FirebaseCore

// Firebase 初期化用 AppDelegate を定義
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct reptitrack_appApp: App {
  // AppDelegate を SwiftUI App に登録
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject var authViewModel = AuthViewModel()

  var body: some Scene {
    WindowGroup {
        if authViewModel.user != nil {
            Text("ログイン成功！") // ←あとでDashboardなどに差し替える
        } else {
            LoginView()
                .environmentObject(authViewModel)
        }
//      NavigationView {
//        ContentView()
//      }
    }
  }
}

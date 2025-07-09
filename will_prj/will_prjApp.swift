//
//  will_prjApp.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI
import FirebaseCore
import Cloudinary
import ActivityKit
import UserNotifications
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        GroupViewModel.shared.endLiveActivity()
        return true
    }
    
    func applicationWillTerminate(){
        GroupViewModel.shared.endLiveActivity()
    }
    
    
}

@main
struct will_prjApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var vm: LoginViewModel = LoginViewModel()
    
    var body: some Scene {
        WindowGroup {
            if vm.isLogin{
                ContentView()
                    .environmentObject(vm)
                    .onDisappear{
                        GroupActivityManager().endLiveActivity()
                    }
            }else{
                LoginScreen()
                    .environmentObject(vm)
            }
        }
    }
}

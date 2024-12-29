//
//  will_prjApp.swift
//  will_prj
//
//  Created by 邱允聰 on 20/12/2024.
//

import SwiftUI
import FirebaseCore
import Cloudinary

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()                        
        return true
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
            }else{
                LoginScreen()
                    .environmentObject(vm)
            }
        }
    }
}

//
//  AppDelegate.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import UIKit
import Photos

class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        return true
//    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
//        if connectingSceneSession.role == .windowApplication {
//            configuration.delegateClass = SceneDelegate.self
//        }
        
        configuration.sceneClass = SceneDelegate.self
        
        return configuration
    }
}


class WindowSharedModel: ObservableObject {
    var sourceRect: CGRect = .zero
    var previousSourceRect: CGRect = .zero
    var hideNativeView: Bool = false
    var selectedCollection: PHCollection?
    
    func reset() {
        sourceRect = .zero
        previousSourceRect = .zero
        hideNativeView = false
        selectedCollection = nil
    }
}

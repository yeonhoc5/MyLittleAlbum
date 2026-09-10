//
//  SceneDelegate.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import UIKit
import SwiftUI

//@available(iOS 17.0, *)
//@Observable
final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
  weak var windowScene: UIWindowScene?
  
  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    windowScene = scene as? UIWindowScene
  }
}

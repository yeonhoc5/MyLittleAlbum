//
//  SceneDelegate.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import UIKit
import SwiftUI

final class SceneDelegate: NSObject, UIWindowSceneDelegate {

  var secondaryWindow: UIWindow?

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
      if let windowScene = scene as? UIWindowScene {
          setupSecondaryOverlayWindow(in: windowScene)
      }
  }

  func setupSecondaryOverlayWindow(in scene: UIWindowScene) {
      let secondaryViewController = UIHostingController(
          rootView:
              EmptyView()
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                  .modifier(InAppAlertModifier())
                  .modifier(InAppSheetModifier())
      )
      secondaryViewController.view.backgroundColor = .clear
      let secondaryWindow = PassThroughWindow(windowScene: scene)
      secondaryWindow.rootViewController = secondaryViewController
      secondaryWindow.isHidden = false
      self.secondaryWindow = secondaryWindow
  }
}


class PassThroughWindow: UIWindow {
  override func hitTest(_ point: CGPoint,
                        with event: UIEvent?) -> UIView? {
    guard let hitView = super.hitTest(point, with: event)
    else { return nil }

    return rootViewController?.view == hitView ? nil : hitView
  }
}

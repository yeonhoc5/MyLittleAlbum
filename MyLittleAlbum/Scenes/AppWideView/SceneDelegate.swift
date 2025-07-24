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
//  var secondaryWindow: UIWindow?

    var heroWindow: UIWindow?
    
  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
//      if let windowScene = scene as? UIWindowScene {
//          setupSecondaryOverlayWindow(in: windowScene)
//      }
      windowScene = scene as? UIWindowScene
  }

    func addHeroWindow(_ windowSharedModel: WindowSharedModel) {
        guard let scene = windowScene else { return }
        
        let heroViewController = UIHostingController(
            rootView: CustomHeroAnimationView()
                .environmentObject(windowSharedModel)
                .allowsHitTesting(false)
        )
        heroViewController.view.backgroundColor = .clear
        let heroWindow = UIWindow(windowScene: scene)
        heroWindow.rootViewController = heroViewController
        heroWindow.isHidden = false
        heroWindow.isUserInteractionEnabled = false
        
        self.heroWindow = heroWindow
    }
    
//  func setupSecondaryOverlayWindow(in scene: UIWindowScene) {
//      let secondaryViewController = UIHostingController(
//          rootView:
//              EmptyView()
//                  .frame(maxWidth: .infinity, maxHeight: .infinity)
//                  .modifier(InAppSheetModifier())
//                  .modifier(InAppAlertModifier())
//                  .modifier(InAppProgressView())
//                  .modifier(InAppDigitalShowModifier())
//      )
//      secondaryViewController.view.backgroundColor = .clear
//      let secondaryWindow = PassThroughWindow(windowScene: scene)
//      secondaryWindow.rootViewController = secondaryViewController
//      secondaryWindow.isHidden = false
//      self.secondaryWindow = secondaryWindow
//  }
}

struct CustomHeroAnimationView: View {
    @EnvironmentObject var windowSharedModel: WindowSharedModel
    
    var body: some View {
        Color.red.opacity(0.3)
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

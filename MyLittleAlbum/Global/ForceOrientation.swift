//
//  ForceOrientation.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/28/25.
//

import SwiftUI

struct ForceOrientation: ViewModifier {
    let orientation: UIInterfaceOrientationMask
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                AppDelegate.orientationLock = orientation
                UIViewController.attemptRotationToDeviceOrientation()
            }
            .onDisappear {
                AppDelegate.orientationLock = .portrait
                UIViewController.attemptRotationToDeviceOrientation()
            }
    }
}

extension View {
    func forceLandScpaeView(_ orientation: UIInterfaceOrientationMask) -> some View {
        self.modifier(ForceOrientation(orientation: orientation))
    }
}

//#Preview {
//    ForceOrientation(orientation: .portrait)
//}

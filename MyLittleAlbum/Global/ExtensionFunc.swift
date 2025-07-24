//
//  ExtensionFunc.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/24/25.
//

import SwiftUI
import LocalAuthentication

extension View {
    func authenticate(albumType: AlbumType, _ resultHandler: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        if context
            .canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               error: &error) {
            let reason = "We need to unlock your data."
            context
                .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: reason) { success, _ in
                    resultHandler(success)
                }
        } else {
            let reason = "We need to unlock your data."
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                   localizedReason: reason) { success, _ in
                resultHandler(success)
            }
        }
    }
}

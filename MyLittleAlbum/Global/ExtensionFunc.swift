//
//  ExtensionFunc.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/24/25.
//

import SwiftUI
import LocalAuthentication

extension View {
  func authenticate(_ resultHandler: @escaping (Bool) -> Void) {
    let context = LAContext()
    var error: NSError?
    if context
      .canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                         error: &error) {
      let reason = "We need to unlock your data."
      context
        .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                        localizedReason: reason) { success, error in
          if success {
            resultHandler(true)
          } else {
            print("biometric Fail")
            resultHandler(false)
          }
        }
    } else {
      let reason = "We need to unlock your data."
      context.evaluatePolicy(.deviceOwnerAuthentication,
                             localizedReason: reason) { success, error in
        if success {
          resultHandler(true)
        } else {
          print("password Fail")
          resultHandler(false)
        }
      }
    }
  }
}

extension Array where Element: Hashable {
    // A custom "modifier" to multiply every number in the array
  func setSubtraing(by: Set<Element>) -> [Element] {
    let set = Set(self).subtracting(by)
    return Array(set)
  }
  func setUnion(with: [Element]) -> [Element] {
    let set = Set(self).union(Set(with))
    return Array(set)
  }
  func setIntersection(with: [Element]) -> [Element] {
    let set = Set(self).intersection(Set(with))
    return Array(set)
  }
}

//
//  InAppDigitalShowModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/7/25.
//

import SwiftUI
import Photos

struct InAppDigitalShowModifier: ViewModifier {
  @State var digitalObject: DigitalShowObject!
  
  func body(content: Content) -> some View {
    content
      .overlay {
        if digitalObject != nil {
          DigitalShowView(title: digitalObject.digitalShowTitle,
                          assetArray: digitalObject.assetArray,
                          transitionSecond: digitalObject.transitionSecond,
                          nameSpace: digitalObject.nameSpace)
          .ignoresSafeArea()
        }
      }
      .onReceive(NotificationCenter.default
        .publisher(for: .showDigitalShow)) { object in
          if let digitalObject = object.object as? DigitalShowObject {
            withAnimation {
              self.digitalObject = digitalObject
            }
          }
        }
        .onReceive(NotificationCenter.default.publisher(for: .endDigitalShow)) { _ in
          DispatchQueue.main.async {
            withAnimation {
              self.digitalObject = nil
            }
          }
        }
  }
}


struct DigitalShowObject {
  var digitalShowRandom: Bool
  var transitionSecond: Int
  var assetArray: [MLAsset]
  var digitalShowTitle: String
  let nameSpace: Namespace.ID
}

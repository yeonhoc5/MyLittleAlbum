//
//  InAppDigitalModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/7/25.
//

import SwiftUI

struct InAppDigitalModifier: ViewModifier {
    @State var digitalObject: DigitalShowObject!

    func body(content: Content) -> some View {
        content
            .overlay {
                if digitalObject != nil {
                    let photosArray = digitalObject.digitalPhotoAlbums
                        .flatMap {
                            $0.frObject(isHiddenAsset: digitalObject.isHiddenAsset)
                        }
                    
                    DigitalShowView(title: digitalObject.digitalShowTitle,
                                    photosArray: photosArray,
                                    transitionSecond: digitalObject.transitionSecond,
                                    nameSpace: digitalObject.nameSpace)
                } else {
                    EmptyView()
                }
            }
            .onReceive(NotificationCenter.default
                .publisher(for: .showDigitalShow)) { object in
                    if let digitalObject = object.object as? DigitalShowObject {
                        self.digitalObject = digitalObject
                    }
            }
            .onReceive(NotificationCenter.default.publisher(for: .endDigitalShow)) { _ in
                DispatchQueue.main.async {
                    self.digitalObject = nil
                }
            }
    }
}

//
//  InAppMoveAssetSheet.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/17/25.
//

import SwiftUI
import Photos

struct InAppMoveAssetSheet: ViewModifier {
    let notificationName: Notification.Name
    @State var moveAssetObject: MoveAssetObject!
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: .constant(moveAssetObject != nil),
                   onDismiss: {
                DispatchQueue.main.async {
                    if let object = moveAssetObject {
                        NotificationCenter.default
                            .post(name: .assetWorkDone,
                                  object: object.currentAlbum.localIdentifier)
                    }
                }
                moveAssetObject = nil
            }) {
                if let object = moveAssetObject {
                    MoveAssetCategoryView(
                        isShowingSelectFolderSheet: .constant(false),
                        object: $moveAssetObject,
                        albumType: object.albumType,
                        currentAlbum: object.currentAlbum,
                        isHiddenAssets: object.isHidden,
                        isDetailView: object.isDetailView,
                        selectedItems: object.selectedItems,
                        selectedFolder: nil
                    )
                    .interactiveDismissDisabled()
                }
            }
            .onReceive(NotificationCenter.default
                .publisher(for: notificationName)) { object in
                    // 미디어 이동 시트
                    if let assetObject = object.object as? MoveAssetObject {
                        self.moveAssetObject = assetObject
                    }
            }
    }
}

#Preview {
    ContentView()
        .modifier(InAppMoveAssetSheet(notificationName: .showMoveAssetSheet,
                                      moveAssetObject: nil))
}

struct MoveAssetObject: Equatable {
    var albumType: AlbumType
    let currentAlbum: PHAssetCollection!
    let selectedItems: [MLAsset]
    var isHidden: Bool
    var isDetailView: Bool = false
}


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
                moveAssetObject = nil
                DispatchQueue.main.async {
                    NotificationCenter.default
                        .post(name: .endProgress, object: nil)

                }
            }) {
                MoveAssetCategoryView(
                    isShowingSelectFolderSheet: .constant(false),
                    object: $moveAssetObject,
                    albumType: moveAssetObject.albumType,
                    currentAlbum: moveAssetObject.currentAlbum,
                    isHiddenAssets: moveAssetObject.isHidden,
                    isDetailView: moveAssetObject.isDetailView,
                    selectedItems: moveAssetObject.selectedItems,
                    selectedFolder: nil
                )
            }
            .onReceive(NotificationCenter.default
                .publisher(for: notificationName)) { object in
                    // 미디어 이동 시트
                    print("step 4")
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


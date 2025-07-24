//
//  InAppSheetModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import SwiftUI
import Photos

struct InAppSheetModifier: ViewModifier {
    @EnvironmentObject var photoData: MLPhotoData
    // 2. 폴더/앨범 이동 시트
    @State var moveCollectionObject: MoveCollectionObject!
    // 3. 컬렉션 순서 조정 시트
    @State var reorderObject: ReorderObject!
    
    func body(content: Content) -> some View {
        content
        // MARK: - 2. Collection Move Sheet
            .sheet(isPresented: .constant(moveCollectionObject != nil),
                   onDismiss: {
                moveCollectionObject = nil
            }, content: {
                if let moveObject = moveCollectionObject {
                    MoveCollectionCategoryView(
                        moveObject: $moveCollectionObject,
                        currentParent: moveObject.currentParent,
                        objectCellType: moveObject.objectCellType,
                        objectAlbum: moveObject.objectAlbum,
                        objectFolder: moveObject.objectFolder,
                        nameSpace: moveObject.nameSpace)
                    .interactiveDismissDisabled()
                }
            })
            .onReceive(NotificationCenter.default
                .publisher(for: .showMoveCollectionSheet)) { object in
                    if let collecitonObject = object.object as? MoveCollectionObject {
                        self.moveCollectionObject = collecitonObject
                    }
                }
        // MARK: - 3. Collection ReOrderSheet
                .fullScreenCover(isPresented: .constant(reorderObject != nil),
                                 onDismiss: {
                    reorderObject = nil
                }, content: {
                    if let _ = reorderObject {
                        ReorderCategoriView(reorderObject: $reorderObject,
                                            pageIdentifier: reorderObject.localIdentifier)
                    }
                })
                .onReceive(NotificationCenter.default
                    .publisher(for: .showReorderSheet)) { object in
                        // 미디어 이동 시트
                        if let object = object.object as? ReorderObject {
                            DispatchQueue.main.async {
                                withAnimation {
                                    self.reorderObject = object
                                }
                            }
                        }
                    }
    }
}

struct MoveCollectionObject: Equatable {
    let currentParent: MLFolder
    let objectCellType: CellType
    let objectFolder: PHCollectionList!
    let objectAlbum: PHAssetCollection!
    let objectColorIndex: Int
    let objectIdentifier: String
    let nameSpace: Namespace.ID
}

struct ReorderObject: Equatable {
    let localIdentifier: String
}

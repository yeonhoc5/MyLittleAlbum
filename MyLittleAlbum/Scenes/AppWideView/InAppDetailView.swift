//
//  InAppDetailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/11/25.
//

import SwiftUI
import Photos

struct InAppDetailView: ViewModifier {
    @State var isShowingDetailView: Bool = false
    @State var detailViewObject: DetailViewObject!
    @State var indexToView: Int = 0
    @State var settingDone: Bool = false
    
    func body(content: Content) -> some View {
        content
//            .fullScreenCover(isPresented: .constant(detailViewObject != nil)) {
//                if let object = detailViewObject {
//                    PhotosDetailView(albumType: object.albumType,
//                                     assetCollection: object.assetCollection,
//                                     isHiddenAssets: object.isHiddenAsset,
//                                     filteringType: object.filteringType,
//                                     belongingType: object.belongingType,
//                                     tempImage: object.image,
//                                     identifier: object.identifier,
//                                     indexToView: $indexToView,
//                                     isExpanded: .constant(detailViewObject != nil),
//                                     animationID: object.nameSpace)
//                    .modifier(
//                        InAppAlertModifier(notificationName: .showAlertInDetailView)
//                    )
//                    .modifier(
//                        InAppMoveAssetSheet(notificationName: .showMoveAssetSheetInDetailView))
//                    .modifier(
//                        InAppProgressView(notificationName: .showProgressingDetailView)
//                    )
//                }
//            }
            .onReceive(NotificationCenter.default.publisher(for: .showDetailView),
                       perform: { output in
                if let object = output.object as? DetailViewObject {
                    self.indexToView = object.indexToView
                    print(object.assetCollection?.localizedTitle ?? "")
                    DispatchQueue.main.async {
                        withAnimation {
                            self.detailViewObject = object
                        }
                    }
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: .endDetailView),
                       perform: { object in
                if let indexTo = object.object as? Int {
                    self.indexToView = indexTo
                    DispatchQueue.main.async {
                        withAnimation {
                            self.detailViewObject = nil
                        }
                    }
                }
            })
    }
}

#Preview {
    ContentView()
        .modifier(InAppDetailView(detailViewObject: nil))
}


struct DetailViewObject {
    let albumType: AlbumType
    let assetCollection: PHAssetCollection!
    let filteringType: FilteringType
    let belongingType: BelongingType
    let isHiddenAsset: Bool
    let indexToView: Int
    let image: UIImage!
    let identifier: String
    let nameSpace: Namespace.ID
}

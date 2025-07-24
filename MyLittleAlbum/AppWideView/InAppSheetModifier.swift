//
//  InAppSheetModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import SwiftUI

struct InAppSheetModifier: ViewModifier {
    @State var showSheet: Bool = false
    @State var album: Album!
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showSheet) {
                MoveAssetCategoryView(
                    isShowingSheet: $showSheet,
                    isShowingSelectFolderSheet: .constant(false),
                    stateChangeObject: StateChangeObject(),
                    albumType: .album,
                    currentAlbum: self.album,
                    isHiddenAssets: false,
                    selectedItemsIndex: .constant([]),
                    isSelectMode: .constant(true))
            }
            .onReceive(NotificationCenter.default.publisher(for: .showSecondSheet)) { object in
                self.album = object.object as? Album
                self.showSheet = true
            }
    }
}

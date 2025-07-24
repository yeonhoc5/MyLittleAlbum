//
//  EditAlert.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 10/30/24.
//

import Foundation
import SwiftUI
import Photos

enum AlertCase {
    // 1. before Action
        // - needs textfield
    case addAlbumToFolder
    case addFolderToFolder
    case albumNameChange
    case folderNameChange
        // - only message
    case mediaTakeFromAlbum
    case mediaUnhide
    // 2. after Action
    case mediaMoved
    case none
    // 3. ios 자체 수행
//    case mediaDelete
//    case mediaHide
}

struct EditAlert {
    let alertCase: AlertCase
    let title: String
    let message: String
    var needsTextField: Bool = false
    let placeHolder: String
    let buttonDonetitle: String
    let album: MLAlbum!
    let folder: MLFolder!
    var isHiddenAsset: Bool! = false
    var selectedItems: [MLAsset] = []
    var isDetailView: Bool = false
}

struct AlertObject {
    let alertCase: AlertCase
    var albumType: AlbumType!
    let album: PHAssetCollection!
    let folder: PHCollectionList!
    var selectedItems: [MLAsset] = []
    var needsTextField: Bool! = false
    var isHiddenAsset: Bool! = false
    var isDetailView: Bool! = false
}

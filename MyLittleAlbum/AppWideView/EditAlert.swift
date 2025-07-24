//
//  EditAlert.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 10/30/24.
//

import Foundation
import SwiftUI

enum AlertCase {
    // 1. before Action
        // - needs textfield
    case addAlbumCurrent
    case addFolderCurrent
    case addAlbumSecondary
    case addFolderSecondary
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
    let album: Album!
    let folder: Folder!
}

struct AlertObject {
    let alertCase: AlertCase
    let album: Album!
    let folder: Folder!
    let count: Int!
    var needsTextField: Bool = false
}

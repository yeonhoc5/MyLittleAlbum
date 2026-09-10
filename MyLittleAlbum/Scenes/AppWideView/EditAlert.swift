//
//  EditAlert.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 10/30/24.
//

import Foundation
import SwiftUI
import Photos

// CollectionAlert & AssetAlert Enum

enum CollectionAlertCase {
// 1. before Action
// 1-1. needs textField
  case addAlbumToFolder
  case addFolderToFolder
  case albumNameChange
  case folderNameChange
// 1-2. no Needs textFiled
  case delShareCategory
// 2. ios 자체 수행
//    case mediaDelete
//    case mediaHide
}

struct EditAlert: Equatable {
  let alertCase: CollectionAlertCase
  let title: String
  let message: String
  let placeHolder: String
  let buttonDonetitle: String
  var album: MLAlbum! = nil
  var folder: MLFolder! = nil
  var parent: String = ""
}

struct AlertObject: Equatable {
  let alertCase: CollectionAlertCase
  var folderType: FolderType = .userFolder
  var albumType: AlbumType!
  let albumID: String!
  let folderID: String!
  var title: String = ""
  var parent: String = ""
}

enum AssetAlertCase {
  case unHide, subtract
//  case hide, delete            // (device self-alert)
//  case favorite, unFavorite    // (non alert)
}

struct AssetAlert {
  let alertCase: AssetAlertCase
  let assets: [MLAsset]
  let album: MLAlbum
  let isHiddenAsset: Bool
  
  static func title(alert: Self!) -> String {
    switch alert?.alertCase {
    case .unHide: "선택한 항목의 가리기를 해제합니다."
    case .subtract: "선택한 항목을 이 앨범에서 제거합니다."
    default: "unknown"
    }
  }
}

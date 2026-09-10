//
//  GlobalProperties.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/4/24.
//

import UIKit
import LocalAuthentication

var device: UIUserInterfaceIdiom {
    return UIDevice.current.userInterfaceIdiom
}

var screenSize: CGSize {
    get {
        guard let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.bounds.size else { return .zero }
        return size
    }
}
var screenWidth: CGFloat {
    return device == .phone
    ? min(screenSize.width, screenSize.height)
    : screenSize.width
}


var scale: CGFloat = {
    return UITraitCollection.current.displayScale
}()

let emptyLabel: [String] = ["텅", "휘이잉~", "Zero", "조용...", "비움",
                            "깨끗", "nothing", "또르르", "empty", "없을 무",
                            "free", "공허", "blank", "0"]

let refreshPhotos: [String] = ["refreshPhoto01", "refreshPhoto02",
                               "refreshPhoto03", "refreshPhoto05",
                               "refreshPhoto06", "refreshPhoto07"]

let transitionRange: [Int] = [
    3, 4, 5, 6, 7, 8, 9, 10, 20, 30 , 40 , 50, 60, //초
    120, 180, 240, 300, 600, 1200, 1800, // 분
    3600, 7200, 10800, 21600, 43200, 86400 // 시간~1일
]

enum UserDefaultsKey: String {
  case existingUser
  case startView
  case uimode
  case useOpeningAni
  case useKnock
  case transitionIndex
  case digitalShowRandom
  case userReadDone
  case recentAlbums
  case recentFolders
  case recentCategoris
}

let tabbarHeight: CGFloat = 80.0
let tabbarTopPadding: CGFloat = 10.0
var tabbarBottomPadding: CGFloat {
    get {
        if device == .pad {
            return 16.5 + 10
        } else {
            if #available(iOS 26.0, *) {
                return 16.5
            } else {
                return 0
            }
        }
    }
}

extension UIApplication {
  static var safeAreaInsets: UIEdgeInsets {
    let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    return scene?.windows.first?.safeAreaInsets ?? .zero
  }
}
//var safeAreaBottom : CGFloat = {
//  return UIApplication.safeAreaInsets.bottom
//}()
let ipadBottomPadding: CGFloat = 20.0

var navigationbarHeight: CGFloat = {
    let controller = UINavigationController()
    return controller.navigationBar.frame.height
}()
var statusBarHeight: CGFloat = {
  return (UIApplication.shared.connectedScenes.first as? UIWindowScene)
      .flatMap { $0.statusBarManager }
      .flatMap { $0.statusBarFrame.height }!
}()
//let statusBarHeight: CGFloat = (UIApplication.shared.connectedScenes.first as? UIWindowScene)
//    .flatMap { $0.statusBarManager }
//    .flatMap { $0.statusBarFrame.height }!
var safeAreaTopPadding: CGFloat = {
  return navigationbarHeight + statusBarHeight
}()

let widthLimit: CGFloat = 600


func operatedArray(array: [MLAsset],
                   setOperation: SetOpertation,
                   assets: [MLAsset]) -> [MLAsset] {
  var set = Set(array)
  switch setOperation {
  case .union: set = set.union(Set(assets))
  case .intersection: set = set.intersection(Set(assets))
  case .subtraction: set = set.subtracting(Set(assets))
  }
  return Array(set)
}

// 앨범 / 폴더 컨텐츠 레이아웃

let normalPadding: CGFloat = 7
let miniPadding: CGFloat = 5
var listCount: Int {
    return device == .phone 
    ? 3 : (screenSize.width > screenSize.height ? 9 : 6)
}
enum CellCountType {
    case big, middle1, middel2, small
}
func cellCount(type: CellCountType) -> Int {
    switch type {
    case .big:
        return 10
    case .middle1:
        return 8
    case .middel2:
        return 6
    case .small:
        return 5
    }
}

func cellHeight(width: CGFloat, uiMode: UIMode, cellType: CellType) -> CGFloat {
    var ratio: CGFloat
    if cellType == .album {
        switch uiMode {
        case .classic: ratio = 1
        case .modern: ratio = 1.3
        case .fancy: ratio = 1.15
        }
    } else {
        switch uiMode {
        case .classic: ratio = 1.1
        case .modern: ratio = 1.21
        case .fancy: ratio = 1.12
        }
    }
    return width * ratio
}
func creteriaResult(screenSize: CGSize, size: CGSize) -> Creteria {
  let assetRatio = size.height / size.width
  let screenRatio = screenSize.height / screenSize.width
  return assetRatio <= screenRatio ? .width : .height
}


// MARK: - 디테일뷰
let detailViewContentSize = screenSize.height - statusBarHeight
// VideoController
let vcHeight: CGFloat = device == .pad ? 60 : 45
let vcHorisontalPadding: CGFloat = 15
let vcBottomPadding: CGFloat = 35

let adsRegionSpacing: CGFloat = 110

// MARK: - 아이콘
// 0. tabbar
let iconPhotos = "photo.on.rectangle"
let iconAlbum = "character.book.closed"
let iconSmart = "list.bullet"
let iconPhotosSelected = "photo.on.rectangle.angled"
let iconAlbumSelected = "book.fill"
let iconSmartSelected = "list.star"

// 1. asset
let iconHide = "eye.slash.fill"
let iconUnhide = "eye.fill"
let iconFavorite = "star.fill"
let iconNotFavorite = "star"
let iconUnfavorite = "star.slash.fill"
let iconSubtract = "rectangle.stack.badge.minus"
    
let iconLocked = "lock.fill"
let iconUnLocked = "lock.open.fill"

// collectionView
let iconSetting = "gearshape.fill"
let iconFolderSetting = "folder.fill.badge.gearshape"

// media detailView
let iconDelete = "trash"
let iconInsertToAlbum = "rectangle.stack.badge.plus"

let iconImage = "photo.fill"
let iconVideo = "video.fill"

let iconTrash = "trash"

let iconModify = "square.and.pencil"
let iconAddFolder = "folder.fill.badge.plus"
let iconAddAlbum = "rectangle.stack.fill.badge.plus"
let iconReorder = "arrow.up.arrow.down"
let iconMoveToOtherFolder = "rectangle.portrait.and.arrow.forward.fill"
let iconEraser = if #available(iOS 26.0, *) {
  "eraser.badge.xmark.fill"
} else {
  "eraser.fill"
}
let syncSymbol: String = if #available(iOS 18, *) {
  "arrow.trianglehead.2.clockwise.rotate.90"
} else {
  "arrow.triangle.2.circlepath"
}

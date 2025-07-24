//
//  GlobalProperties.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/4/24.
//

import UIKit
import SwiftUI
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
//var screenWidth: CGFloat {
//    return device == .phone
//    ? min(screenSize.width, screenSize.height)
//    : screenSize.width
//}


var scale: CGFloat = {
    guard let scale = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.scale else { return .zero }
    return scale
}()


let colorSet: [Color] = [.color1, .color2, .color3, .color4, .color5,
                         .color6, .color7, .color8, .color9, .color10,
                         .color11, .color12, .color13, .color14, .color15,
                         .color16, .color17, .color18, .color19, .color20,
                         .color21, .color22, .color23, .color24, .color25,
                         .color26, .color27, .color28]

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
    case startView
    case uimode
    case useOpeningAni
    case useKnock
    case transitionIndex
    case digitalShowRandom
    case userReadDone
    case recentAlbums
    case recentFolders
}

let tabbarHeight: CGFloat = 80.0
let tabbarTopPadding: CGFloat = 10.0
let tabbarBottomPadding: CGFloat = device == .phone ? 0 : 30.0

let statusBarHeight: CGFloat = (UIApplication.shared.connectedScenes.first as? UIWindowScene)
    .flatMap { $0.statusBarManager }
    .flatMap { $0.statusBarFrame.height }!

var safeAraBottom: CGFloat? = {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)
        .flatMap { $0.windows.first }
        .flatMap { $0.safeAreaInsets.bottom }
}()

var navigationbarHeight: CGFloat = {
    let controller = UINavigationController()
    return controller.navigationBar.frame.height
}()

let widthLimit: CGFloat = 600


// 앨범 / 폴더 컨텐츠 레이아웃
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


// MARK: - 디테일뷰
let detailViewContentSize = screenSize.height - statusBarHeight
// VideoController
let vcHeight: CGFloat = 40
let vcHorisontalPadding: CGFloat = 15
let vcBottomPadding: CGFloat = 30



// MARK: - 아이콘
let iconHide = "eye.slash.fill"
let iconUnhide = "eye.fill"

let iconFavorite = "heart.fill"
let iconNotFavorite = "heart"
let iconUnfavorite = "heart.slash.fill"

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

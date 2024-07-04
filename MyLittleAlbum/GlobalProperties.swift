//
//  GlobalProperties.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/4/24.
//

import UIKit
import SwiftUI

var device: UIUserInterfaceIdiom {
    return UIDevice.current.userInterfaceIdiom
}

var screenSize: CGSize {
    get {
        guard let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.bounds.size else { return .zero }
        return size
    }
}

var scale: CGFloat {
    guard let scale = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.scale else { return .zero }
    return scale
}

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
    case uimode
    case useOpeningAni
    case useKnock
    case transitionIndex
    case userReadDone
}

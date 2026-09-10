//
//  EnumList.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import Foundation


// ui 체인지용
enum UIMode: String, Identifiable, CaseIterable {
    var id: Int { return self.hashValue }
    
    case classic, modern, fancy
    
    enum Axis {
        case horizontal, vertical
    }
    
    static func axis(uiMode: UIMode) -> Axis {
        switch uiMode {
        case .classic:
            return .vertical
        case .modern, .fancy:
            return .horizontal
        }
    }
}

enum SampleCase: Int {
    case none
    case overTwo
    case one
    case zero
    
    
    static func returnType(int: Int) -> Self {
        switch int {
        case 2: return .overTwo
        case 1: return .one
        case 0: return .zero
        default: return .none
        }
    }
    func returnCount() -> Int {
        switch self {
        case .overTwo:
            return 2
        case .one:
            return 1
        case .zero:
            return 0
        case .none:
            return -1
        }
    }
}

// 탭바용
enum Tabs: String, CaseIterable, Identifiable {
    var id: Self { self }
    
//    case photo = "나의 포토"
    case album = "나의 앨범"
//    case other = "사진 관리"
    case share = "공유 앨범"
}

// cell별 ui 구분
enum CellType {
    case folder, album, miniAlbum
}
// ui 라이트 모드 구분용
enum LightMode: String, CaseIterable {
    case fixedLight, fixedDark, system
}
// 알럿 내용 구분용1
enum PressedType {
    case none, album, folder
}
// 알럿 내용 구분용2
enum CollectionType: CaseIterable {
    case album, folder, none
}
// 알럿 내용 구분용3
enum DepthType {
    case none, current, secondary
}

enum EditType {
    case none, add, modify, remove
}

enum DeleteType {
    case folder, album
}

enum ButtonSize {
    case big, half, medium, mini
}

enum ImageSize {
    case cellSize, PreviewSize, DetailViewSize
}


enum AlbumType {
    case home, album, share, picker
}

enum SmartType {
    case none, trashCan, hiddenAsset, favorite
}

enum EdgeToScroll {
    case top, bottom, none, number
}

enum NewToScroll {
    case currentAlbum, currenFolder, secondaryAlbum, secondaryFolder
}


enum SwipingSelectMode {
    case add, subtract, none
}

//
//  EnumList.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import Foundation


// ui 체인지용
enum UIMode: String, CaseIterable {
    case classic, modern, fancy
}
enum SampleCase {
    case overTwo, one, none
}

// 탭바용
enum Tabs: String, CaseIterable {
    case photo, album, smart
}
// 커스텀 네비게이션용
enum TypeView {
    case photo, album, other
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
enum CollectionType {
    case none, album, folder
}
// 알럿 내용 구분용3
enum DepthType {
    case none, current, secondary
}

enum EditType {
    case none, add, modify
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
    case home, album, smartAlbum, picker
}

enum SmartAlbum {
    case none, trashCan, hiddenAsset
}

enum EdgeToScroll {
    case top, bottom, none
}

enum NewToScroll {
    case currentAlbum, currenFolder, secondaryAlbum, secondaryFolder
}


enum SwipingSelectMode {
    case add, subtract, none
}

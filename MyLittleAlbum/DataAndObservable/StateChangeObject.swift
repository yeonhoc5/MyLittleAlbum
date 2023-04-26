//
//  StateChangeObject.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/19.
//

import Foundation
import Photos


class StateChangeObject: ObservableObject {
    
    
    @Published var pageFolder: Folder!
    
    // 폴더/앨범 지우기 모드
    @Published var isEditingMode: Bool = false
    // 폴더/앨범 추가/이름변경 알럿
    @Published var isShowingAlert: Bool = false
    // 폴더/앨범 다른 폴더로 이동 시트
    @Published var isShowingSheet: Bool = false
    // 폴더 / 앨범 순서 조정 시트
    @Published var isShowingReoderSheet: Bool = false
    // 포토 피커
    @Published var isShowingPhotosPicker: Bool = false
    // 폴더 편집 context menu
    @Published var isShowingMenu: Bool = false
    
    // 앨범/폴더 추가시 애니메이션
    @Published var isAlbumAdded: Bool = false
    @Published var isFolderAdded: Bool = false
    
    
    @Published var depthType: DepthType = .none
    @Published var pressedType: PressedType = .none
    @Published var collectionType: CollectionType = .none
    @Published var editType: EditType = .none
    @Published var collectionToEdit: PHCollection!
    
    
    // 콜렉션뷰 용 프라퍼티
    // 사진 추가/삭제시 / 필터 change시 전체 리로드
    @Published var filteringChanged: Bool = false
    @Published var isPhotosMoved: Bool = false
//    @Published var photosFilterChanged: Bool = false
    
    @Published var isTabbarHidden: Bool = false
    @Published var isSlideShowEnded: Bool = false
    
//    @Published var typeFilterChanged: Bool = false
    @Published var photosEdited: Bool = false
    
    @Published var selectToggleAllPhotos: Bool = false
    @Published var selectToggleSomePhotos: Bool = false
    
    @Published var scrollToFirst: Bool = false
    @Published var assetRemoving: Bool = false
    
    @Published var newName: String = ""
    @Published var selectedIndexes: [Int] = []
 
    
    @Published var showPickerButton: Bool = false
    
    @Published var tabBarbtnScroll: Bool = false
    
}


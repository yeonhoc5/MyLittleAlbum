//
//  PhotoMenu.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
import PhotosUI

enum LabelType {
    case text, image
}

enum FilteringType {
    case video, image, all
}
enum BelongingType {
    case nonAlbum, album, all
}

struct PhotosGridMenu: View {
    @EnvironmentObject var photoData: PhotoData
    @StateObject var stateChangeObject: StateChangeObject
    
    var albumType: AlbumType = .album
    var album: Album! 
    var smartAlbumType: SmartAlbum = .none
    
    @Binding var settingDone: Bool!
    @Binding var belongingType: BelongingType
    @Binding var filteringType: FilteringType

    
    @Binding var isSelectMode: Bool
    @Binding var selectedItemsIndex: [Int]
    @Binding var edgeToScroll: EdgeToScroll
    @State var isSelectedAll: Bool = false
    
//    @Binding var isShowingAlert: Bool
//    @Binding var editType: EditType
    @Binding var isShowingSheet: Bool
    
    @Binding var isShowingShareSheet: Bool
    
    let width = (min(screenSize.width, screenSize.height) - 19) / 10
    let spacing: CGFloat = 8
    let opacity: CGFloat = 0.8
    
    var body: some View {
        switch albumType {
        case .home: homeStack
        case .album: albumStack
        case .smartAlbum: smartAlbumStack
        default: pickerStack
        }
    }
}

// 모드에 따라 뷰 구분
extension PhotosGridMenu {
    // 1. home 스택
    var homeStack: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            VStack(spacing: spacing) {
                if isSelectMode {
                    btnDelete()
                } else {
                    btnFilter()
                }
            }
            VStack(spacing: spacing) {
                centerMenuBar
                HStack(alignment: .center, spacing: spacing) {
                    if isSelectMode {
                        btnHidden(btnSize: .half)
                        btnMove(btnSize: .half)
                    } else {
                        btnPhotos(btnSize: .medium)
                        btnScrollToEdge(btnSize: .medium, edge: .bottom)
                        btnScrollToEdge(btnSize: .medium, edge: .top)
                    }
                }
            }
            VStack(spacing: spacing) {
                btnTransSelectMode()
            }
        }
    }
    // 2. album 스택
    var albumStack: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            VStack(spacing: spacing) {
                if isSelectMode {
                    btnDelete()
                } else {
                    btnFilter()
                }
            }
            VStack(spacing: spacing) {
                centerMenuBar
                HStack(alignment: .center, spacing: spacing) {
                    if isSelectMode {
                        btnHidden(btnSize: .medium)
                        btnTakeFrom(btnSize: .medium)
                        btnMove(btnSize: .medium)
                    } else {
                        btnModifyTitle(btnSize: .medium)
                        btnScrollToEdge(btnSize: .medium, edge: .bottom)
                        btnScrollToEdge(btnSize: .medium, edge: .top)
                    }
                }
            }
            VStack(spacing: spacing) {
                if isSelectMode {
                    btnSelectAll
                }
                btnTransSelectMode()
            }
        }
    }
    // 3. smartAlbum 스택
    var smartAlbumStack: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            VStack(spacing: spacing) {
                if isSelectMode {
                    if smartAlbumType == .trashCan {
                        colorBar(opacity: 0)
                            .frame(width: width * 1.2)
                    } else {
                        btnDelete()
                    }
                } else {
                    btnFilter()
                }
            }
            VStack(spacing: spacing) {
                centerMenuBar
                HStack(alignment: .center, spacing: spacing) {
                    if isSelectMode {
                        if smartAlbumType == .hiddenAsset {
                            btnUnHide(btnSize: .big)
                        }
                    } else {
                        btnScrollToEdge(btnSize: .half, edge: .bottom)
                        btnScrollToEdge(btnSize: .half, edge: .top)
                    }
                }
            }
            VStack(spacing: spacing) {
                if smartAlbumType == .trashCan {
                    colorBar(opacity: 0)
                        .frame(width: width * 1.2)
                } else {
                    if isSelectMode {
                        btnSelectAll
                    }
                    btnTransSelectMode()
                }
            }
        }
    }
    // 4. picker 스택
    var pickerStack: some View {
        HStack(alignment: .top) {
            btnFilter()
            btnPhotos(btnSize: .medium)
            btnScrollToEdge(btnSize: .medium, edge: .bottom)
            btnScrollToEdge(btnSize: .medium, edge: .top)
        }
    }
}


// MARK: - 포토 그리드 공통 버튼
extension PhotosGridMenu {
    
    // 가운데 라벨바
    var centerMenuBar: some View {
        let imageText = "사진 : \(album.countOfImage)"
        let videoText = "동영상 : \(album.countOfVidoe)"
        let selecteModeText = "\(selectedItemsIndex.count)개의 항목 선택됨"
        return ZStack(alignment: .center) {
            colorBar()
            if isSelectMode {
                Text(selecteModeText)
                    .foregroundColor(.primaryColorInvert)
            } else {
                Text(imageText)
                    .foregroundColor(filteringType == .image ? .blue : .primaryColorInvert)
                + Text(" / ")
                    .foregroundColor(.primaryColorInvert)
                + Text(videoText)
                    .foregroundColor(filteringType == .video ? .blue : .primaryColorInvert)
            }
        }
        .font(.system(.subheadline, design: .rounded, weight: .medium))
        .frame(width: width * 7, height: width)
    }
    // 선택 모드 토글 버튼
    func btnTransSelectMode(btnSize: ButtonSize! = .mini) -> some View {
        let text = isSelectMode ? "취소" : "선택"
        return menuButton(btnSize: btnSize, type: .text, text: text) {
            isSelectMode.toggle()
            if !isSelectMode {
                if isSelectedAll {
                    stateChangeObject.selectToggleAllPhotos = true
                    selectedItemsIndex.removeAll()
                } else if selectedItemsIndex.count != 0 {
                    stateChangeObject.selectToggleSomePhotos = true
                }
                isSelectedAll = false
                stateChangeObject.showPickerButton = true
            } else {
                stateChangeObject.showPickerButton = true
            }
        }
    }
    // 전체 선택 / 해제 버튼
    var btnSelectAll: some View {
        let text = isSelectedAll ? "전체\n해제" : "전체\n선택"
        return menuButton(btnSize: .mini, type: .text, text: text) {
            stateChangeObject.selectToggleAllPhotos = true
            isSelectedAll.toggle()
            
            var count: Int
            switch album.filteringType {
            case .all: count = album.count
            case .image: count = album.countOfImage
            case .video: count = album.countOfVidoe
            }
            
            if isSelectedAll {
                selectedItemsIndex.removeAll()
                selectedItemsIndex.append(contentsOf: 0..<count)
            } else {
                selectedItemsIndex.removeAll()
            }
        }
        .onChange(of: selectedItemsIndex.count) { newValue in
            var count: Int
            switch album.filteringType {
            case .all: count = album.count
            case .image: count = album.countOfImage
            case .video: count = album.countOfVidoe
            }
            if selectedItemsIndex.count != count {
                isSelectedAll = false
            } else {
                isSelectedAll = true
            }
        }
    }
    // 스크롤 버튼
    func btnScrollToEdge(btnSize: ButtonSize! = .medium, edge: Edge) -> some View {
        let image = edge == .top ? "chevron.left.to.line" : "chevron.right.to.line"
        return menuButton(btnSize: btnSize, type: .image, image: image, rotate: .pi/2) {
            switch edge {
            case .top:
                withAnimation(.interactiveSpring()) {
                    edgeToScroll = .top
                }
            default:
                withAnimation(.interactiveSpring()) {
                    edgeToScroll = .bottom
                }
            }
            
        }
    }
    // home에서 사진함 선택
    func btnPhotos(btnSize: ButtonSize! = .mini) -> some View {
        let text = belongingType == .all ? "모든 사진함" : (belongingType == .album ? "앨범있는 사진함" : "앨범없는 사진함")
        return Menu {
            photoMenu
        } label: {
            menuButton(btnSize: btnSize, type: .text, text: text, color: .blue) {
            }
            .fontWeight(.bold)
        }
        
    }
    
    // 필터링
    func btnFilter(btnSize: ButtonSize! = .mini) -> some View {
        var image = ""
        switch filteringType {
        case .image: image = "photo.fill"
        case .video: image = "video.fill"
        default: image = "line.3.horizontal.decrease"
        }
        return Menu {
            filteringMenu
        } label: {
            menuButton(btnSize: btnSize,
                       type: .image,
                       image: image,
                       color: filteringType == .all ? .primaryColorInvert : .blue) {
            }
        }
    }
    var filteringMenu: some View {
        VStack {
            Button {
                changeFiltering(type: .all, albumChange: false)
                print("전체로 바꾼다")
            } label: {
                if filteringType == .all {
                    ContextMenuItem(title: "모두 보기", image: "checkmark")
                } else {
                    ContextMenuItem(title: "모두 보기")
                }
            }
            Button {
                changeFiltering(type: .image, albumChange: false)
                print("사진으로 바꾼다")
            } label: {
                ContextMenuItem(title: "사진만 보기", image: filteringType == .image ? "checkmark":"photo.fill")
            }
            Button {
                changeFiltering(type: .video, albumChange: false)
                print("비디오로 바꾼다")
            } label: {
                ContextMenuItem(title: "비디오만 보기", image: filteringType == .video ? "checkmark":"video.fill")
            }
        }
    }
    
    // 정렬
    func btnRearrange(btnSize: ButtonSize! = .mini) -> some View {
        Menu {
            reArrangeMenu
        } label: {
            menuButton(btnSize: btnSize, type: .image, image: "arrow.up.arrow.down") {
                
            }
        }
    }
    var reArrangeMenu: some View {
        VStack {
            Button {
            } label: {
                ContextMenuItem(title: "사용자 정의 순으로 보기(기본)")
            }
            Button {
                
            } label: {
                ContextMenuItem(title: "최신 항목부터 보기")
            }
            Button {

            } label: {
                ContextMenuItem(title: "오래된 항목부터 보기")
            }
        }
    }
    // 앨범명 수정
    func btnModifyTitle(btnSize: ButtonSize! = .mini) -> some View {
        menuButton(btnSize: btnSize, type: .text, text: "앨범명 수정") {
            stateChangeObject.editType = .modify
            stateChangeObject.isShowingAlert = true
        }
    }
    
    var photoMenu: some View {
        VStack {
            Button {
                if belongingType != .nonAlbum {
                    withAnimation(.interactiveSpring()) {
                        belongingType = .nonAlbum
                        changeFiltering(type: .all)
                    }
                    withAnimation {
                        settingDone = false
                    }
                }
            } label: {
                ContextMenuItem(title: "앨범에 없는 항목만 보기",
                                image: belongingType == .nonAlbum ? "checkmark" : "",
                                color: belongingType == .nonAlbum ? .blue : .primary)
            }
            Button {
                if belongingType != .album {
                    withAnimation(.interactiveSpring()) {
                        belongingType = .album
                        changeFiltering(type: .all)
                    }
                    withAnimation {
                        settingDone = false
                    }
                }
            } label: {
                ContextMenuItem(title: "앨범에 있는 항목만 보기",
                                image: belongingType == .album ? "checkmark" : "",
                                color: belongingType == .nonAlbum ? .blue : .primary)
            }
            Button {
                if belongingType != .all {
                    withAnimation(.interactiveSpring()) {
                        belongingType = .all
                        changeFiltering(type: .all)
                    }
                    withAnimation {
                        settingDone = false
                    }
                }
            } label: {
                ContextMenuItem(title: "모두 보기",
                                image: belongingType == .all ? "checkmark" : "",
                                color: belongingType == .nonAlbum ? .blue : .primary)
            }
        }
    }
    
    func changeFiltering(type: FilteringType, albumChange: Bool! = true) {
        if self.filteringType != type {
            DispatchQueue.main.async {
                album.changeFiltering(type: type)
                self.filteringType = type
                if !albumChange {
                    stateChangeObject.allPhotosChanged = true
                }
            }
        }
    }
    
}

//MARK: - 선택한 사진 처리 버튼 정의
extension PhotosGridMenu {
    // 삭제
    func btnDelete(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.red
        let count = selectedItemsIndex.count
        let tempFilteringType = self.filteringType
        let tempSelectedItems = self.selectedItemsIndex
        return menuButton(btnSize: btnSize, type: .image, image: "trash", color: color, disabled: count == 0) {
            deleteAsset(indexSet: selectedItemsIndex, filter: tempFilteringType, selected: tempSelectedItems)
        }
    }
    // 앨범에서 빼기
    func btnTakeFrom(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, type: .text, text: "앨범에서 빼기", color: color, disabled: count == 0) {
            stateChangeObject.editType = .add
            stateChangeObject.isShowingAlert = true
        }
    }
    
    // 공유 버튼
    func btnShare(btnSize: ButtonSize! = .mini) -> some View {
        ShareLink(items: assetsToShare(indexSet: selectedItemsIndex.sorted{ $0 < $1 })) { items in
            SharePreview(items.caption, image: items.image)
        } label: {
            let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
            buttonLabel(btnSize: btnSize, type: .text, text: "공유하기", font: .caption, color: color)
        }
        .disabled(selectedItemsIndex.count == 0)
    }
    // 복구 버튼
    func btnRestore(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, type: .text, text: "복구하기", color: color, disabled: count == 0) {
            PHPhotoLibrary.shared().performChanges {
                
            }
        }
    }
    
    func assetsToShare(indexSet: [Int])  -> [Photo] {
        let assetsToShare: [Photo] = []
//        let imageManager = PHImageManager.default()
//        for i in indexSet {
//            let photo = allPhotos[i]
//            let resource = PHAssetResource.assetResources(for: photo)
//            let fileName = resource.first?.originalFilename
//            let options = PHImageRequestOptions()
//            options.isSynchronous = true
//            options.resizeMode = .none
//            getURL(ofPhotoWith: photo) { responseURL in
//                guard let url = responseURL?.absoluteURL else { return }
//                print(url)
//                imageManager.requestImage(for: photo, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options) { asset, info in
//                    if let asset = asset {
//                        let photoAsset = Photo(image: Image(uiImage: asset), caption: fileName ?? "", url: url )
//                        assetsToShare.append(photoAsset)
//                    }
//                }
//                print("공유하려는 사진 info: \(assetsToShare.count)")
//            }
//        }
//        print(assetsToShare.count)
        return assetsToShare
    }
    
    
    // 앨범에 넣기 / 다른 앨범으로 이동 (둘 모두 시트에서 처리)
    func btnMove(btnSize: ButtonSize! = .mini) -> some View {
        let text = albumType == .home ? "앨범에 넣기" : "다른 앨범으로\n이동하기"
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, type: .text, text: text, color: color, disabled: count == 0) {
            isShowingSheet = true
        }
        .disabled(selectedItemsIndex.count == 0)
    }
    // 가리기
    func btnHidden(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, type: .text, text: "가리기", color: color, disabled: count == 0) {
            hiddenAsset(indexSet: selectedItemsIndex)
        }
    }
    // 가리기 해제
    func btnUnHide(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, type: .text, text: "가리기 해제", color: color, disabled: count == 0) {
            unHideAsset(indexSet: selectedItemsIndex)
        }
    }
    
}

//MARK: - 사진 처리 함수
extension PhotosGridMenu {
    
    // 앨범에서 빼기 - 경고창을 위해 grid 뷰에서 처리
    
    // 기기에서 삭제
    func deleteAsset(indexSet: [Int], filter: FilteringType, selected: [Int]) {
        album.deleteAssetFromDevice(indexSet: indexSet, stateObject: stateChangeObject)
    }
    
    // 사진 가리기
    func hiddenAsset(indexSet: [Int]) {
        album.hideAsset(indexSet: indexSet, stateObject: stateChangeObject)
    }
    
    func unHideAsset(indexSet: [Int]) {
        album.unHideAsset(indexSet: indexSet, stateObject: stateChangeObject)
    }
    
    func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
           
           if mPhasset.mediaType == .image {
               let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
               options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                   return true
               }
               mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                   completionHandler(contentEditingInput!.fullSizeImageURL)
               })
           } else if mPhasset.mediaType == .video {
               let options: PHVideoRequestOptions = PHVideoRequestOptions()
               options.version = .current
               options.isNetworkAccessAllowed = true
               PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
                   if let urlAsset = asset as? AVURLAsset {
                       let localVideoUrl = urlAsset.url
                       completionHandler(localVideoUrl)
                   } else {
                       completionHandler(nil)
                   }
               })
           }
           
       }
    
}

// MARK: - 버튼 레이아웃
extension PhotosGridMenu {
    // 공용 백그라운드 바
    func colorBar(opacity: CGFloat! = 0.9) -> some View {
        Color.primary.opacity(opacity)
            .cornerRadius(width / 2)
    }
    
    func menuButton(btnSize: ButtonSize, type: LabelType, text: String! = "", image: String! = "", rotate: Double! = 0.0,
                    font: Font! = .caption, color: Color! = .primaryColorInvert,
                    disabled: Bool! = false,
                    action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            buttonLabel(btnSize: btnSize , type: type, text: text, image: image, rotate: rotate, font: font, color: color, disabled: disabled)
        }
        .disabled(disabled)
        .buttonStyle(ClickScaleEffect(scale: 0.95))
    }
    
    func buttonLabel(btnSize: ButtonSize, type: LabelType, text: String! = "", image: String! = "", rotate: Double! = 0.0,
                      font: Font! = .caption, color: Color! = .primaryColorInvert,
                      disabled: Bool! = false) -> some View {
        let resultWidth: CGFloat!
        switch btnSize {
        case .big: resultWidth = self.width * 7
        case .half: resultWidth = (self.width * 7/2) - ((self.spacing) / 2)
        case .medium: resultWidth = (self.width * 7/3)-(2 * (self.spacing) / 3)
        default: resultWidth = width * 1.2
        }
        return ZStack(alignment: .center) {
            colorBar()
            switch type {
            case .text:
                Text(text)
                    .font(font)
                    .multilineTextAlignment(.center)
            case .image:
                imageWithScale(systemName: image)
                    .imageScale(.medium)
                    .rotationEffect(.radians(rotate))
            }
        }
        .foregroundColor(color)
        .frame(width: resultWidth, height: width)
    }
    
//    func miniButton(type: LabelType, text: String! = "", image: String! = "",
//                    font: Font! = .caption, color: Color! = .primaryColorInvert,
//                    disabled: Bool! = false,
//                    action: @escaping () -> Void) -> some View {
//        Button {
//            action()
//        } label: {
//            buttonLabel(btnSize: .mini , type: type, text: text, image: image, font: font, color: color, disabled: disabled)
//        }
//        .disabled(disabled)
//        .buttonStyle(ClickScaleEffect(scale: 0.95))
//    }
//    // 중간 버튼
//    func mediumButton(type: LabelType, text: String! = "", image: String! = "", rotate: Double! = 0.0,
//                      font: Font! = .caption, color: Color! = .primaryColorInvert,
//                      disabled: Bool! = false,
//                      action: @escaping () -> Void) -> some View {
//        Button {
//            action()
//        } label: {
//            buttonLabel(btnSize: .medium, type: type, text: text, image: image, rotate: rotate, font: font, color: color, disabled: disabled)
//        }
//        .disabled(disabled)
//        .buttonStyle(ClickScaleEffect(scale: 0.95))
//    }
    
}

//struct PhotoMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotosGridMenu(isHome: false, album: nil, allPhotos: nil, isSelectMode: .constant(true), selectedItemsIndex: .constant([]), scrollEdge: .constant(.none), isShowingAlert: .constant(false), editType: .constant(.none), isShowingSheet: .constant(false), isShowingShareSheet: .constant(false))
//    }
//}

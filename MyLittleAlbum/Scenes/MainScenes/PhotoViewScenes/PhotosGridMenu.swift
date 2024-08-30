//
//  PhotoMenu.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
//import PhotosUI

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
    var albumToEdit: Album!
    var smartAlbumType: SmartAlbum = .none
    
    var isHiddenAssets: Bool = false
    
    @Binding var settingDone: Bool!
    @Binding var belongingType: BelongingType
    @Binding var filteringType: FilteringType
    @Binding var filteringTypeChanged: Bool
    
    @Binding var isSelectMode: Bool
    @Binding var selectedItemsIndex: [Int]
    @Binding var edgeToScroll: EdgeToScroll
    @State var isSelectedAll: Bool = false
    
    @Binding var isShowingSheet: Bool
    @Binding var isShowingShareSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    
    var nameSpace: Namespace.ID
    
    let width: CGFloat
    let unitCount = 9.0
    let spacing: CGFloat = 8
    let opacity: CGFloat = 0.8
    
    var body: some View {
        HStack(spacing: spacing, content: {
            // left mini
            VStack(spacing: spacing) {
                btnLeftTop(albumType: albumType,
                           isSelectMode: isSelectMode)
                btnLeftBottom(albumType: albumType,
                              isSelectMode: isSelectMode)
            }
            // center
            VStack(spacing: spacing) {
                centerTop(albumType: albumType,
                          isSelectMode: isSelectMode,
                          isHiddenAssets: isHiddenAssets)
                btnsCenterBottom(albumType: albumType,
                                 isSelectMode: isSelectMode,
                                 isHiddenAssets: isHiddenAssets)
            }
            // right mini
            VStack(spacing: spacing) {
                btnRightTop(albumType: albumType,
                            isSelectMode: isSelectMode)
                btnRightBottom(albumType: albumType,
                               isSelectMode: isSelectMode)
            }
        })
    }
}

extension PhotosGridMenu {
    func btnLeftTop(albumType: AlbumType, isSelectMode: Bool) -> some View {
        Group {
            if albumType == .album && !isSelectMode && !isHiddenAssets {
                btnPlus
            } else {
                emptySpace(size: .mini)
            }
        }
    }
    func btnLeftBottom(albumType: AlbumType, isSelectMode: Bool) -> some View {
        Group {
            if albumType == .picker {
                btnFilter()
            } else {
                if isSelectMode {
                    btnDelete()
                } else {
                    btnFilter()
                }
            }
        }
    }
    func centerTop(albumType: AlbumType, isSelectMode: Bool, isHiddenAssets: Bool) -> some View {
        Group {
            switch albumType {
            case .picker:
                btnMove(albumType: albumType, btnSize: .big)
            default:
                centerMenuBar(isSelectMode: isSelectMode)
            }
        }
    }
    func btnsCenterBottom(albumType: AlbumType, isSelectMode: Bool, isHiddenAssets: Bool) -> some View {
        HStack(spacing: spacing) {
            if !isSelectMode {
                if isHiddenAssets == true || albumType == .smartAlbum {
                    btnScrollToEdge(btnSize: .half, edge: .bottom)
                    btnScrollToEdge(btnSize: .half, edge: .top)
                } else {
                    if albumType == .home {
                        btnPhotos(btnSize: .medium)
                    } else {
                        btnModifyTitle(btnSize: .medium)
                    }
                    btnScrollToEdge(btnSize: .medium, edge: .bottom)
                    btnScrollToEdge(btnSize: .medium, edge: .top)
                }
            } else {
                switch albumType {
                case .home, .smartAlbum:
                    if albumType == .home {
                        btnHidden(btnSize: .half)
                    } else {
                        btnUnHide(btnSize: .half)
                    }
                    btnMove(albumType: albumType, btnSize: .half)
                case .album:
                    if !isHiddenAssets {
                        btnHidden(btnSize: .medium)
                    } else {
                        btnUnHide(btnSize: .medium)
                    }
                    btnTakeFrom(btnSize: .medium)
                    btnMove(albumType: albumType, btnSize: .medium)
                case .picker:
                btnPhotos(btnSize: .medium)
                btnScrollToEdge(btnSize: .medium, edge: .bottom)
                btnScrollToEdge(btnSize: .medium, edge: .top)
                }
            }
        }
    }
    func btnRightTop(albumType: AlbumType, isSelectMode: Bool) -> some View {
        Group {
            switch albumType {
            case .album:
                if isSelectMode {
                    btnSelectAll
                } else {
                    btnDigitalShow()
                        .background {
                            RoundedRectangle(cornerRadius: (width - (2 * spacing)) / unitCount)
                                .foregroundStyle(.ultraThinMaterial)
                                .matchedGeometryEffect(id: "digitalShow", in: nameSpace)
                        }
                }
            case .picker:
                btnDeselectInPicker
            default: emptySpace(size: .mini)
            }
        }
    }
    func btnRightBottom(albumType: AlbumType, isSelectMode: Bool) -> some View {
        Group {
            switch albumType {
            case .picker: btnClose
            default: btnTransSelectMode(btnSize: .mini)
            }
        }
    }
}

// MARK: - 포토 그리드 공통 버튼
extension PhotosGridMenu {
    
    var btnClose: some View {
        return menuButton(btnSize: .mini, type: .text, text: "close") {
            self.selectedItemsIndex.removeAll()
            withAnimation {
                self.isShowingPhotosPicker = false
            }
        }
    }
    
    // 가운데 라벨바
    func centerMenuBar(isSelectMode: Bool) -> some View {
        let unitWidth = (width - (2 * spacing)) / unitCount
        let imageText = "사진: \(isHiddenAssets ? album.hiddenAssetsArray.filter{ $0.mediaType == .image}.count : album.countOfImage)"
        let videoText = "비디오: \(isHiddenAssets ? album.hiddenAssetsArray.filter{ $0.mediaType == .video}.count : album.countOfVidoe)"
        let selecteModeText = "\(selectedItemsIndex.count)개의 항목 선택됨"
        return ZStack(alignment: .center) {
            colorBar(unitWidth: unitWidth)
            if isSelectMode {
                Text(selecteModeText)
                    .foregroundColor(.primaryColorInvert)
            } else {
                Text(isHiddenAssets ? "가려진 \(imageText)" : imageText)
                    .foregroundColor(filteringType == .image ? .blue : .primaryColorInvert)
                + Text(" / ")
                    .foregroundColor(.primaryColorInvert)
                + Text(videoText)
                    .foregroundColor(filteringType == .video ? .blue : .primaryColorInvert)
            }
        }
        .font(.system(.subheadline, design: .rounded, weight: .medium))
    }
    // 사진 추가 버튼
    var btnPlus: some View {
        return menuButton(btnSize: .mini,
                          type: .image,
                          image: "plus",
                          scale: .large,
                          color: .white,
                          bgColor: .blue,
                          disabled: isSelectMode) {
            withAnimation {
                self.isShowingPhotosPicker = true
            }
        }
    }
    
    // 선택 모드 토글 버튼
    func btnTransSelectMode(btnSize: ButtonSize! = .mini) -> some View {
        let text = isSelectMode ? "취소" : "선택"
        return menuButton(btnSize: btnSize, type: .text, text: text) {
//            withAnimation {
                isSelectMode.toggle()
//            }
            if isSelectMode {
                stateChangeObject.showPickerButton = true
            } else {
                if isSelectedAll {
                    stateChangeObject.selectToggleAllPhotos = true
                    selectedItemsIndex.removeAll()
                } else if selectedItemsIndex.count != 0 {
                    stateChangeObject.selectToggleSomePhotos = true
                }
                isSelectedAll = false
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
            let array = !isHiddenAssets ? album.photosArray : album.hiddenAssetsArray
            switch album.filteringType {
            case .all: count = array.count
            case .image: count = array.filter { $0.mediaType == .image }.count
            case .video: count = array.filter { $0.mediaType == .video }.count
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
            let array = !isHiddenAssets ? album.photosArray : album.hiddenAssetsArray
            switch album.filteringType {
            case .all: count = array.count
            case .image: count = array.filter { $0.mediaType == .image }.count
            case .video: count = array.filter { $0.mediaType == .video }.count
            }
            isSelectedAll = selectedItemsIndex.count == count
        }
    }
    var btnDeselectInPicker: some View {
        return menuButton(btnSize: .mini,
                          type: .text,
                          text: "선택\n해제",
                          color: selectedItemsIndex.count == 0 ? .gray.opacity(0.5) : .black,
                          disabled: selectedItemsIndex.count == 0) {
            selectedItemsIndex.removeAll()
            DispatchQueue.main.async {
                stateChangeObject.selectToggleSomePhotos = true
            }
        }
    }
    
    // 디지털 액자 버튼
    func btnDigitalShow(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = (isHiddenAssets
                            ? album.hiddenAssetsArray.count == 0
                            : album.photosArray.count == 0)
        ? .gray.opacity(0.5):.black
        return menuButton(btnSize: btnSize,
                          type: .image,
                          image: "play.square.stack",
                          scale: .small,
                          color: color,
                          disabled: self.isHiddenAssets
                          ? album.hiddenAssetsArray.count == 0
                          : album.photosArray.count == 0) {
            var photos = self.isHiddenAssets ? album.hiddenAssetsArray : album.photosArray
            if photoData.digitalShowRandom {
                photos.shuffle()
            }
            photoData.isHiddenAsset = self.isHiddenAssets
            photoData.digitalPhotoAlbums = [self.album]
//            photoData.digitalPhotoArray = photos
            withAnimation(.easeInOut) {
                photoData.isShowingDigitalShow = true
            }
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    // 스크롤 버튼
    func btnScrollToEdge(btnSize: ButtonSize! = .medium, edge: Edge) -> some View {
        let image = edge == .top ? "chevron.left.to.line" : "chevron.right.to.line"
        return menuButton(btnSize: btnSize, type: .image, image: image, rotate: .pi/2) {
            switch edge {
            case .top: edgeToScroll = .top
            default: edgeToScroll = .bottom
            }
        }
    }
    // home에서 사진함 선택
    func btnPhotos(btnSize: ButtonSize! = .mini) -> some View {
        let text = belongingType == .all 
                    ? "모든 사진함"
                    : (belongingType == .album ? "앨범있는 사진함" : "앨범없는 사진함")
        let textColor: Color = selectedItemsIndex.count > 0 ? .gray.opacity(0.5):.blue
        
        return Menu {
            photoMenu
        } label: {
            menuButton(btnSize: btnSize,
                       type: .text,
                       text: text,
                       color: textColor,
                       disabled: selectedItemsIndex.count > 0) {
            }
            .fontWeight(.bold)
        }
        .disabled(selectedItemsIndex.count > 0)
    }
    
    // 필터링
    func btnFilter(btnSize: ButtonSize! = .mini) -> some View {
        var image = ""
        switch filteringType {
        case .image: image = "photo.fill"
        case .video: image = "video.fill"
        default: image = "line.3.horizontal.decrease"
        }
        let textColor: Color = selectedItemsIndex.count > 0 ? .gray.opacity(0.5):.black
        return Menu {
            filteringMenu
        } label: {
            menuButton(btnSize: btnSize,
                       type: .image,
                       image: image,
                       color: selectedItemsIndex.count > 0 
                            ? .gray.opacity(0.5)
                            : (filteringType == .all ? .black : .blue),
                       disabled: selectedItemsIndex.count > 0) {
            }
        }
        .disabled(selectedItemsIndex.count > 0)
    }
    var filteringMenu: some View {
        VStack {
            Button {
                if filteringType != .all {
                    changeFiltering(type: .all, albumChange: true)
                    print("전체로 바꾼다")
                }
            } label: {
                if filteringType == .all {
                    ContextMenuItem(title: "모두 보기", image: "checkmark")
                } else {
                    ContextMenuItem(title: "모두 보기")
                }
            }
            Button {
                if filteringType != .image {
                    changeFiltering(type: .image, albumChange: true)
                    print("사진으로 바꾼다")
                }
            } label: {
                ContextMenuItem(title: "사진만 보기", image: filteringType == .image ? "checkmark":"photo.fill")
            }
            Button {
                if filteringType != . video {
                    changeFiltering(type: .video, albumChange: true)
                    print("비디오로 바꾼다")
                }
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
    
    func changeFiltering(type: FilteringType, albumChange: Bool! = false) {
        album.changeFiltering(type: type)
        self.filteringType = type
        if albumChange {
//            DispatchQueue.main.async {
            self.filteringTypeChanged = true
//                stateChangeObject.filteringChanged = true
            print("check 1. filtering Change \(stateChangeObject.filteringChanged)")
//            }
        }
        print("check 2. filtering Change \(stateChangeObject.filteringChanged)")
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
        return menuButton(btnSize: btnSize, 
                          type: .image, 
                          image: "trash",
                          color: color,
                          disabled: count == 0) {
            deleteAsset(indexSet: selectedItemsIndex, 
                        filter: tempFilteringType,
                        selected: tempSelectedItems)
        }
    }
    // 앨범에서 빼기
    func btnTakeFrom(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, 
                          type: .text,
                          text: "앨범에서 빼기",
                          color: color,
                          disabled: count == 0) {
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
            buttonLabel(btnSize: btnSize, 
                        type: .text,
                        text: "공유하기",
                        font: .caption,
                        color: color)
        }
        .disabled(selectedItemsIndex.count == 0)
    }
    // 복구 버튼
    func btnRestore(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, 
                          type: .text,
                          text: "복구하기",
                          color: color,
                          disabled: count == 0) {
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
    func btnMove(albumType: AlbumType, btnSize: ButtonSize! = .mini) -> some View {
        let text: String
        let textColor: Color
        let bgColor: Color
        switch albumType {
        case .home: text = "앨범에 넣기"
        case .album: text = "다른 앨범으로\n이동하기"
        default: text = selectedItemsIndex.count
            > 0 ? "\(selectedItemsIndex.count)개의 항목 이 앨범에 넣기"
            : "선택한 항목 없음"
        }
        
        switch albumType {
        case .home, .album:
            textColor = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.black
            bgColor = .white
        default:
            textColor = .white
            bgColor = .blue.opacity(selectedItemsIndex.count == 0 ? 0.3 : 1)
        }
        
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, 
                          type: .text,
                          text: text,
                          color: textColor,
                          bgColor: bgColor,
                          disabled: count == 0) {
            if albumType == .picker {
                addAssetIntoAlbum(indexSet: selectedItemsIndex)
            } else {
                isShowingSheet = true
            }
            
        }
        .disabled(selectedItemsIndex.count == 0)
    }
    // 가리기
    func btnHidden(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, 
                          type: .text,
                          text: "가리기",
                          color: color,
                          disabled: count == 0) {
            hiddenAsset(indexSet: selectedItemsIndex)
        }
    }
    // 가리기 해제
    func btnUnHide(btnSize: ButtonSize! = .mini) -> some View {
        let color: Color = selectedItemsIndex.count == 0 ? .gray.opacity(0.5):.primaryColorInvert
        let count = selectedItemsIndex.count
        return menuButton(btnSize: btnSize, 
                          type: .text,
                          text: "가리기 해제",
                          color: color,
                          disabled: count == 0) {
            unHideAsset(indexSet: selectedItemsIndex)
        }
    }
    
}

//MARK: - 사진 처리 함수
extension PhotosGridMenu {
    
    // 앨범에서 빼기 - 경고창을 위해 grid 뷰에서 처리
    // 현재 앨범에 넣기
    func addAssetIntoAlbum(indexSet: [Int]) {
        self.isShowingPhotosPicker = false
        var assetArray: [PHAsset] = []
        switch album.filteringType {
        case .all:
            assetArray = album.photosArray
        case .image:
            assetArray = album.photosArray.filter({$0.mediaType == .image})
        case .video:
            assetArray = album.photosArray.filter({$0.mediaType == .video})
        }
        let sortedIndexSet = indexSet.sorted{ $0 < $1 }
        var assets: [PHAsset] = []
        for i in sortedIndexSet {
            assets.append(assetArray[i])
        }
        if isShowingPhotosPicker {
            withAnimation {
                isShowingPhotosPicker = false
            }
        }
        selectedItemsIndex = []

        DispatchQueue.global(qos: .userInteractive).async {
            albumToEdit?.addAsset(assets: assets, stateObject: stateChangeObject)
        }
    }
    
    // 기기에서 삭제
    func deleteAsset(indexSet: [Int], filter: FilteringType, selected: [Int]) {
        album.deleteAssetFromDevice(indexSet: indexSet, stateObject: stateChangeObject)
    }
    
    // 사진 가리기
    func hiddenAsset(indexSet: [Int]) {
        album.hideAsset(indexSet: indexSet, stateObject: stateChangeObject)
    }
    
    func unHideAsset(indexSet: [Int]) {
        if indexSet.count >= 1000 {
            for i in 0..<indexSet.count / 100 {
                let subIndexSet = Array(indexSet[(i*100)..<((i+1)*100)])
                album.unHideAsset(indexSet: subIndexSet,
                                  stateObject: stateChangeObject,
                                  isAlbum: true,
                                  isSeperated: true)
            }
            let remain = Array(indexSet[(100 * (indexSet.count / 100))..<indexSet.count])
            album.unHideAsset(indexSet: remain,
                              stateObject: stateChangeObject,
                              isAlbum: true)
        } else {
            album.unHideAsset(indexSet: indexSet, stateObject: stateChangeObject, isAlbum: true)
        }
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
               PHImageManager.default()
                   .requestAVAsset(forVideo: mPhasset,
                                   options: options,
                                   resultHandler: { (asset, audioMix, info) in
                   if let urlAsset = asset as? AVURLAsset {
                       let localVideoUrl = urlAsset.url
                       completionHandler(localVideoUrl)
                   } else {
                       completionHandler(nil)
                   }
               })
           }
       }
    func emptySpace(size: ButtonSize) -> some View {
        buttonLabel(btnSize: size, type: .text)
            .opacity(0)
            .disabled(true)
    }
    
}

// MARK: - 버튼 레이아웃
extension PhotosGridMenu {
    // 공용 백그라운드 바
    func colorBar(opacity: CGFloat! = 0.9,
                  unitWidth: CGFloat,
                  color: Color! = .primary) -> some View {
        color.opacity(opacity)
            .cornerRadius(unitWidth / 2)
    }
    
    func menuButton(btnSize: ButtonSize,
                    type: LabelType,
                    text: String! = "",
                    image: String! = "",
                    scale: Image.Scale = .medium,
                    rotate: Double! = 0.0,
                    font: Font! = .caption, 
                    color: Color! = .primaryColorInvert,
                    bgColor: Color! = .primary,
                    disabled: Bool! = false,
                    action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            buttonLabel(btnSize: btnSize,
                        type: type, text: text, image: image,
                        rotate: rotate,
                        font: font, 
                        color: color, bgColor: bgColor,
                        disabled: disabled)
        }
        .disabled(disabled)
        .buttonStyle(ClickScaleEffect(scale: 0.95))
    }
    
    func buttonLabel(btnSize: ButtonSize, 
                     type: LabelType,
                     text: String! = "", 
                     image: String! = "",
                     rotate: Double! = 0.0,
                     font: Font! = .caption,
                     color: Color! = .primaryColorInvert,
                     bgColor: Color! = .primary,
                     disabled: Bool! = false) -> some View {
        let unitWidth = (width - (2 * spacing)) / unitCount
        let resultWidth: CGFloat!
        switch btnSize {
        case .big: resultWidth = unitWidth * 7
        case .half: resultWidth = (unitWidth * 7 - (spacing * 1)) / 2
        case .medium: resultWidth = (unitWidth * 7 - (spacing * 2)) / 3
        default: resultWidth = unitWidth * 1
        }
        return ZStack(alignment: .center) {
            colorBar(unitWidth: unitWidth, color: bgColor)
                .cornerRadius(unitWidth / 2)
                .clipped()
                .shadow(color: Color.fancyBackground.opacity(0.5), radius: 2, x: 0, y: 0)
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
        .frame(width: resultWidth)
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

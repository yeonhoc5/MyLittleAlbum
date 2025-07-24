//
//  PhotoMenu.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos

enum LabelType {
    case text, image
}

enum FilteringType: Identifiable, Hashable, CaseIterable {
    var id: Int { return self.hashValue }
    var titleText: String {
        return switch self {
        case .all: "전체 보기"
        case .favorite: "즐겨찾기만 보기"
        case .video: "동영상만 보기"
        case .image: "사진만 보기"
        }
    }
    var imageText: String {
        return switch self {
        case .all: ""
        case .favorite: iconFavorite
        case .video: iconVideo
        case .image: iconImage
        }
    }
    case all, video, image, favorite // contextMenu에서 아래부터 순서대로
    
    static func trueType(type: Self) -> PHAssetMediaType {
        switch type {
        case .image: return .image
        case .video: return .video
        default: return .image
        }
    }
}
enum BelongingType {
    case nonAlbum, album, all
}

struct PhotosGridMenu: View {
    @EnvironmentObject var photoData: MLPhotoData
    var albumType: AlbumType = .album
    let smartAlbumType: SmartType
    @ObservedObject var mlAlbum: MLAlbum
    var isHiddenAssets: Bool = false
    let cachingimageManager: PHCachingImageManager
    
    let assetArray: [MLAsset]
    @Binding var belongingType: BelongingType
    @Binding var filteringType: FilteringType
    
    @Binding var isSelectMode: Bool
    @Binding var selectedItems: [MLAsset]
    @Binding var refreshItems: [MLAsset]
    @Binding var edgeToScroll: EdgeToScroll
    @State var isSelectedAll: Bool = false
    
    @State var isShowingDigitalShow: Bool = false
    @Binding var isShowingShareSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    
    var albumToEdit: String!
    var nameSpace: Namespace.ID
    
    let width: CGFloat
    let unitCount = 9.0
    let spacing: CGFloat = 8
    let opacity: CGFloat = 0.8
    
    @Binding var reloadingType: ReLoadingType
    let isReadyHiddenAsset: Bool
    
    var body: some View {
        HStack(spacing: spacing, content: {
            // left mini
            VStack(spacing: spacing) {
                btnLeftTop(albumType: albumType,
                           isSelectMode: isSelectMode)
                btnLeftBottom(albumType: albumType,
                              isSelectMode: isSelectMode)
            }
            .frame(width: abs(width - (2 * spacing)) / unitCount)
            // center
            VStack(spacing: spacing) {
                centerTop(albumType: albumType,
                          assetArray: assetArray,
                          isSelectMode: isSelectMode,
                          isHiddenAssets: isHiddenAssets)
                btnCenterBottom(albumType: albumType,
                                isSelectMode: isSelectMode,
                                isHiddenAssets: isHiddenAssets)
            }
            // right mini
            VStack(spacing: spacing) {
                btnRightTop(albumType: albumType,
                            assetArray: assetArray,
                            isSelectMode: isSelectMode)
                btnRightBottom(albumType: albumType,
                               assetArray: assetArray,
                               isSelectMode: isSelectMode)
            }
            .frame(width: abs(width - (2 * spacing)) / unitCount)
        })
        .animation(.easeInOut, value: isSelectMode)
        .onReceive(NotificationCenter.default
            .publisher(for: .endDigitalShow)) { _ in
                dispatchAnimation {
                    isShowingDigitalShow = false
                }
        }
        .onReceive(NotificationCenter.default
            .publisher(for: .assetWorkStart), perform: { output in
                if let mlID = output.object as? String {
                    if mlID == self.mlAlbum.id {
                        mlAlbum.processingChange(bool: true)
                    }
                }
            })
        .onReceive(NotificationCenter.default
            .publisher(for: .assetWorkDone), perform: { output in
                if let mlID = output.object as? String {
                    print("[\(mlID == mlAlbum.id)] \(mlID), \(mlAlbum.id)")
                    if mlID == self.mlAlbum.id {
                        mlAlbum.processingChange(bool: false)
                    }
                }
            })
        .opacity(isShowingDigitalShow ? 0 : 1)
    }
}

extension PhotosGridMenu {
    func btnLeftTop(albumType: AlbumType, isSelectMode: Bool) -> some View {
        Group {
            if albumType == .album && !isHiddenAssets {
                FlipViewTransitor(isModeChange: isSelectMode) {
                    btnPlus
                } flipReverseView: {
                    btnDelete
                }
            } else {
                Group {
                    if albumType != .picker && isSelectMode {
                        btnDelete
                    } else {
                        emptySpace(size: .mini)
                    }
                }
                .transition(.scale)
            }
        }
    }
    func btnLeftBottom(albumType: AlbumType, isSelectMode: Bool) -> some View {
        Group {
            if albumType == .picker {
                btnFilter()
            } else {
                FlipViewTransitor(isModeChange: isSelectMode) {
                    btnFilter()
                } flipReverseView: {
                    btnHideUnhide(!isHiddenAssets && smartAlbumType != .hiddenAsset)
                }
            }
        }
    }
    func centerTop(albumType: AlbumType,
                   assetArray: [MLAsset],
                   isSelectMode: Bool,
                   isHiddenAssets: Bool) -> some View {
        Group {
            switch albumType {
            case .picker:
                btnMove(albumType: albumType)
            default:
                centerMenuBar(assetArray: assetArray,
                              isSelectMode: isSelectMode)
                    .clipped()
            }
        }
    }
    func btnCenterBottom(albumType: AlbumType,
                         isSelectMode: Bool,
                         isHiddenAssets: Bool) -> some View {
            FlipViewTransitor(isModeChange: isSelectMode) {
                HStack(spacing: spacing) {
                    if !isHiddenAssets {
                        switch albumType {
                        case .home, .picker: btnPhotosChange()
                        case .album: btnModifyTitle()
                        default: EmptyView()
                        }
                    }
                    btnScrollToEdge(edge: .bottom)
                    btnScrollToEdge(edge: .top)
                }
            } flipReverseView: {
                HStack(spacing: spacing) {
                    switch albumType {
                    case .picker:
                        btnPhotosChange()
                        btnScrollToEdge(edge: .bottom)
                        btnScrollToEdge(edge: .top)
                    default:
                        if albumType == .album {
                            btnTakeFrom()
                        }
                        if albumType != .smartAlbum {
                            btnMove(albumType: albumType)
                        }
                        btnFavorite()
                    }
                }
            }
    }
    func btnRightTop(albumType: AlbumType, assetArray: [MLAsset], isSelectMode: Bool) -> some View {
        Group {
            if albumType == .picker || albumType == .home {
                Group {
                    if isSelectMode {
                        btnDeselectInPicker
                    } else {
                        emptySpace(size: .mini)
                    }
                }
                .transition(.scale)
            } else if albumType != .home {
                FlipViewTransitor(isModeChange: isSelectMode) {
                    Group {
                        if !isShowingDigitalShow {
                            btnDigitalShow(assetArray: assetArray)
                                .matchedGeometryEffect(id: "digitalShow", in: nameSpace)
                                .transition(.opacity)
                        } else {
                            emptySpace(size: .mini)
                        }
                    }
                } flipReverseView: {
                    btnSelectAll(assetArray: assetArray)
                }
            } else {
                emptySpace(size: .mini)
            }
        }
    }
    func btnRightBottom(albumType: AlbumType, assetArray: [MLAsset], isSelectMode: Bool) -> some View {
        Group {
            if smartAlbumType != .trashCan {
                switch albumType {
                case .picker:
                    btnClose
                default:
                    btnToggleSelectMode(assetArray: assetArray)
                }
            } else {
                emptySpace(size: .mini)
            }
        }
    }
}

// MARK: - 포토 그리드 공통 버튼
extension PhotosGridMenu {
    // 0. 가운데 라벨바
    func centerMenuBar(assetArray: [MLAsset], isSelectMode: Bool) -> some View {
        return ZStack(alignment: .center) {
            Capsule()
                .modify({ view in
                    if isReadyHiddenAsset {
                        view.foregroundStyle(.blue)
                    } else {
                        view.foregroundStyle(.ultraThinMaterial)
                    }
                })
                .transition(.opacity)
            if isReadyHiddenAsset {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                    Text("Generating...")
                        .foregroundStyle(.white)
                }
                .transition(.opacity)
            } else {
                FlipViewTransitor(isModeChange: isSelectMode) {
                    HStack {
                        let imageCount = assetArray.filter { $0.mediaType == .image }.count
                        let videoCount = assetArray.filter { $0.mediaType == .video }.count
                        if isHiddenAssets {
                            Text("가려진")
                        }
                        Text("사진: \(imageCount)")
                            .foregroundColor(filteringType == .image ? .blue : .white)
                            .contentTransition(.numericText())
                        if mlAlbum.innerProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.blue)
                                .padding(.horizontal, 7.5)
                                .matchedGeometryEffect(id: "processing", in: nameSpace)
                        } else {
                            Text(" / ")
                                .matchedGeometryEffect(id: "processing", in: nameSpace)
                        }
                        Text("비디오: \(videoCount)")
                            .foregroundColor(filteringType == .video ? .blue : .white)
                            .contentTransition(.numericText())
                    }
                    .foregroundColor(.white)
                } flipReverseView: {
                    HStack(alignment: .center, spacing: 0) {
                        let selectedCount = selectedItems.count
                        Text("\(selectedCount)")
                            .font(.system(.subheadline,
                                          design: .monospaced,
                                          weight: .medium))
                            .contentTransition(.numericText())
                            .animation(.linear, value: selectedCount)
                        Text("개의 항목 ")
                        if mlAlbum.innerProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.blue)
                                .padding(.horizontal, 7.5)
                        } else {
                            Text("선택됨")
                        }
                    }
                }
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.white)
            }
        }
    }
    // 1. show PhotoPickerView : album
    var btnPlus: some View {
        return menuButton(type: .image, image: "plus",
                          scale: .large, color: .white, bgColor: .blue,
                          disabled: isSelectMode) {
            let object = PickerObject(editToAlbum: self.mlAlbum.id,
                                      imageManager: cachingimageManager)
            dispatchAnimation {
                NotificationCenter.default
                    .post(name: .showPhotosPicker, object: object)
            }
        }
    }
    
    // 선택 모드 토글 버튼
    func btnToggleSelectMode(assetArray: [MLAsset]) -> some View {
        let assetArray = assetArray
            .filter {
                return switch filteringType {
                case .all: true
                case .favorite: $0.isFavorite
                default: FilteringType
                        .trueType(type: self.filteringType) == $0.mediaType
                }
            }
        let text = isSelectMode ? "취소" : "선택"
        let disabled = isSelectMode ? false : assetArray.isEmpty
        return menuButton(type: .text, text: text, disabled: disabled) {
            isSelectMode.toggle()
            DispatchQueue.main.async {
                reloadingType = .selectedModeChange
            }
        }
    
    }
    // 전체 선택 / 해제 버튼
    func btnSelectAll(assetArray: [MLAsset]) -> some View {
        let assetArray = assetArray
            .filter {
                return switch filteringType {
                case .all: true
                case .favorite: $0.isFavorite
                default: FilteringType
                        .trueType(type: self.filteringType) == $0.mediaType
                }
            }
        let disable = assetArray.isEmpty
        let isSelectedAll = selectedItems.count == assetArray.count
        let text = isSelectedAll ? "전체\n해제" : "전체\n선택"
        return menuButton(type: .text,
                          text: text,
                          disabled: disable) {
            if isSelectedAll {
                DispatchQueue.main.async {
                    reloadingType = .deselectAll
                }
            } else {
                DispatchQueue.main.async {
                    reloadingType = .selectAll
                }
            }
        }
    }
    var btnDeselectInPicker: some View {
        return menuButton(type: .text,
                          text: "선택\n해제",
                          color: selectedItems.isEmpty ? .gray.opacity(0.5) : .black,
                          disabled: selectedItems.isEmpty) {
            DispatchQueue.main.async {
                reloadingType = .deselectAll
            }
        }
    }
    
    // 디지털 액자 버튼
    func btnDigitalShow(assetArray: [MLAsset]) -> some View {
        let assetArray = assetArray
            .filter {
                return switch filteringType {
                case .all: true
                case .favorite: $0.isFavorite
                default: FilteringType
                        .trueType(type: self.filteringType) == $0.mediaType
                }
            }
        let disable = assetArray.isEmpty
        let color: Color = disable ? .gray.opacity(0.5) : .black
        var symbol: String = ""
        if #available(iOS 17, *) {
            symbol = "play.square.stack"
        } else {
            symbol = "play.square"
        }
        return menuButton(type: .image,
                          image: symbol,
                          scale: .small,
                          color: color,
                          bgColor: isShowingDigitalShow ? .clear : .white,
                          disabled: disable) {
            let digitalShowObject = DigitalShowObject(
                digitalShowRandom: photoData.digitalShowRandom,
                transitionSecond: transitionRange[photoData.transitionIndex],
                assetArray: photoData.digitalShowRandom ? assetArray.shuffled() : assetArray,
                digitalShowTitle: mlAlbum.title,
                nameSpace: nameSpace)
            withAnimation {
                isShowingDigitalShow = true
            }
            NotificationCenter.default
                .post(name: .showDigitalShow, object: digitalShowObject)
        }
    }
    // 스크롤 버튼
    func btnScrollToEdge(edge: Edge) -> some View {
        let image = edge == .top ? "chevron.left.to.line" : "chevron.right.to.line"
        return menuButton(type: .image, image: image, rotate: .pi/2) {
            DispatchQueue.main.async {
                switch edge {
                case .top: edgeToScroll = .top
                default: edgeToScroll = .bottom
                }
            }
        }
    }
    // home에서 사진함 선택
    func btnPhotosChange() -> some View {
        let text = belongingType == .all
                    ? "모든 항목"
                    : (belongingType == .album ? "앨범에 있는 항목" : "앨범에 없는 항목")
        let disable = !selectedItems.isEmpty
        let textColor: Color = disable ? .gray.opacity(0.5) : .blue
        return Menu {
            photoMenu
        } label: {
            menuButton(type: .text, text: text, color: textColor, disabled: disable) { }
            .fontWeight(.bold)
        }
        .disabled(disable)
    }
    
    // 필터링
    func btnFilter() -> some View {
        var image = ""
        switch filteringType {
        case .favorite: image = "heart.fill"
        case .image: image = "photo.fill"
        case .video: image = "video.fill"
        default: image = "line.3.horizontal.decrease"
        }
        let disable = !selectedItems.isEmpty
        return Group {
            if filteringType == .all {
                Menu {
                    filteringMenu
                } label: {
                    buttonLabel(type: .image,
                                image: image,
                                color: .black,
                                disabled: disable)
                }
            } else {
                menuButton(type: .image,
                           image: image,
                           color: .blue,
                           disabled: disable) {
                    dispatchAnimation {
                        filteringType = .all
                        reloadingType = .filterChange
                    }
                }
            }
        }
    }
    var filteringMenu: some View {
        VStack {
            ForEach(FilteringType
                .allCases
                .filter({ smartAlbumType == .favorite ? $0 != .favorite : true }), id: \.self) { type in
                if type != .all {
                    Button {
                        if filteringType != type {
                            dispatchAnimation {
                                filteringType = type
                                reloadingType = .filterChange
                            }
                        }
                    } label: {
                        ContextMenuItem(title: type.titleText,
                                        image: type.imageText,
                                        color: filteringType == type ? .white : .blue)
                    }
                }
            }
        }
    }
    
    // 정렬
    func btnRearrange() -> some View {
        Menu {
            reArrangeMenu
        } label: {
            menuButton(type: .image, image: "arrow.up.arrow.down") {
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
    func btnModifyTitle() -> some View {
        menuButton(type: .text, text: "앨범명 수정") {
            let alertObject = AlertObject(alertCase: .albumNameChange,
                                          album: mlAlbum.phAssetCollection,
                                          folder: nil,
                                          needsTextField: true
            )
            NotificationCenter.default.post(name: .showAlert,
                                            object: alertObject)
        }
    }
    func btnFavorite() -> some View {
        let disable = selectedItems.isEmpty
        let toFavorite = disable || !selectedItems.filter { !$0.isFavorite }.isEmpty
        let icon = toFavorite ? iconFavorite : iconUnfavorite
        let assets = selectedItems.filter { $0.isFavorite != toFavorite }
        return menuButton(type: .image, image: icon, disabled: disable) {
            mlAlbum.processingChange(bool: true)
            mlAlbum.favoriteAsset(toFavorite: toFavorite,
                                  assets: assets,
                                  isHiddenAsset: self.isHiddenAssets) { bool in
                if bool {
                    dispatchAnimation {
                        isSelectMode = false
                        reloadingType = .itemChangedInside
//                        switch albumType {
//                        case .home:
//                            let object = ChangedItem(assets: selectedItems, albumType: .album)
//                            NotificationCenter.default
//                                .post(name: .assetChanged, object: object)
//                        case .album:
//                            let object = ChangedItem(assets: selectedItems, albumType: .home)
//                            NotificationCenter.default
//                                .post(name: .assetChanged, object: object)
//                        case .smartAlbum:
//                            let object1 = ChangedItem(assets: selectedItems, albumType: .album)
//                            let object2 = ChangedItem(assets: selectedItems, albumType: .home)
//                            NotificationCenter.default
//                                .post(name: .assetChanged, object: object1)
//                            NotificationCenter.default
//                                .post(name: .assetChanged, object: object2)
//                        default: break
//                        }
                    }
                }
            }
        }
    }
    
    var photoMenu: some View {
        VStack {
            Button {
                switch belongingType {
                case .all:
                    dispatchAnimation {
                        belongingType = .nonAlbum
                        reloadingType = .belongingChange
                    }
                case .album:
                    dispatchAnimation {
                        belongingType = .all
                        reloadingType = .belongingChange
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.interactiveSpring()) {
                                belongingType = .nonAlbum
                        }
                        reloadingType = .belongingChange
                    }                    }
                case .nonAlbum:
                    break
                }
            } label: {
                ContextMenuItem(title: "앨범에 없는 항목만 보기",
                                image: belongingType == .nonAlbum ? "checkmark" : "",
                                color: belongingType == .nonAlbum ? .blue : .black)
            }
            Button {
                if belongingType != .all {
                    DispatchQueue.main.async {
                        withAnimation(.interactiveSpring()) {
                            belongingType = .all
                        }
                        reloadingType = .belongingChange
                    }
                }
            } label: {
                ContextMenuItem(title: "모든 항목 보기",
                                image: belongingType == .all ? "checkmark" : "",
                                color: belongingType == .nonAlbum ? .blue : .black)
            }
            Button {
                switch belongingType {
                case .all:
                    dispatchAnimation {
                        belongingType = .album
                        reloadingType = .belongingChange
                    }
                case .nonAlbum:
                    dispatchAnimation {
                        belongingType = .all
                        reloadingType = .belongingChange
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.interactiveSpring()) {
                                belongingType = .album
                            }
                            reloadingType = .belongingChange
                        }
                    }
                case .album:
                    break
                }
//                if belongingType != .album {
//                    withAnimation(.interactiveSpring()) {
//                        belongingType = .album
//                    }
//                    DispatchQueue.main.async {
//                        reloadingType = .belongingChange
//                    }
//                }
            } label: {
                ContextMenuItem(title: "앨범에 있는 항목만 보기",
                                image: belongingType == .album ? "checkmark" : "",
                                color: belongingType == .nonAlbum ? .blue : .black)
            }
        }
    }
    
}

//MARK: - 선택한 사진 처리 버튼 정의
extension PhotosGridMenu {
    // 삭제
    var btnDelete: some View {
        let disable = selectedItems.isEmpty
        let bgColor: Color = disable ? .color4 : .red
        let tempSelectedItems = self.selectedItems
        return menuButton(type: .image,
                          image: "trash",
                          color: .white,
                          bgColor: bgColor,
                          disabled: disable,
                          disabledColor: .white.opacity(0.5)) {
            deleteAsset(selected: tempSelectedItems)
        }
    }
    // 앨범에서 빼기
    func btnTakeFrom() -> some View {
        let disable = selectedItems.isEmpty
        return menuButton(type: .text, text: "앨범에서 빼기", disabled: disable) {
            let alertObject = AlertObject(alertCase: .mediaTakeFromAlbum,
                                          album: mlAlbum.phAssetCollection,
                                          folder: nil,
                                          selectedItems: selectedItems,
                                          isHiddenAsset: isHiddenAssets
            )
            DispatchQueue.main.async {
                NotificationCenter.default
                    .post(name: .showAlert, object: alertObject)
            }
        }
    }
    
    // 공유 버튼
    func btnShare() -> some View {
        ShareLink(items: assetsToShare(assets: selectedItems)) { items in
            SharePreview(items.caption, image: items.image)
        } label: {
            let disable = selectedItems.isEmpty
            buttonLabel(type: .text,
                        text: "공유하기",
                        font: .caption,
                        disabled: disable)
        }
        .disabled(selectedItems.isEmpty)
    }
    // 복구 버튼
    func btnRestore() -> some View {
        let disable = selectedItems.isEmpty
        return menuButton(type: .text,
                          text: "복구하기",
                          disabled: disable) {
            PHPhotoLibrary.shared().performChanges {
                
            }
        }
    }
    
    func assetsToShare(assets: [MLAsset])  -> [Photo] {
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
    
    // 1-1. album: 어셋 이동 시트 열기
    // 1-2. home: 어셋 이동 시트 열기
    // 2. picker: 현재 앨범에 넣기
    func btnMove(albumType: AlbumType) -> some View {
        let disable = selectedItems.isEmpty
        let textColor: Color
        let bgColor: Color
        let text = switch albumType {
        case .home: "앨범에 넣기"
        case .album: "다른 앨범으로 이동하기"
        default: selectedItems.isEmpty 
                        ? "선택한 항목 없음"
                        : "\(selectedItems.count)개의 항목 이 앨범에 넣기"
        }
        switch albumType {
        case .home, .album:
            textColor = disable ? .gray.opacity(0.5) : .black
            bgColor = .white
        default:
            textColor = .white
            bgColor = disable ? .addButton : .blue
        }
        return menuButton(type: .text, text: text,
                          color: textColor, bgColor: bgColor,
                          disabled: disable) {
            switch albumType {
            case .home, .album:
                mlAlbum.processingChange(bool: true)
                let moveAssetObject = MoveAssetObject(
                    albumType: albumType,
                    currentAlbum: mlAlbum.phAssetCollection,
                    selectedItems: self.selectedItems,
                    isHidden: isHiddenAssets
                )
                dispatchAnimation {
                    NotificationCenter.default
                        .post(name: .showMoveAssetSheet, object: moveAssetObject)
                }
            case .picker:
                guard let albumToEdit = photoData.albums[self.albumToEdit ?? ""]
                else { return }
                dispatchAnimation {
                    NotificationCenter.default
                        .post(name: .assetWorkStart, object: albumToEdit.id)
//                    self.isShowingPhotosPicker = false
                }
                albumToEdit.processingChange(bool: true)
                albumToEdit.addAsset(assets: selectedItems) { bool in
                    if bool {
                        DispatchQueue.main.async {
                            selectedItems = []
                            withAnimation {
                                self.reloadingType = .reFetchInside
                            }
                            NotificationCenter.default
                                .post(name: .outsideFetchChange, object: "myPhotos")
                        }
                    } else {
                        NotificationCenter.default
                            .post(name: .assetWorkDone, object: albumToEdit.id)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isShowingPhotosPicker = false
                        if bool {
                            NotificationCenter.default
                                .post(name: .innerFetchChange, object: albumToEdit.id)
                        }
                    }
                }
            default: break
            }
        }
        .disabled(selectedItems.isEmpty)
    }
    // 가리기 & 해제
    func btnHideUnhide(_ toHide: Bool) -> some View {
        let disable = selectedItems.isEmpty
        return menuButton(type: .image,
                          image: toHide ? iconHide : iconUnhide,
                          disabled: disable) {
            hideOrUnhideAsset(assets: selectedItems)
        }
    }
    // pickerView 닫기 버튼
    var btnClose: some View {
        return menuButton(type: .text, text: "close") {
            DispatchQueue.main.async {
                isShowingPhotosPicker = false
            }
        }
    }
}

//MARK: - 사진 처리 함수
extension PhotosGridMenu {
    // 기기에서 삭제
    func deleteAsset(selected: [MLAsset]) {
        mlAlbum.deleteAssetFromDevice(albumType: albumType,
                                       assets: selectedItems,
                                       isHiddenAsset: isHiddenAssets,
                                       isDetailView: false) { bool in
            if bool {
                DispatchQueue.main.async {
                    reloadingType = .reFetchInside
                    if albumType == .album || albumType == .smartAlbum {
                        NotificationCenter.default
                            .post(name: .innerFetchChange, object: "myPhotos")
                    }
                }
            } else {
                mlAlbum.processingChange(bool: false)
            }
        }
    }
    
    // 사진 가리기
    func hideOrUnhideAsset(assets: [MLAsset]) {
        mlAlbum.processingChange(bool: true)
        if !isHiddenAssets {
            mlAlbum.hideOrUnhideAsset(assets: selectedItems,
                                      toHide: !isHiddenAssets,
                                      isDetailView: false) { bool in
                DispatchQueue.main.async {
                    if bool {
                        reloadingType = .reFetchInside
                    }
                    mlAlbum.processingChange(bool: false)
                }
            }
        } else {
            let alertObject = AlertObject(alertCase: .mediaUnhide,
                                          albumType: self.albumType,
                                          album: mlAlbum.phAssetCollection,
                                          folder: nil,
                                          selectedItems: selectedItems,
                                          needsTextField: false,
                                          isHiddenAsset: self.isHiddenAssets,
                                          isDetailView: false)
            DispatchQueue.main.async {
                NotificationCenter.default
                    .post(name: .showAlert, object: alertObject)
            }
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
        buttonLabel(type: .text)
            .opacity(0)
            .disabled(true)
    }
    
}

// MARK: - 버튼 레이아웃
extension PhotosGridMenu {
    // 공용 백그라운드 바
    func colorBar(opacity: CGFloat! = 0.9,
                  unitWidth: CGFloat,
                  color: Color! = .white) -> some View {
        color.opacity(opacity)
            .cornerRadius(unitWidth / 2)
    }
    
    func menuButton(type: LabelType,
                    text: String! = "",
                    image: String! = "",
                    scale: Image.Scale = .medium,
                    rotate: Double! = 0.0,
                    font: Font! = .caption, 
                    color: Color! = .black,
                    bgColor: Color! = .white,
                    disabled: Bool! = false,
                    disabledColor: Color! = .gray.opacity(0.5),
                    action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            buttonLabel(type: type, text: text, image: image,
                        rotate: rotate,
                        font: font, 
                        color: color, bgColor: bgColor,
                        disabled: disabled, disabledColor: disabledColor)
            .animation(.easeInOut, // 없애지 말 것 : 선택한 셀이 0인지에 따라 전체 버튼에 애니메이션 효과
                       value: selectedItems.isEmpty)
        }
        .disabled(disabled)
        .buttonStyle(ClickScaleEffect(scale: 0.95))
    }
    
    func buttonLabel(type: LabelType,
                     text: String! = "", 
                     image: String! = "",
                     rotate: Double! = 0.0,
                     font: Font! = .caption,
                     color: Color! = .black,
                     bgColor: Color! = .white,
                     disabled: Bool! = false,
                     disabledColor: Color! = .gray.opacity(0.5)) -> some View {
        let unitWidth = abs(width - (2 * spacing)) / unitCount
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
        .foregroundStyle(disabled ? disabledColor : color)
    }
}

//struct PhotoMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotosGridMenu(isHome: false, album: nil, allPhotos: nil, isSelectMode: .constant(true), selectedItemsIndex: .constant([]), scrollEdge: .constant(.none), isShowingAlert: .constant(false), editType: .constant(.none), isShowingSheet: .constant(false), isShowingShareSheet: .constant(false))
//    }
//}

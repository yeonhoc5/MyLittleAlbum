//
//  PhotosDetailView.swift
//  PhotosDetailView
//
//  Created by yeonhoc5 on 2023/02/21.
//

import SwiftUI
import Photos
import AVKit

enum DetailViewGesture {
    case paging, videoSeeking, soundAdjusting, dismissingView, hideTools, none
}

// MARK: - 1. BODY
struct PhotosDetailView: View {
    @EnvironmentObject var photoData: MLPhotoData
    let albumType: AlbumType
//    let album: MLAlbum!
    let assetCollection: PHAssetCollection!
    let isHiddenAssets: Bool
    let assetArray: [MLAsset]
    
    @Binding var indexToView: Int
    @Binding var isExpanded: Bool
    @State var navigationTitle: String = ""
    var animationID: Namespace.ID
    
    // 페이지
    @State var hideToolbar: Bool = false
    // 이미지/비디오 공통
    @State var offsetY: CGFloat = 0
    @State var offsetX: CGFloat = .zero
    // 이미지
    @State var variableScale: CGFloat = 1
    @State var currentScale: CGFloat = 1
    // 비디오
    @State var play: VideoState = .stop
    @State var userGesture: DetailViewGesture = .none
    
    // cacing
    let cachingManager = PHCachingImageManager()
    @State var settingDone: Bool = false
    
    @Binding var reLoadingType: ReLoadingType
    @Binding var selectedItems: [MLAsset]
    
    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                RecyclePageView(count: assetArray.count,
                                 indexToView: $indexToView,
                                 isExpanded: $isExpanded,
                                 userGesture: $userGesture,
                                 scale: variableScale,
                                 offsetX: $offsetX) { offsetIndex, pageIndex, size in
                    if (0..<assetArray.count).contains(pageIndex) {
                        let asset = assetArray[pageIndex]
                        detailView(currentAsset: asset,
                                   offsetIndex: offsetIndex,
                                   pageIndex: pageIndex,
                                   size: size,
                                   cachingManager: cachingManager,
                                   animationID: animationID)
                            .onChange(of: indexToView) { [old = indexToView] new in
                                if offsetIndex == 0 {
                                    print(indexToView)
                                    checkImageCaching(old, new, size: size)
                                }
                            }
                    }
                }
                .matchedGeometryEffect(id: "backGround", in: animationID)
                .overlay(alignment: .bottom, content: {
                    if (0..<assetArray.count).contains(indexToView) {
                        HStack {
                            AssetHandleMenu(
                                albumType: self.albumType,
                                assetCollection: assetCollection,
                                isHiddenAssets: isHiddenAssets,
                                asset: assetArray[indexToView],
                                reLoadingType: $reLoadingType,
                                selectedItems: $selectedItems
                            )
                                .padding(.horizontal, vcHorisontalPadding)
                                .frame(width: geo.size.width / (device == .pad ? 3 : 1))
                                .disabled(assetArray.isEmpty)
                            if device == .pad {
                                Spacer()
                            }
                        }
                        .offset(y: hideToolbar ? (vcHeight + 10) : -(vcBottomPadding + 5))
                        .opacity(assetArray.isEmpty ? 0.3 : 1)
                        .disabled(assetArray.isEmpty)
                    }
                })
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .statusBarHidden(hideToolbar)
                .toolbar(hideToolbar ? .hidden : .visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { closeButton }
                    ToolbarItem(placement: .principal) { Text(navigationTitle) }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        assetCountLabel(count: assetArray.count)
                    }
                }
            }
            .onDisappear {
                print("caching Delete in DetailView")
                DispatchQueue.global(qos: .background).async {
                    cachingManager.stopCachingImagesForAllAssets()
                }
            }
//            .onChange(of: removeAsset) { newValue in
//                if let id = newValue {
//                    if let index = self.assetArray.compactMap({ $0.id }).firstIndex(of: id) {
//                        dispatchAnimation {
//                            self.assetArray.remove(at: index)
//                        }
//                    }
//                    self.removeAsset = nil
//                }
//            }
        }
        .ignoresSafeArea()
        .modifier(
            InAppAlertModifier(notificationName: .showAlertInDetailView)
        )
        .modifier(
            InAppMoveAssetSheet(notificationName: .showMoveAssetSheetInDetailView))
        .modifier(
            InAppProgressView(notificationName: .showProgressingDetailView)
        )
    }
}


// MARK: - 2. extension [Asset handle Menu]
extension PhotosDetailView {
    func checkImageCaching(_ oldValue: Int, _ newValue: Int, size: CGSize) {
        if oldValue < newValue {
            if newValue-2 >= 0 {
                if assetArray[newValue-2].mediaType == .image {
                    phImageQueue.async {
                        manageImageCacing(size: size,
                                          assets: [assetArray[newValue-2].phAsset])
                        if newValue+2 < assetArray.count {
                            manageImageCacing(size: size,
                                              start: false,
                                              assets: [assetArray[newValue+2].phAsset])
                        }
                    }
                }
            }
        } else {
            if newValue+2 < assetArray.count {
                if assetArray[newValue+2].mediaType == .image {
                    phImageQueue.async {
                        manageImageCacing(size: size,
                                          assets: [assetArray[newValue+2].phAsset])
                        if newValue-2 > 0 {
                            manageImageCacing(size: size,
                                              start: false,
                                              assets: [assetArray[newValue-2].phAsset])
                        }
                    }
                }
            }
        }
    }
    var separator: some View {
        Text("|")
            .foregroundStyle(.white)
            .opacity(0.4)
    }
    func assetHandleMenuView(asset: MLAsset) -> some View {
        HStack(spacing: 3) {
            // 0. 삭제 버튼
            assetHandleButton(imageName: iconDelete, imageColor: Color.color1) {
                guard let album = photoData.albums[assetCollection.localIdentifier]
                else { return }
                dispatchAnimation {
                    NotificationCenter.default
                        .post(name: .showProgressingDetailView, object: "")
                }
                album.deleteAssetFromDevice(albumType: albumType,
                                            assets: [asset],
                                            isHiddenAsset: isHiddenAssets,
                                            isDetailView: true) { bool in
                    if bool {
                        notifyAndRemoveAsset(asset: asset)
                    }
                    dispatchAnimation {
                        NotificationCenter.default
                            .post(name: .showProgressEndDetailView, object: nil)
                    }
                }
            }
            
            separator
            if albumType == .home || albumType == .smartAlbum {
                // 1-1. 앨범에 추가 버튼
                assetHandleButton(imageName: iconInsertToAlbum) {
                    let moveAssetObject = MoveAssetObject(
                        albumType: self.albumType,
                        currentAlbum: assetCollection,
                        selectedItems: [asset],
                        isHidden: isHiddenAssets)
                    NotificationCenter.default
                        .post(name: .showMoveAssetSheetInDetailView,
                              object: moveAssetObject)
                }
            } else if albumType == .album {
                // 1-2-1. 앨범에서 빼기 버튼
                assetHandleButton(imageName: "rectangle.stack.badge.minus") {
                    dispatchAnimation {
                        NotificationCenter.default
                            .post(name: .showProgressingDetailView, object: "")
                    }
                    let alertObject = AlertObject(
                        alertCase: .mediaTakeFromAlbum,
                        album: assetCollection,
                        folder: nil,
                        selectedItems: [asset],
                        isDetailView: true)
                    DispatchQueue.main.async {
                        NotificationCenter.default
                            .post(name: .showAlertInDetailView, object: alertObject)
                    }
                }
                separator
                // 1-2-2. 앨범 이동 버튼
                assetHandleButton(isImage: false, titleName: "이동") {
                    let moveAssetObject = MoveAssetObject(
                        albumType: self.albumType,
                        currentAlbum: assetCollection,
                        selectedItems: [asset],
                        isHidden: isHiddenAssets,
                        isDetailView: true)
                    DispatchQueue.main.async {
                        NotificationCenter.default
                            .post(name: .showMoveAssetSheetInDetailView,
                                  object: moveAssetObject)
                    }
                }
            }
            Spacer()
            if !isHiddenAssets {
                // 2-1. 가리기 버튼
                assetHandleButton(imageName: iconHide, imageColor: .gray) {
                    dispatchAnimation {
                        NotificationCenter.default
                            .post(name: .showProgressingDetailView, object: "")
                    }
                    guard let album = photoData.albums[assetCollection.localIdentifier] else { return }
                    album.hideOrUnhideAsset(assets: [asset],
                                            toHide: true,
                                            isDetailView: true) { bool in
                        if bool {
                            notifyAndRemoveAsset(asset: asset)
                        }
                        dispatchAnimation {
                            NotificationCenter.default
                                .post(name: .showProgressEndDetailView, object: nil)
                        }
                    }
                }
            } else {
                // 2-2. 가리기 해제 버튼
                assetHandleButton(imageName: iconUnhide, imageColor: .gray) {
                    dispatchAnimation {
                        NotificationCenter.default
                            .post(name: .showProgressingDetailView, object: "")
                    }
                    let alertObject = AlertObject(alertCase: .mediaUnhide,
                                                  album: assetCollection,
                                                  folder: nil,
                                                  selectedItems: [asset],
                                                  isHiddenAsset: isHiddenAssets,
                                                  isDetailView: true)
                    dispatchAnimation {
                        NotificationCenter.default
                            .post(name: .showAlertInDetailView, object: alertObject)
                        }
                    }
            }
            separator
            assetHandleButton(
                // 즐겨찾기 버튼
                imageName: asset.isFavorite ? iconFavorite : iconNotFavorite,
                imageColor: asset.isFavorite ? .color1 : .gray) {
                    guard let album = photoData.albums[assetCollection.localIdentifier] else { return }
                    if let _ = assetArray.firstIndex(of: asset) {
                        album.favoriteAsset(toFavorite: !asset.isFavorite,
                                            assets: [asset],
                                            isHiddenAsset: self.isHiddenAssets) { bool in
                            dispatchAnimation {
                                NotificationCenter.default
                                    .post(name: .itemChanged, object: asset)
                            }
                            print(asset.isFavorite)
                        }
                    }
            }
            // 3. 공유 버튼
//            separator
//                .opacity(0.2)
//            assetHandleButton(imageName: "square.and.arrow.up", imageColor: .gray) {
//            }
        }
        .foregroundStyle(.gray)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.black)
                .frame(height: vcHeight)
        }
    }
    
    func notifyAndRemoveAsset(asset: MLAsset) {
        dispatchAnimation {
            NotificationCenter.default
                .post(name: .innerFetchChange, object: assetCollection.localIdentifier)
            NotificationCenter.default
                .post(name: .innerFetchChange, object: "myPhotos")
        }
    }
    
    // detail View 닫기 버튼
    var closeButton: some View {
        Button {
            withAnimation {
                self.isExpanded = false
            }
        } label: {
            Image(systemName: "xmark")
                .imageScale(.medium)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .frame(width: 50, height: 40, alignment: .center)
        }
    }
    
    func assetCountLabel(count: Int) -> some View {
        Text("(\(indexToView + 1) / \(count))")
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.top, 5)
            .opacity(count == 0 ? 0 : 1)
    }
    
    @ViewBuilder
    func detailView(currentAsset: MLAsset,
                    offsetIndex: Int,
                    pageIndex: Int,
                    size: CGSize,
                    cachingManager: PHCachingImageManager,
                    animationID: Namespace.ID) -> some View {
        Group {
            if currentAsset.mediaType == .image {
                ImageDetailView(asset: currentAsset,
                                imageManager: cachingManager,
                                size: size,
                                enableZoom: true,
                                variableScale: $variableScale,
                                currentScale: $currentScale,
                                offsetY: $offsetY)
                .scaleEffect(variableScale)
                .gesture(
                    TapGesture(count: 2)
                        .exclusively(before: hideGesture)
                )
                
            } else if currentAsset.mediaType == .video {
                VideoDetailView(offsetIndex: offsetIndex,
                                asset: currentAsset,
                                imageManager: cachingManager,
                                size: size,
                                play: $play,
                                hideTools: $hideToolbar,
                                userGesture: $userGesture,
                                offsetY: $offsetY,
                                offsetX: $offsetX)
                .ignoresSafeArea()
            }
        }
        .id(currentAsset.id)
        .offset(x: 0, y: offsetY)
        .onAppear(perform: {
            if offsetIndex == 0 {
                navigationTitle = timeFormmatter(asset: currentAsset)
            }
        })
        .onChange(of: offsetIndex) { newValue in
            changeNavigationTitle(asset: currentAsset,
                                  newValue,
                                  pageIndex: pageIndex)
        }
    }
    
}

// MARK: - 3. extension [Funcitons]
extension PhotosDetailView {
    func changeNavigationTitle(asset: MLAsset, _ newValue: Int, pageIndex: Int) {
        if newValue == 0 {
            indexToView = pageIndex
            navigationTitle = timeFormmatter(asset: asset)
        }
    }
    
    func manageImageCacing(size: CGSize, start: Bool = true, assets: [PHAsset]) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        
        for i in assets {
            let assetRatio = CGFloat(i.pixelHeight) / CGFloat(i.pixelWidth)
            let screenRatio = size.height / size.width
            let widthIsCreteria = assetRatio <= screenRatio
            
            let creteriaSize = (widthIsCreteria ? size.width : size.height) * scale
            let size = CGSize(width: widthIsCreteria ? creteriaSize : .infinity,
                              height: widthIsCreteria ? .infinity : creteriaSize)
            if start {
//                dispatchAnimation {
                    cachingManager.startCachingImages(for: assets,
                                                    targetSize: size,
                                                    contentMode: .aspectFit,
                                                    options: options)
//                }
            } else {
                cachingManager.startCachingImages(for: assets,
                                                  targetSize: size,
                                                  contentMode: .aspectFit,
                                                  options: options)
            }
        }
        
    }
    
    func timeFormmatter(asset: MLAsset, isDate: Bool = true) -> String {
        let fommatter = DateFormatter()
        fommatter.locale = Locale(identifier: "ko_KR")
        fommatter.dateFormat = isDate ? "yyyy년 MM월 dd일" : "a hh:mm"
        let date = fommatter.string(from: asset.creationDate)
        return date
    }
}
// MARK: - 4. extenstion [Gestures]
extension PhotosDetailView {
    // navigationtitle & customPlayBack hidden 토글
    private var hideGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                if userGesture == .none {
                    withAnimation(.easeOut(duration: 0.1)) {
                        self.hideToolbar.toggle()
                    }
                }
            }
    }
    
    var zoomGestureByPinch: some Gesture {
        MagnificationGesture()
            .onChanged { value in
//                if !isUserSwiping {
                    self.variableScale = currentScale * value.magnitude
//                }
            }
//            .onEnded { value in
//                if !isUserSwiping && userGesture != .dismissingView {
//                    if self.variableScale >= 1 && self.variableScale <= 2 {
//                        self.variableScale = currentScale * value.magnitude
//                    } else  if variableScale > 2 {
//                        withAnimation { self.variableScale = 2 }
//                    } else {
//                        withAnimation { self.variableScale = 1 }
//                    }
//                    currentScale = self.variableScale
//                }
//            }
    }
    
    func assetHandleButton(isImage: Bool = true,
                           imageName: String = "",
                           titleName: String = "",
                           buttonColor: Color! = nil,
                           imageColor: Color! = .white,
                           action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(.black)
                .frame(width: 40, height: 30)
                .overlay {
                    if isImage {
                        Image(systemName: imageName)
                            .foregroundStyle(imageColor)
                            .imageScale(.medium)
                    } else {
                        Text(titleName)
                    }
                }
        }
    }
    
}

//struct PhotosDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotosDetailView(indexToView: .constant(0),
//                         isExpanded: .constant(true),
//                         navigationTitle: "photos")
//            .preferredColorScheme(.dark)
//    }
//}

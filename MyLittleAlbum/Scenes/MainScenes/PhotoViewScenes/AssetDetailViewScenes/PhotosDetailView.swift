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
    case paging, videoSeeking, soundAdjusting, dismissingView, hideTools, none, magnifying
}

// MARK: - 1. BODY
struct PhotosDetailView: View {
    @EnvironmentObject var photoData: MLPhotoData
    let albumType: AlbumType
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
    
    @Binding var reLoadingType: ReLoadingType
    @Binding var selectedItems: [MLAsset]
    @State var copyDone: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            NavigationStack {
                RecyclePageView(count: assetArray.count,
                                 indexToView: $indexToView,
                                 isExpanded: $isExpanded,
                                 userGesture: $userGesture,
                                 hideToolBar: $hideToolbar,
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
                                    checkImageCaching(old, new, size: size)
                                }
                            }
                    }
                }
                .matchedGeometryEffect(id: "backGround", in: animationID)
                .overlay(alignment: .bottom, content: {
                    if (0..<assetArray.count).contains(indexToView) {
                        VStack {
                            if copyDone {
                                Text("사진을 클릭보드에 복사하였습니다.")
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundStyle(.thinMaterial)
                                    }
                                    .padding(.bottom, 20)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation {
                                                self.copyDone = false
                                            }
                                        }
                                    }
                            }
                            HStack {
                                AssetHandleMenu(
                                    albumType: self.albumType,
                                    assetCollection: assetCollection,
                                    isHiddenAssets: isHiddenAssets,
                                    asset: assetArray[indexToView],
                                    reLoadingType: $reLoadingType,
                                    selectedItems: $selectedItems,
                                    copyDone: $copyDone)
                                    .padding(.horizontal, vcHorisontalPadding)
                                    .frame(width: geo.size.width / (device == .pad ? 3 : 1))
                                    .disabled(assetArray.isEmpty)
                                if device == .pad {
                                    Spacer()
                                }
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
                    ToolbarItem(placement: .principal) {
                        getNavigatinoTitle(asset: assetArray[indexToView])
                    }
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
            InAppAlertModifier(notificationName: .showAlertInDetailView))
        .modifier(
            InAppMoveAssetSheet(notificationName: .showMoveAssetSheetInDetailView))
        .modifier(
            InAppProgressView(notificationName: .showProgressingDetailView))
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
//        .onAppear(perform: {
//            if offsetIndex == 0 {
//                navigationTitle = timeFormmatter(asset: currentAsset)
//            }
//        })
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
                cachingManager.startCachingImages(for: assets,
                                                targetSize: size,
                                                contentMode: .aspectFit,
                                                options: options)
            } else {
                cachingManager.startCachingImages(for: assets,
                                                  targetSize: size,
                                                  contentMode: .aspectFit,
                                                  options: options)
            }
        }
        
    }
    
    func getNavigatinoTitle(asset: MLAsset, isDate: Bool = true) -> some View {
        let fommatter = DateFormatter()
        fommatter.locale = Locale(identifier: "ko_KR")
        fommatter.dateFormat = isDate ? "yyyy년 MM월 dd일" : "a hh:mm"
        let date = fommatter.string(from: asset.creationDate)
        return Text(date)
            .foregroundStyle(.white)
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
}

//struct PhotosDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotosDetailView(indexToView: .constant(0),
//                         isExpanded: .constant(true),
//                         navigationTitle: "photos")
//            .preferredColorScheme(.dark)
//    }
//}

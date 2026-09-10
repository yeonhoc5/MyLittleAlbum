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
  case none,
       paging,
       dismissingView,
       videoSeeking,
       soundAdjusting,
       magnifying
}

enum Creteria {
  case width, height
}

enum WorkState {
  case delete, addSubtrack, move, favorite, hide, copy, none
}

// MARK: - 1. BODY
struct PhotosDetailView: View {
  let albumType: AlbumType
  let localID: String
  let isHiddenAssets: Bool
  @State var assetArray: [MLAsset]
  let thumbnailManager: PHCachingImageManager
  var animationID: Namespace.ID

  @Binding var isExpanded: Bool
  @Binding var indexToView: Int
  @State var currentMedia: UIImage?
  // 페이지
  @State var hideToolbar: Bool = false
  // 이미지
  @State var variableScale: CGFloat = 1
  @State var currentScale: CGFloat = 1
  // 비디오
  @State var playStatus: VideoState = .stop
  @State var videoMove: VideoMove = .none
  @State var mute: Bool = false
  @State var landscapeVideo: Bool = false
  @State var userGesture: DetailViewGesture = .none
  @State var currentTime: Double = .zero
  @GestureState var play2x: Bool = false
  // cacing
  let cachingManager = PHCachingImageManager()
  
  @State var copyDone: Bool = false
  @State var scaled: Bool = false
  
  @State var zoomPoint: UnitPoint = .zero
  @State var tappedPoint: CGPoint = .zero
  @State var preZoomOffset: CGSize = .zero
  @State var zoomOffset: CGSize = .zero
  
  @State var workState: WorkState = .none
  @State var assetChanged: Bool = false
  @State var changedAssets: [MLAsset] = []
  @State var assetAlert: AssetAlert!
  @State var isShowingMoveAssetSheet: Bool = false
  @State var moveAssetObject: MoveAssetObject!
  let completion: (Bool, [MLAsset], Int) -> Void
  @Environment(\.openURL) var openURL
  
  var body: some View {
    GeometryReader { geometry in
      let totalCount = assetArray.count
      let currentAsset = assetArray[indexToView]
      let assetInfo = AssetInfo(
        mediaType: currentAsset.mediaType,
        size: CGSize(width: currentAsset.phAsset.pixelWidth,
                     height: currentAsset.phAsset.pixelHeight)
      )
      let hide = hideToolbar || (assetInfo.mediaType == .video
                                 && landscapeVideo)
      NavigationStack {
        RecyclePageView(isExpanded: $isExpanded,
                        indexToView: $indexToView,
                        geometry: geometry,
                        count: totalCount,
                        assetInfo: assetInfo,
                        userGesture: $userGesture,
                        hideToolBar: $hideToolbar,
                        scale: $variableScale,
                        landscapePlay: $landscapeVideo) {
          endDetailView(index: indexToView)
        } content: { offsetIndex, pageIndex in
          if pageIndex < totalCount && pageIndex >= 0 {
            detailView(offsetIndex: offsetIndex,
                       pageIndex: pageIndex,
                       geometry: geometry,
                       cachingManager: cachingManager,
                       animationID: animationID)
          }
        }
        .onChange(of: indexToView) { [old = indexToView] new in
          DispatchQueue.main.async {
            currentTime = 0
          }
//          checkImageCaching(old, new, size: geo.size)
          controllStatus(current: playStatus)
        }
        .background(content: { Color.black })
        .overlay(alignment: .leading, content: {
          let isVideo = assetInfo.mediaType == .video
          let isPad = device == .pad
          if landscapeVideo && isVideo {
            VideoControllBar(isVideo: isVideo,
                             isPad: isPad,
                             duration: currentAsset.duration,
                             playStatus: $playStatus,
                             videoMove: $videoMove,
                             currentTime: $currentTime,
                             mute: $mute,
                             play2x: play2x,
                             landscapePlay: $landscapeVideo,
                             userGesture: $userGesture)
            .frame(width: vcHeight-1)
            .matchedGeometryEffect(id: "controllbar",
                                   in: animationID)
            .padding(.top, safeAreaTopPadding + 10)
            .padding(.leading, 15)
            .padding(.bottom, tabbarHeight + 10)
            .offset(x: hideToolbar ? -(vcHeight * 2) : 0)
            .animation(.spring(response: isPad ? 0.4 : 0.25,
                               dampingFraction: 0.9,
                               blendDuration: 0.8),
                       value: isVideo)
          }
        })
        .overlay(alignment: .bottomLeading,
                 content: {
          if (0..<totalCount).contains(indexToView) {
            assetHandleAndVideoController(
              geo: geometry,
              asset: currentAsset
            )
          }
        })
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .modify({ view in
          if #available(iOS 18.0, *) {
            view
              .toolbarBackground(.black.opacity(0.5), for: .navigationBar)
              .toolbarBackground(.visible, for: .navigationBar)
          } else {
            view
              .overlay(alignment: .top) {
                let height = safeAreaTopPadding
                Rectangle()
                  .foregroundStyle(.black.opacity(0.5))
                  .frame(height: height)
                  .ignoresSafeArea()
                  .offset(y: hideToolbar ? -(height * 2) : 0)
              }
          }
        })
        .statusBarHidden(hide)
        .toolbar(hide ? .hidden : .visible, for: .navigationBar)
        .toolbar {
          closeButton(index: indexToView)
          centerDateTitleView(asset: currentAsset)
          openInPhotos(asset: currentAsset)
        }
      }
      .onDisappear {
        DispatchQueue.global(qos: .background).async {
          cachingManager.stopCachingImagesForAllAssets()
        }
        print("caching Delete in DetailView")
      }
    }
    //    .overlay(alignment: .top, content: {
    //      navigationBlurView(height: safeAreaTopPadding, color: .black)
    //    })
    .ignoresSafeArea()
//    .rotationEffect(landscapeVideo ? .degrees(90) : .zero)
    .modifier(
      AssetAlertModifier(assetAlert: $assetAlert,
                         completion: { bool in
                           actionAfterAlert(assetRemoved: bool)
                         })
    )
//    .modifier(
//      InAppMoveAssetSheet(
//        assetMoved: { bool in
//          actionAfterMoveSheet(assetRemoved: bool)
//        }))
    .modifier(
      InAppProgressView(
        notificationName: .showProgressingDetailView)
    )
  }
}

// MARK: - 2. extension [Asset handle Menu]
extension PhotosDetailView {
  func openInPhotos(asset: MLAsset) -> some ToolbarContent {
    let assetUuid = asset.phAsset.localIdentifier.prefix(while: { $0 != "/" })
    print(assetUuid)
    let collectionUuid = localID.prefix(while: { $0 != "/" })
    print(collectionUuid)
    let urlString = "photos-navigation://Finned/favorites"
    return ToolbarItem(placement: .topBarTrailing) {
      Button {
        if let url = URL(string: urlString) {
          openURL(url)
        }
      } label: {
        IconPhotos(lineWidth: 2)
          .frame(width: 25, height: 25)
      }

//      if let url = URL(string: urlString) {
//        Link(destination: url) {
//          IconPhotos(lineWidth: 2)
//            .frame(width: 25, height: 25)
//        }
//      }
    }
  }
  
  func actionAfterAlert(assetRemoved: Bool) {
    if assetRemoved {
      removeCurrentAsset()
    }
    dispatchAnimation {
      workState = .none
    }
  }
  func actionAfterMoveSheet(assetRemoved: Bool) {
    if assetRemoved {
      removeCurrentAsset()
    } else {
      if playStatus == .processPause {
        playStatus = .play
      }
    }
  }
  func removeCurrentAsset() {
    dispatchAnimation {
      assetChanged = true
      assetArray.remove(at: indexToView)
    }
  }
  func endDetailView(index: Int) {
    dispatchAnimation {
      self.isExpanded = false
      completion(assetChanged, changedAssets, index)
    }
  }
  func controllStatus(current: VideoState) {
    if current != .stop {
      let temp = current
      playStatus = .stop
      if temp == .play {
        DispatchQueue.main
          .asyncAfter(deadline: .now() + 0.3) {
            playStatus = .play
          }
      }
    }
  }
  func centerDateTitleView(asset: MLAsset) -> some ToolbarContent {
    ToolbarItem(placement: .principal) {
      if indexToView < assetArray.count {
        VStack {
          getNavigationTitle(asset: asset)
          getNavigationTitle(asset: asset, isTime: true)
        }
        .contentTransition(.numericText())
      } else {
        Text("(Empty)")
      }
    }
  }
  func assetHandleAndVideoController(geo: GeometryProxy,
                                     asset: MLAsset) -> some View {
    let isPad = device == .pad
    let videoNeeds = checkVideoNeeds(size: geo.size,
                                     asset: asset.phAsset)
    let isVideo = asset.mediaType == .video
    let hideHandler = (isVideo && landscapeVideo) || hideToolbar
    return ZStack(alignment: .bottomLeading) {
      Group {
        if !landscapeVideo {
          HStack(spacing: 0) {
            if isPad && isVideo { Spacer() }
            VideoControllBar(isVideo: isVideo,
                             isPad: isPad,
                             duration: asset.duration,
                             playStatus: $playStatus,
                             videoMove: $videoMove,
                             currentTime: $currentTime,
                             mute: $mute,
                             play2x: play2x,
                             landscapePlay: $landscapeVideo,
                             userGesture: $userGesture)
            .matchedGeometryEffect(id: "controllbar", in: animationID)
            .opacity(isVideo ? 1 : 0)
            .modify({ view in
              if isPad {
                view.scaleEffect(scaled ? 1.02 : 1)
              } else {
                view.scaleEffect(x: scaled ? 1.04 : 1, y: scaled ? 1.2 : 1)
              }
            })
            .overlay(alignment: isPad ? .topLeading : .topTrailing) {
              assetCountLabel(count: assetArray.count)
                .offset(x: isPad ? 5 : -5, y: -20)
            }
            .tabBarLayout(height: vcHeight,
                          screenWidth: geo.size.width,
                          isPhotosView: true,
                          padEdge: .trailing)
            if isPad && !isVideo { Spacer() }
          }
          .opacity((videoNeeds == .opacity && hideToolbar) ? 0 : 1)
          .animation(.easeInOut,
                     value: needOpacity(asset: asset.phAsset,
                                        size: geo.size))
          .offset(y: (isVideo && !isPad)
                  ? (hideToolbar ? -(vcHeight * 2) : -(vcHeight + 10))
                  : 0)
          .animation(.spring(response: isPad ? 0.4 : 0.25,
                             dampingFraction: 0.9,
                             blendDuration: 0.8),
                     value: isVideo)
        }
        ZStack {
          AssetHandleMenu(
            media: currentMedia,
            albumType: self.albumType,
            localID: localID,
            isHiddenAssets: isHiddenAssets,
            isPad: isPad,
            asset: asset,
            playStatus: $playStatus,
            copyDone: $copyDone,
            assetAlert: $assetAlert,
            moveAssetObject: $moveAssetObject,
            isShowingMoveAssetSheet: $isShowingMoveAssetSheet,
            workState: $workState,
            removeAsset: {
              removeCurrentAsset()
            }, reloadAssets: { asset in
              if let _ = assetArray.firstIndex(of: asset) {
                if let aIndex = changedAssets.firstIndex(of: asset) {
                  self.changedAssets.remove(at: aIndex)
                } else {
                  self.changedAssets.append(asset)
                }
              }
            })
          .disabled(assetArray.isEmpty)
          .scaleEffect(scaled ? 1.02 : 1)
          copyDoneMessage
            .opacity(copyDone ? 1 : 0)
        }
        .tabBarLayout(height: vcHeight,
                      screenWidth: geo.size.width,
                      isPhotosView: true,
                      sidePadding: true,
                      padEdge: .leading)
      }
      .onChange(of: asset.mediaType,
                perform: { [oldValue = asset.mediaType] type in
        if #available(iOS 17.0, *) {
          if oldValue != type {
            withAnimation(.spring(response: 0.15,
                                  dampingFraction: 0.4,
                                  blendDuration: 0.3)) {
              scaled = true
            } completion: {
              withAnimation(
                .spring(response: 0.3,
                        dampingFraction: 0.2,
                        blendDuration: 0.2)) {
                          scaled = false
                        }
            }
          }
        }
      })
    }
    .padding(.bottom, (tabbarHeight - vcHeight) / 2)
    .offset(y: hideHandler ? (vcHeight * 2) : 0)
    .disabled(assetArray.isEmpty)
  }
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
  
  // detail View 닫기 버튼
  func closeButton(index: Int) -> some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        endDetailView(index: index)
      } label: {
        Image(systemName: "xmark")
          .imageScale(.medium)
          .foregroundColor(.white)
          .fontWeight(.semibold)
          .frame(width: 30, height: 40, alignment: .center)
      }
    }
  }
  
  func assetCountLabel(count: Int) -> some View {
    Text("\(indexToView + 1) / \(count)")
      .font(.footnote)
      .foregroundColor(.gray)
      .opacity(count == 0 ? 0 : (hideToolbar ? 0 : 1))
      .contentTransition(.numericText())
  }
  
  @ViewBuilder
  func detailView(offsetIndex: Int,
                  pageIndex: Int,
                  geometry: GeometryProxy,
                  cachingManager: PHCachingImageManager,
                  animationID: Namespace.ID) -> some View {
    let currentAsset = assetArray[pageIndex]
    Group {
      switch currentAsset.mediaType {
      case .video:
        let isCurrent = offsetIndex == 0
        let videoNeeds = checkVideoNeeds(size: geometry.size,
                                         asset: currentAsset.phAsset)
        VideoDetailView(
          offsetIndex: offsetIndex,
          asset: currentAsset,
          imageManager: cachingManager,
          geometry: geometry,
          playStatus: isCurrent ? $playStatus : .constant(.stop),
          videoMove: isCurrent ? $videoMove : .constant(.none),
          videoNeeds: videoNeeds,
          play2x: play2x,
          landscapeVideo: landscapeVideo,
          hideTools: hideToolbar,
          userGesture: isCurrent ? $userGesture : .constant(.none),
          currentTime: isCurrent ? $currentTime : .constant(0),
          tempView: {
            loadingView(size: geometry.size)
        })
        .simultaneousGesture(fastPlayGesture)
      default:
        ImageDetailView(asset: currentAsset,
                        imageManager: cachingManager,
                        geometry: geometry,
                        tempView: {
          loadingView(size: geometry.size)
        }) { image in
          if pageIndex == indexToView {
            self.currentMedia = image
          }
        }
      }
    }
    .id(currentAsset.id)
    .background(content: {
      GeometryReader { geo in
        Color.clear
      }
    })
    .simultaneousGesture(zoomGestureByPinch)
  }
  var copyDoneMessage: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .availabeGlassEffect(cornerR: 10,
                             foreground: .thinMaterial) { view in
          view
            .foregroundStyle(.thinMaterial)
        }
      Text("사진을 클립보드에 복사하였습니다.")
        .foregroundStyle(.white)
    }
  }
}

// MARK: - 3. extension [Funcitons]
extension PhotosDetailView {
  func loadingView(size: CGSize) -> some View {
    ProgressView()
      .tint(.white)
      .controlSize(.large)
      .progressViewStyle(.circular)
      .frame(width: size.width, height: size.height)
      .scaleEffect(0.8)
  }

  func assetHeight(asset: PHAsset, width: CGFloat) -> CGFloat {
    return width * CGFloat(asset.pixelHeight)
    / CGFloat(asset.pixelWidth)
  }
  
  func manageImageCacing(size: CGSize, start: Bool = true, assets: [PHAsset]) {
    let options = PHImageRequestOptions()
    options.deliveryMode = .opportunistic
    options.resizeMode = .exact
    options.isSynchronous = true
    options.isNetworkAccessAllowed = true
    
    for i in assets {
      let creteria = creteriaResult(
        screenSize: size,
        size: CGSize(width: i.pixelWidth, height: i.pixelHeight)
      )
      let creteriaSize = (creteria == .width ? size.width : size.height) * scale
      let anotherSize: CGFloat = (
        creteria == .width
        ? (CGFloat(i.pixelHeight) * size.width / CGFloat(i.pixelWidth))
        : (CGFloat(i.pixelWidth) * size.height / CGFloat(i.pixelHeight))
      ) * scale
      let size = CGSize(width: creteria == .width
                        ? creteriaSize : anotherSize,
                        height: creteria == .height
                        ? creteriaSize : anotherSize)
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
  
  func getNavigationTitle(asset: MLAsset, isTime: Bool = false) -> some View {
    let fommatter = DateFormatter()
    fommatter.locale = Locale(identifier: "ko_KR")
    fommatter.dateFormat = isTime ? "HH:mm" : "yyyy년 MM월 dd일"
    let date = fommatter.string(from: asset.creationDate)
    return Text(date)
      .foregroundStyle(isTime ? .gray : .white)
      .font(isTime ? .caption : .body)
  }
}
// MARK: - 4. extenstion [Gestures]
extension PhotosDetailView {
  // video fast play gesture
  var fastPlayGesture: some Gesture {
    LongPressGesture(minimumDuration: 0.5)
      .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
      .updating($play2x) { value, gestureState, _ in
        switch value {
        case .second(true, nil):
          gestureState = true
          let hapticManager = HapticManager.instance
          hapticManager.impact(style: .light)
        default: break
        }
      }
  }
  
  var zoomGestureByPinch: some Gesture {
    if #available(iOS 17.0, *) {
      return MagnifyGesture()
        .onChanged { value in
          if userGesture == .none {
            userGesture = .magnifying
            self.zoomPoint = value.startAnchor
          }
          withAnimation {
            self.variableScale = currentScale * value.magnification
            //            self.zoomOffset = CGSize(
            //                width: zoomPoint.x - value.startLocation.x,
            //                height: zoomPoint.y - value.startLocation.y
            //            )
          }
        }
        .onEnded { value in
          if userGesture == .magnifying {
            if self.variableScale >= 1 && self.variableScale <= 5 {
              self.variableScale = currentScale * value.magnification
            } else  if variableScale > 5 {
              withAnimation {
                self.variableScale = 5
              }
            } else {
              withAnimation {
                variableScale = 1.0
                zoomOffset = .zero
                preZoomOffset = .zero
              }
            }
            userGesture = .none
            currentScale = self.variableScale
          }
        }
    } else {
      return MagnificationGesture()
        .onChanged { value in
          if userGesture != .paging {
            self.variableScale = currentScale * value.magnitude
          }
        }
        .onEnded { value in
          if userGesture == .none {
            if self.variableScale >= 1 && self.variableScale <= 5 {
              self.variableScale = currentScale * value.magnitude
            } else  if variableScale > 5 {
              withAnimation { self.variableScale = 5 }
            } else {
              withAnimation { self.variableScale = 1 }
            }
            currentScale = self.variableScale
          }
        }
    }
  }
  func assetSize(geometry: GeometryProxy, asset: MLAsset) -> CGSize {
    let ratio = geometry.size.width / CGFloat(asset.phAsset.pixelWidth)
    return CGSize(
      width: CGFloat(asset.phAsset.pixelWidth) * ratio,
      height: CGFloat(asset.phAsset.pixelHeight) * ratio
    )
  }
  func needOpacity(asset: PHAsset, size: CGSize) -> Bool {
    let assetHeight = size.width * CGFloat(asset.pixelHeight)
                    / CGFloat(asset.pixelWidth)
    return size.height
        - assetHeight
        - statusBarHeight
        <= tabbarHeight
  }
  func checkVideoNeeds(size: CGSize, asset: PHAsset) -> VideoNeeds {
    let width = landscapeVideo ? size.height : size.width
    let height = landscapeVideo ? size.width : size.height
    let assetHeight = width * CGFloat(asset.pixelHeight)
    / CGFloat(asset.pixelWidth)
    let emptySpace = height - statusBarHeight - assetHeight
    let bottomSpace = (height - assetHeight) / 2
    let bottomPadding = vcBottomPadding + vcHeight + 15
    if bottomSpace - bottomPadding >= 0 {
      return .none
    } else if emptySpace - bottomPadding >= 0 {
      return .offset
    } else {
      return .opacity
    }
  }
}

struct PhotosDetailView_Previews: PreviewProvider {
  static var previews: some View {
    PhotosDetailView(albumType: .album,
                     localID: "home",
                     isHiddenAssets: false,
                     assetArray: [],
                     thumbnailManager: PHCachingImageManager(),
                     animationID: Namespace().wrappedValue,
                     isExpanded: .constant(true),
                     indexToView: .constant(0),
                     completion: { _, _, _ in
      
    })
    .preferredColorScheme(.dark)
  }
}

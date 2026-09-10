//
//  PhotoView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
import LocalAuthentication
import VariableBlur

struct AllPhotosView: View {
  @Environment(\.scenePhase) var scenePhase
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var photoData: MLPhotoData
  @ObservedObject var mlAlbum: MLAlbum
  let isHiddenAsset: Bool
  let nameSpace: Namespace.ID
  @Namespace var allPhotosNamespace
  @Binding var isPhotosView: Int
  let imageManager = PHCachingImageManager()
  // view state
  @State var inited: Bool = false
  @State var edgeToScroll: EdgeToScroll = .none
  @State var isReadyVolumeSort: Bool = false
  @State var readyCount: Int = 0
  @State var emptyText: String = ""
  // selectMode
  @State var isSelectMode: Bool = false
  @State var selectedItems: [MLAsset] = []
  @State var isSelectingBySwipe: Bool = false
  @State var isUnionMode: Bool = true
  @State var swipeSelectedItems: [MLAsset] = []
  // view Redraw
  @State var isShowingFilter: Bool = false
  @State var filtering: Filtering = Filtering()
  @State var reLoadingType: ReLoadingType = .none
  // detailView
  @State var isExpanded = false
  @State var indexToView: Int = 0
  // show Hidden asset view
  @State var knockCount: Int = 0
  @State var showEmptyHiddenAsset: Bool = false
  @State var isReadyHiddenAsset: Bool = false
  @State var showHiddenAssets: Bool = false
  // sheet
  @State var assetAlert: AssetAlert!
  @State var moveAssetObject: MoveAssetObject!
  @State var isShowingShareSheet: Bool = false
  @State var isShowingPhotosPicker: Bool = false
  @State var isShowingMoveAssetSheet: Bool = false
  //to refresh
  @State var refreshItems: [MLAsset] = []
  @State var assetChanged: Bool = false
  @State var pointedAsset: UIImage? = nil

  let viewCompletion: (Bool) -> Void
  
  var body: some View {
    let assetArray = filteredAssetArray()
    return GeometryReader { geoProxy in
      let columnCount = columnCount(geoProxy: geoProxy)
      let cellWidth = (geoProxy.size.width - CGFloat(columnCount - 1)) / CGFloat(columnCount)
      ZStack(alignment: .bottomTrailing) {
        // background
        FancyBackground()
        if isHiddenAsset {
          availableGlassCardView(cornerR: 38)
        }
//        Color.white
        collectionView(geoProxy: geoProxy,
                       cellWidth: cellWidth,
                       assetArray: assetArray.filtered)
//        ratioChecker  // 화면 비율 체커
        VariableBlurView(maxBlurRadius: 3,
                         direction: .blurredBottomClearTop)
          .frame(height: tabbarHeight * 2 + 25)
        photosGridMenu(size: geoProxy.size,
                       assetArray: assetArray)
        .padding(.bottom, (device == .phone)
                 ? (tabbarHeight + 10) : 0)
      }
      .navigationDestination(isPresented: $showHiddenAssets,
                             destination: {
        AllPhotosView(mlAlbum: mlAlbum,
                      isHiddenAsset: true,
                      nameSpace: nameSpace,
                      isPhotosView: $isPhotosView,
                      viewCompletion: { assetChanged in
          if #available(iOS 18.0, *) {
            if assetChanged {
              dispatchAnimation {
                self.reLoadingType = .reFetchInside
              }
              mlAlbum.unSetHiddenAssets {
                print("hiddenAssets Removed")
              }
            }
          }
        })
        .interactiveDismissDisabled(true) 
        .modify { view in
          if #available(iOS 18.0, *) {
            view
              .navigationTransition(
                .zoom(sourceID: "centerCardView", in: nameSpace)
              )
          } else {
            view
          }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              withAnimation {
                showHiddenAssets = false
              }
            } label: {
              Image(systemName: "xmark")
            }

          }
        }
      })
      .overlay(content: {
        if filtering.sort == .byVolume && !isReadyVolumeSort {
          PercentageView(readyCount: readyCount,
                         allCount: assetArray.filtered.count,
                         nameSpace: allPhotosNamespace) {
          }
        }
      })
      .modify({ view in
        navigationTitleToolbar(view: view)
      })
      .overlay(alignment: .center, content: {
//        ZStack(alignment: .top) {
//          navigationBlurView(height: safeAreaTopPadding)
          if showEmptyHiddenAsset {
            emptyNoticeView(cellWidth: cellWidth)
              .offset(y: 130)
              .onAppear {
                dispatchAnimationDelay(delay: 1.5) {
                  showEmptyHiddenAsset = false
                }
              }
          }
//        }
      })
    }
    .ignoresSafeArea(.all)
    .ignoresSafeArea(.keyboard)
    .fullScreenCover(isPresented: $isExpanded,
                     onDismiss: {
      dispatchAnimation {
        self.isExpanded = false
      }
    }, content: {
      PhotosDetailView(
        albumType: mlAlbum.albumType,
        localID: mlAlbum.id,
        isHiddenAssets: self.isHiddenAsset,
        assetArray: assetArray.filtered,
        thumbnailManager: imageManager,
        animationID: allPhotosNamespace,
        isExpanded: $isExpanded,
        indexToView: $indexToView) { assetRemoved, assets, index in
          dispatchAnimation {
            isExpanded = false
          }
          print("assetRemoved in DetailView?: \(assetRemoved)")
          if assetRemoved {
            print("reload all")
            dispatchAnimation {
              self.reLoadingType = .reFetchInside
            }
          } else if !assets.isEmpty {
            print("reload selected")
            dispatchAnimation {
              selectedItems = assets
              self.reLoadingType = .itemChangedInside
            }
          }
//          DispatchQueue.main.async {
//            print("ended? \(indexToView)")
            self.edgeToScroll = .number
//          }
        }
    })
    .modifier(
      AssetAlertModifier(assetAlert: $assetAlert,
                         completion: { assetRemoved in
                           reloadingAssets(changed: assetRemoved)
                           mlAlbum.processingChange(bool: false)
                         })
    )
    .modifier(
      InAppPhotosPicker(
        openMLAlbumID: mlAlbum.id,
        isShowingPhotosPicker: $isShowingPhotosPicker,
        nameSpace: nameSpace,
        completion: { addedAssets in
          if !addedAssets.isEmpty {
            addAssetsIntoAlbum(addedAssets: addedAssets)
          }
        })
    )
    .modifier(
      InAppMoveAssetSheet(
        isShowingMoveAssetSheet: $isShowingMoveAssetSheet,
        moveAssetObject: $moveAssetObject,
        assetMoved: { bool in
          if bool {
            if mlAlbum.albumType == .home {
              mlAlbum.processingChange(bool: true)
            }
            reloadingAssets(changed: bool)
          }
        })
    )
    .onReceive(NotificationCenter.default
      .publisher(for: .innerFetchChange), perform: { output in
        if reLoadingType != .reFetchInside {
          if mlAlbum.id == output.object as? String {
            print("\(mlAlbum.title) innerfetch Recieved")
            self.reLoadingType = .reFetchInside
          }
        }
      })
    .onReceive(NotificationCenter.default
      .publisher(for: .outsideFetchChange), perform: { object in
        if reLoadingType != .reFetchOutside {
          if mlAlbum.id == object.object as? String {
            self.reLoadingType = .reFetchInside
          }
        }
      })
    .onReceive(NotificationCenter.default
      .publisher(for: .assetChanged), perform: { output in
        if let object = output.object as? ChangedItem {
          if object.albumType == mlAlbum.albumType {
            DispatchQueue.main.async {
              self.refreshItems = object.assets
                .filter({ mlAlbum.photosArray.contains($0) })
              self.reLoadingType = .itemChangedOutside
            }
          }
        }
      })
    //        .onReceive(NotificationCenter.default
    //            .publisher(for: .collectionRemoved), perform: { object in
    //                guard let assetCollection = object.object as? PHAssetCollection
    //                else { return }
    //                if assetCollection.localIdentifier == mlAlbum.id {
    //                    dispatchAnimation {
    //                        dismiss()
    //                    }
    //                }
    //            })
//    .navigationDestination(isPresented: $showHiddenAssets,
//                           destination: {
//      AllPhotosView(mlAlbum: mlAlbum,
//                    isHiddenAsset: true,
//                    nameSpace: nameSpace,
//                    isPhotosView: $isPhotosView,
//                    viewCompletion: { assetChanged in
//        if #available(iOS 18.0, *) {
//          if assetChanged {
//            dispatchAnimation {
//              self.reLoadingType = .reFetchInside
//            }
//            mlAlbum.unSetHiddenAssets {
//              print("hiddenAssets Removed")
//            }
//          }
//        }
//      })
//    })
    .onDisappear(perform: {
      print("dismissed")
    })
    .onChange(of: scenePhase, perform: { value in
      //            if album.isHidden {
      //                if value == .background {
      //                    showAuthenticView = true
      //                }
      //            }
    })
    //    .overlay(content: {
    //        if showAuthenticView {
    //            notValidatedView
    //                .task {
    //                    DispatchQueue.main
    //                        .asyncAfter(deadline: .now() + 0.7) {
    //  //                                    authenticate(albumType: albumType)
    //                            authenticate(albumType: albumType) { bool in
    //
    //                            }
    //                        }
    //                }
    //        }
    //    })
    //  })
  }
}

struct TempView: View {
  let completion: () -> Void
  
  var body: some View {
    Rectangle()
      .foregroundStyle(.orange)
      .onDisappear {
        completion()
      }
  }
}

// MARK: - 1. extenstion. subviews
extension AllPhotosView {
  func modifyAlbumTitleButton() -> some View {
    Button {
      let alertObject = AlertObject(
        alertCase: .albumNameChange,
        folderType: .userFolder,
        albumID: mlAlbum.id,
        folderID: nil)
      NotificationCenter.default
        .post(name: .showAlert, object: alertObject)
    } label: {
      Image(systemName: iconModify)
        .scaledToFit()
    }
    .offset(y: -2)
  }
  func reloadingAssets(changed: Bool) {
    if changed {
      dispatchAnimation {
        if isHiddenAsset {
          self.assetChanged = true
        }
        self.reLoadingType = .reFetchInside
        if mlAlbum.albumType == .album {
          NotificationCenter.default
            .post(name: .outsideFetchChange, object: "myPhotos")
        }
      }
    }
  }
  func filteredAssetArray() -> (all: [MLAsset], filtered: [MLAsset]) {
    let assetArray = isHiddenAsset ? mlAlbum.hiddenArray : mlAlbum.photosArray
    if mlAlbum.albumType == .home {
      let subtracting = filtering.zero == .allAlbums
                      ? photoData.albumsPhotosSet() : []
      let homeAssets = assetArray
        .setSubtraing(by: isHiddenAsset ? [] : subtracting)
        .filter({ asset in
          if filtering.first == .allMedia {
            return true
          } else {
            return asset.mediaType == FilterFirst
              .trueType(type: filtering.first)
          }
        })
      return (homeAssets, assetArray
        .filter({ asset in
          if filtering.second == .favorite {
            return asset.isFavorite
          } else if filtering.second == .screenshot {
            return (asset
              .phAsset.mediaSubtypes
                      .contains(.photoScreenshot)
                    || asset
              .phAsset.mediaSubtypes
                      .contains(.videoScreenRecording)
            )
          } else {
            return true
          }
        })
        .sorted(by: { assetA, assetB in
          switch filtering.sort {
          case .byVolume:
            if assetA.volume != assetB.volume {
              return assetA.volume > assetB.volume
            }
            if assetA.phAsset.duration != assetB.phAsset.duration {
              return assetA.duration > assetB.phAsset.duration
            }
            return assetA.phAsset.pixelHeight > assetB.phAsset.pixelHeight
          case .byDate:
            return assetA.creationDate < assetB.creationDate
          }
        }))
    } else {
      return (assetArray, assetArray
        .filter({ asset in
        if filtering.first == .allMedia {
          return true
        } else {
          return asset.mediaType == FilterFirst
            .trueType(type: filtering.first)
        }
      })
      .filter({ asset in
        if filtering.second == .favorite {
          return asset.isFavorite
        } else if filtering.second == .screenshot {
          return (asset.phAsset
            .mediaSubtypes
            .contains(.photoScreenshot)
                  || asset.phAsset
            .mediaSubtypes
            .contains(.videoScreenRecording)
          )
        } else {
          return true
        }
      })
      .sorted(by: { assetA, assetB in
        switch filtering.sort {
        case .byVolume:
          if assetA.volume != assetB.volume {
            return assetA.volume > assetB.volume
          }
          if assetA.phAsset.duration != assetB.phAsset.duration {
            return assetA.duration > assetB.phAsset.duration
          }
          return assetA.phAsset.pixelHeight > assetB.phAsset.pixelHeight
        case .byDate:
          return assetA.creationDate < assetB.creationDate
        }
      }))
    }
  }
  
  func navigationTitleToolbar(view: some View) -> some View {
    view
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(content: {
        ToolbarItem(placement: .principal) {
          if mlAlbum.albumType == .home {
            let width: CGFloat = 150
            let height: CGFloat = 40
            let pickerPadding: CGFloat = 10
            HStack(alignment: .center) {
              Text("나의 사진\(isHiddenAsset ? "" : (filtering.zero == .allMedia ? "의" : "에서"))")
                .bold()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
              ZStack {
                Group {
                  if #available(iOS 26.0, *) {
                    Capsule()
                      .glassEffect(in: Capsule())
                  } else {
                    RoundedRectangle(cornerRadius: 7)
                  }
                }
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: width - (2 * pickerPadding),
                       height: height - (pickerPadding / 2))
                if isHiddenAsset {
                  Text("가려진 사진")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(Color.fancyBackground)
                } else {
                  // picker selected box의 각 패딩 10
                  Picker("",
                         selection: .constant(filtering.zero),
                         content: {
                    Group {
                      Text(FilterZero.string(type: .allMedia))
                        .tag(FilterZero.allMedia)
                      Text(FilterZero.string(type: .allAlbums))
                        .tag(FilterZero.allAlbums)
                    }
                    .font(.caption)
                    .bold()
                    .foregroundStyle(Color.fancyBackground)
                  })
                  .pickerStyle(.wheel)
                  .disabled(true)
                  .frame(width: width, height: height)
                  .padding(.horizontal, -pickerPadding)
                  .clipShape(RoundedRectangle(cornerRadius: 7))
                }
              }
            }
          } else {
            let title = mlAlbum.title
            Text("\(self.isHiddenAsset ? "🫣" : "")\(title == "" ? "(No Title)" : title)")
              .foregroundStyle(title == "" ? .gray : .white)
              .bold()
              .contentTransition(.numericText())
          }
        }
        if mlAlbum.albumType == .album {
          ToolbarItem(placement: .topBarTrailing) {
            modifyAlbumTitleButton()
          }
        }
      })
  }
  
  func collectionView(geoProxy: GeometryProxy,
                      cellWidth: CGFloat,
                      assetArray: [MLAsset]) -> some View {
    Group {
      if self.inited {
        NewPhotosCollectionView(
          mlAlbum: mlAlbum,
          albumType: mlAlbum.albumType,
          isHiddenAssets: isHiddenAsset,
          assetArray: assetArray,
          imageManager: imageManager,
          sampleImages: .constant([:]),
          geoProxy: geoProxy,
          cellWidth: cellWidth,
          edgeToScroll: $edgeToScroll,
          isReadyVolumeSort: $isReadyVolumeSort,
          isSelectMode: $isSelectMode,
          selectedItems: $selectedItems,
          isSelectingBySwipe: $isSelectingBySwipe,
          isUnionMode: $isUnionMode,
          swipeSelectedItems: $swipeSelectedItems,
          isShowingFilter: $isShowingFilter,
          filtering: $filtering,
          reLoadingType: $reLoadingType,
          isExpanded: $isExpanded,
          indexToView: $indexToView,
          isShowingPhotosPicker: $isShowingPhotosPicker,
          refreshItems: $refreshItems)
        .overlay {
          emptyInfoView()
            .padding(.bottom, tabbarHeight)
            .transition(.opacity)
        }
        .onDisappear {
          DispatchQueue.global(qos: .default).async {
            imageManager.stopCachingImagesForAllAssets()
          }
        }
      } else {
        tempView(geoProxy: geoProxy,
                 size: cellWidth * 1.5,
                 needAnimationView: isHiddenAsset
                 || mlAlbum.albumType == .home) {
          mlAlbum.fetchChecker(isHidden: isHiddenAsset) { bool in
            let delay = mlAlbum.albumType == .home ? 1 : 0.1
            if bool {
              DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation{
                  self.inited = true
                }
              }
              thumbnailCaching(width: cellWidth)
            } else {
              mlAlbum
                .generateArray(isHidden: isHiddenAsset) {
                  DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation{
                      self.inited = true
                    }
                  }
                thumbnailCaching(width: cellWidth)
              }
            }
          }
        }
      }
    }
  }
  
  func addAssetsIntoAlbum(addedAssets: [MLAsset]) {
    mlAlbum.addAsset(assets: addedAssets) { bool in
      if bool {
        dispatchAnimationDelay(delay: 0.5) {
          self.reLoadingType = .reFetchInside
          NotificationCenter.default
            .post(name: .outsideFetchChange, object: "myPhotos")
        }
      }
      mlAlbum.processingChange(bool: false)
    }
  }
  
  func photosGridMenu(
    size: CGSize, assetArray: (all: [MLAsset],
                               filtered: [MLAsset])) -> some View {
    PhotosGridMenu(mlAlbum: mlAlbum,
                   isShowingPhotosPicker: $isShowingPhotosPicker,
                   albumType: mlAlbum.albumType,
                   isHiddenAssets: isHiddenAsset,
                   assetArray: assetArray,
                   edgeToScroll: $edgeToScroll,
                   isShowingFilter: $isShowingFilter,
                   isReadyVolumeSort: $isReadyVolumeSort,
                   isReadyHiddenAsset: $isReadyHiddenAsset,
                   showHiddenAssets: $showHiddenAssets,
                   isSelectMode: $isSelectMode,
                   selectedItems: $selectedItems,
                   isSelectingBySwipe: $isSelectingBySwipe,
                   isUnionMode: $isUnionMode,
                   swipeSelectedItems: $swipeSelectedItems,
                   filtering: $filtering,
                   reLoadingType: $reLoadingType,
                   assetAlert: $assetAlert,
                   moveAssetObject: $moveAssetObject,
                   isShowingMoveAssetSheet: $isShowingMoveAssetSheet,
                   showEmptyNoticeView: $showEmptyHiddenAsset,
                   isPhotosView: $isPhotosView,
                   nameSpace: nameSpace,
                   allPhotosNamespace: allPhotosNamespace,
                   width: size.width,
                   readyCount: readyCount,
                   knockCount: knockCount) {
      knockingCenterBar()
    } sortByVolume: {
      readySortByVolume(assetArray: assetArray.filtered) {
        dispatchAnimation {
          self.refreshItems = assetArray.filtered
          self.isReadyVolumeSort = true
          dispatchAnimationDelay(delay: 0.5) {
            self.reLoadingType = .itemChangedOutside
            self.edgeToScroll = .top
          }
        }
      }
    } completion: { _ in }
    
  }
  
  var notValidatedView: some View {
    Rectangle()
      .foregroundColor(.fancyBackground)
      .overlay {
        VStack(spacing: 20) {
          Text("이 사진들을 보려면 사용자 권한이 필요합니다.")
            .foregroundColor(.gray)
          btnFaceID
            .onTapGesture {
              authenticate() { bool in
                if bool {
                  returnHiddenAssets(albumType: mlAlbum.albumType)
                } else {
                  knock(0) { }
                }
              }
            }
          Button("FaceID 사용 설정하러 가기") {
            UIApplication.shared
              .open(URL(string: "app-settings:root=Privacy")!)
          }
        }
      }
      .ignoresSafeArea()
  }
  func knock(_ count: Int, completion: @escaping () -> Void) {
    if count == 0 {
      DispatchQueue.main.async {
        withAnimation {
          self.knockCount = 0
        }
        completion()
      }
    } else {
      for i in 0...count {
        DispatchQueue.main
          .asyncAfter(wallDeadline: .now() + (0.5 * Double(i))) {
            if i < count {
              withAnimation {
                self.knockCount += 1
              }
              let hapticManager = HapticManager()
              hapticManager.impact(style: .light)
            } else {
              completion()
            }
        }
      }
    }
  }
  var btnFaceID: some View {
    imageScaledFit(systemName: "faceid", width: 80, height: 80)
      .padding(40)
      .overlay(alignment: .topTrailing) {
        Text("Touch")
          .font(.system(size: 10, weight: .regular))
          .padding(8)
          .background {
            Image(systemName: "bubble.left")
              .resizable()
              .fontWeight(.ultraLight)
              .offset(x: 0, y: 3)
          }
          .offset(x: 0, y: 0)
          .opacity(0.7)
      }
      .foregroundColor(.gray)
  }
  
  func knockingCenterBar() {
    if photoData.useKnock && knockCount == 0 {
      knock(3) {
        authenticate() { bool in
          if bool {
            self.returnHiddenAssets(albumType: mlAlbum.albumType)
          } else {
            self.knock(0) { }
          }
        }
      }
    }
  }
}

// MARK: - 2. extenstion. functions
extension AllPhotosView {
  func readySortByVolume(assetArray: [MLAsset], completion: @escaping () -> Void) {
    let toReady = assetArray.filter({ $0.volume == 0 })
    if toReady.isEmpty {
      completion()
    } else {
      DispatchQueue.global(qos: .userInteractive).async {
        for asset in toReady {
          if asset.volume == 0 {
            asset.getFileSize { _ in
              dispatchAnimation {
                self.readyCount += 1
                if readyCount == assetArray.count {
                  print("sort by Volume ready done")
                  completion()
                }
              }
            }
          } else {
            dispatchAnimation {
              self.readyCount += 1
              if readyCount == assetArray.count {
                print("sort by Volume ready done")
                completion()
              }
            }
          }
        }
      }
    }
  }
  func columnCount(geoProxy: GeometryProxy) -> Int {
    device == .phone
    ? cellCount(type: .small)
    : (geoProxy.size.width > geoProxy.size.height
       ? cellCount(type: .big)
       : cellCount(type: .middle1)
      )
  }
  
  func returnHiddenAssets(albumType: AlbumType) {
    mlAlbum.setHiddenAsset() { count in
      if count == 0 {
        dispatchAnimation {
          self.showEmptyHiddenAsset = true
          self.knockCount = 0
        }
      } else {
        dispatchAnimation {
          self.isReadyHiddenAsset = true
          self.knockCount = 0
        }
      }
    }
  }
  
  func thumbnailCaching(width: CGFloat) {
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .fastFormat
    requestOptions.resizeMode = .exact
    requestOptions.isSynchronous = true
    requestOptions.isNetworkAccessAllowed = true
    let size = CGSize(width: width * scale,
                      height: width * scale)
    print("캐싱 시작 : [\(mlAlbum.title) \(isHiddenAsset ? "HiddenAsset" : "not HiddenAsset")]")
    phImageQueue.async {
      let objects = (!isHiddenAsset ? mlAlbum.photosArray : mlAlbum.hiddenArray)
        .compactMap { $0.phAsset }
      imageManager
        .startCachingImages(
          for: objects,
          targetSize: size,
          contentMode: .aspectFill,
          options: requestOptions)
    }
  }
  
  func emptyInfoView() -> some View {
    VStack(spacing: 20) {
      Text(emptyText)
      if mlAlbum.albumType == .share
          && isHiddenAsset
          && !emptyText.isEmpty {
        Button {
          dispatchAnimation {
            NotificationCenter.default
              .post(name: .showInfoView,
                    object: Info.hiddenAssets)
          }
        } label: {
          Rectangle()
            .foregroundStyle(Color.fancyBackground)
            .frame(width: 70, height: 70)
            .overlay {
              imageScaledFit(
                systemName: "info.circle.fill",
                width: 40,
                height: 40)
              .foregroundStyle(.blue)
              .fontWeight(.thin)
            }
        }
      }
    }
    .foregroundStyle(.gray)
  }
  
  func viewWithTask(_ view: some View,
                    condition: Bool! = true,
                    task: @escaping () -> Void) -> some View {
    return view
      .task { if condition { task() } }
  }
  
  func emptyNoticeView(cellWidth: CGFloat) -> some View {
    ZStack {
      Capsule()
        .availabeGlassEffect(
          cornerR: (cellWidth - 10) / 2,
          foreground: .thinMaterial.opacity(0.85), { view in
            view
              .foregroundStyle(.ultraThinMaterial)
        })
      HStack {
        Text("이 앨범에는 가린 항목이 없습니다.")
        Button {
          dispatchAnimation {
            NotificationCenter.default
              .post(name: .showInfoView, object: Info.hiddenAssets)
          }
        } label: {
          ZStack {
            imageScaledFit(
              systemName: "info.circle.fill",
              width: 20,
              height: 20)
          }
          .frame(width: 20, height: 20)
        }
      }
      .transition(.scale)
    }
    .matchedGeometryEffect(id: "centerCardView", in: nameSpace)
    .frame(height: cellWidth - 10)
    .frame(maxWidth: widthLimit)
    .padding(.horizontal, 15)
  }
  var ratioChecker: some View {
    HStack(spacing: 0) {
      Rectangle()
        .foregroundStyle(.yellow)
      Rectangle()
        .foregroundStyle(.mint)
    }
    //                let testHeight = tabbarHeight * 2 + tabbarTopPadding
    //                VStack(spacing: 0) {
    //                    Rectangle()
    //                        .foregroundStyle(.red.opacity(0.4))
    //                        .frame(height: tabbarHeight)
    //                    Rectangle()
    //                        .foregroundStyle(.yellow.opacity(0.4))
    //                        .frame(height: tabbarTopPadding)
    //                    Rectangle()
    //                        .foregroundStyle(.green.opacity(0.4))
    //                        .frame(height: tabbarHeight)
    //                }
    //                .padding(tabbarBottomPadding)
  }
  
}

struct AllPhotosView_Previews: PreviewProvider {
  static var previews: some View {
    AllPhotosView(mlAlbum: MLAlbum(sampleID: 0,
                                   sampleCase: .none),
                  isHiddenAsset: false,
                  nameSpace: Namespace().wrappedValue,
                  isPhotosView: .constant(0),
                  viewCompletion: { _ in }
    )
    .environmentObject(MLPhotoData())
  }
}

extension View {
  func heroFullScreenCover<Content: View>(
    isShowDetailView: Binding<Bool>,
    content: @escaping () -> Content) -> some View {
      self
        .modifier(HelperHeroView(show: isShowDetailView, overlay: content()))
    }
  
  @ViewBuilder
  func sheroFullScreenCover<Content: View>(
    isShowDetailview: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content) -> some View {
      self
        .modifier(HelperHeroView(show: isShowDetailview, overlay: content()))
    }
}

fileprivate struct  HelperHeroView<Overlay: View>: ViewModifier {
  @Binding var show: Bool
  var overlay: Overlay
  
  @State private var hostView: UIHostingController<Overlay>?
  @State private var parentController: UIViewController?
  
  func body(content: Content) -> some View {
    content
      .background(content: {
        ExtractSwiftUIParentController(content: overlay,
                                       hostView: $hostView) { viewController in
          parentController = viewController
        }
      })
      .onAppear {
        hostView = UIHostingController(rootView: overlay)
      }
      .onChange(of: show) { newValue in
        if newValue {
          if let hostView {
            hostView.modalPresentationStyle = .overFullScreen
            hostView.modalTransitionStyle = .crossDissolve
            hostView.view.backgroundColor = .clear
            
            parentController?.present(hostView, animated: false)
          }
        } else {
          hostView?.dismiss(animated: false)
        }
      }
  }
}


fileprivate struct ExtractSwiftUIParentController<Content: View>: UIViewRepresentable {
  
  var content: Content
  @Binding var hostView: UIHostingController<Content>?
  var parentController: (UIViewController?) -> ()
  
  func makeUIView(context: Context) -> UIView {
    return UIView()
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    hostView?.rootView = content
    DispatchQueue.main.async {
      parentController(uiView.superview?.superview?.parentController)
    }
  }
}

public extension UIView {
  var parentController: UIViewController? {
    var responder = self.next
    while responder != nil {
      if let viewController = responder as? UIViewController {
        return viewController
      }
      responder = responder?.next
    }
    return nil
  }
}

enum ReLoadingType {
  case none
  case reFetchInside // item count + selectedItems 제거 + selectMode 체인지
  case reFetchOutside // item count 체인지
  case itemChangedInside // selectedItems 제거 + selectMode 체인지
  case itemChangedOutside // selectedItems 제거
  case selectedModeChange, selectAll, deselectAll
  case filterChange, belongingChange
}

struct Filtering: Comparable {
  static func < (lhs: Filtering, rhs: Filtering) -> Bool {
    lhs.zero == rhs.zero
    && lhs.first == rhs.first
    && lhs.second == rhs.second
  }
  var zero: FilterZero = .allAlbums
  var first: FilterFirst = .allMedia
  var second: FilterSecond = .all
  var sort: SortType = .byDate
}

enum SelectedItems {
  case selected, swiped, refreshed
}

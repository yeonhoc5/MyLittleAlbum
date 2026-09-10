//
//  CustomPhotosPicker.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/31.
//

import SwiftUI
import Photos
import VariableBlur

struct CustomPhotosPicker: View {
  @EnvironmentObject var photoData: MLPhotoData
  @Binding var isShowingPhotosPicker: Bool
  @Binding var animationEnded: Bool
  @State var photosMlAlbum: MLAlbum?
  let openedMLAlbumID: String?
  let albumType: AlbumType
  let nameSpace: Namespace.ID
  let imageManager = PHCachingImageManager()
  
  @State var selectMode: Bool = false
  @State var reLoadingType: ReLoadingType = .none
  @State var filtering = Filtering()
  @State var edgeToScroll: EdgeToScroll = .none
  @State var selectedItems: [MLAsset] = []
  @State var isSelectingBySwipe: Bool = false
  @State var isUnionMode: Bool = false
  @State var swipeSelectedItems: [MLAsset] = []
  @State var isShowingFilter: Bool = false
  @State var emptyText: String = ""
  @State var ready: Bool = false
  
  @State var isShowingDetailView: Bool = false
  @State var indexToview: Int = 0
  
  @State var isShowingMoveAssetSheet: Bool = false
  @State var moveAssetObject: MoveAssetObject! = nil
  
  let completion: ([MLAsset]) -> Void
  
  var body: some View {
    let assetArray = filteredAssetArray()
    return GeometryReader(content: { geoProxy in
      let columnCount = columnCount(geoProxy: geoProxy)
      let cellWidth = (geoProxy.size.width - CGFloat(columnCount - 1)) / CGFloat(columnCount)
      ZStack(alignment: .bottom) {
        photosContentView(cellWidth: cellWidth,
                          geoProxy: geoProxy,
                          assetArray: assetArray.filtered)
          .padding(.top, safeAreaTopPadding)
        VariableBlurView(maxBlurRadius: 3,
                         direction: .blurredBottomClearTop)
          .frame(height: tabbarHeight * 2 + 25)
        VStack {
          upperTitleView(geometry: geoProxy,
                         assetArray: assetArray.filtered)
          Spacer()
          if let homeAlbum = self.photosMlAlbum {
            gridMenuView(mlAlbum: homeAlbum,
                         width: geoProxy.size.width,
                         assetArray: assetArray)
            .padding(.bottom, tabbarTopPadding + tabbarHeight)
            .transition(.opacity)
          }
        }
      }
    })
    .fullScreenCover(isPresented: $isShowingDetailView,
                     content: {
      PhotosDetailView(
        albumType: albumType,
        localID: "home",
        isHiddenAssets: false,
        assetArray: assetArray.filtered,
        thumbnailManager: imageManager,
        animationID: nameSpace,
        isExpanded: $isShowingDetailView,
        indexToView: $indexToview) { _, _, _ in
          
        }
    })
    .modifier(
      InAppMoveAssetSheet(
        isShowingMoveAssetSheet: $isShowingMoveAssetSheet,
        moveAssetObject: $moveAssetObject,
        assetMoved: { bool in
          if bool {
            if let home = self.photosMlAlbum {
              home.processingChange(bool: true)
            }
            reloadingAssets(changed: bool)
          }
        })
    )
    .onReceive(NotificationCenter.default
      .publisher(for: .outsideFetchChange), perform: { object in
        if reLoadingType != .reFetchOutside {
          if object.object as? String == "picker" {
            print("Picker View outter fetch Recieved")
            dispatchAnimation {
              self.reLoadingType = .reFetchOutside
            }
          }
        }
      })
  }
}

extension CustomPhotosPicker {
  func reloadingAssets(changed: Bool) {
    if changed {
      dispatchAnimation {
        self.reLoadingType = .reFetchInside
        if let albumID = openedMLAlbumID,
           let album = photoData.albums[albumID] {
          NotificationCenter.default
            .post(name: .outsideFetchChange,
                  object: albumID)
        }
      }
    }
  }
  func photosContentView(cellWidth: CGFloat,
                         geoProxy: GeometryProxy,
                         assetArray: [MLAsset]) -> some View {
    Group {
      let temp = loadingTempView(geoProxy: geoProxy,
                                 cellWidth: cellWidth,
                                 asyncTime: 0.5) { }
      if animationEnded {
        if let allPhotos = self.photosMlAlbum {
          photosView(mlAlbum: allPhotos,
                     geoProxy: geoProxy,
                     cellWidth: cellWidth,
                     assetArray: assetArray)
        } else {
          temp
        }
      } else {
        temp
      }
    }
    .transition(.blurReplace)
  }
  func upperTitleView(geometry: GeometryProxy,
                      assetArray: [MLAsset]) -> some View {
    let width: CGFloat = 150
    let height: CGFloat = 40
    let pickerPadding: CGFloat = 10
    return HStack(alignment: .center) {
      Text("나의 사진\(filtering.zero == .allMedia ? "의" : "에서")")
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
               height: height - pickerPadding)
        // picker selected box의 각 패딩 10
        Picker("",
               selection: .constant(filtering.zero),
               content: {
          Group {
            Text(FilterZero.string(type: .allMedia))
              .tag(FilterZero.allMedia)
            Text(FilterZero.string(type: .allAlbums))
              .tag(FilterZero.allAlbums)
            Text(FilterZero.string(type: .currentAlbum))
              .tag(FilterZero.currentAlbum)
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
    .frame(height: navigationbarHeight)
    .padding(.top, statusBarHeight)
//    let height: CGFloat = 70
//    let padding: CGFloat = 20
//    let spacing: CGFloat = 20
//    let width = geometry.size.width - (padding * 2) - spacing
//    return HStack(alignment: .bottom, spacing: spacing) {
//      titleView(width: width * 0.65, height: height)
//      subTitleView(assetArray: assetArray,
//                   width: width * 0.35)
//    }
//    .frame(height: height)
//    .clipped()
//    .padding(.horizontal, padding)
//    .padding(.top, 15)
  }
  
  func loadingTempView(geoProxy: GeometryProxy,
                       cellWidth: CGFloat,
                       asyncTime: CGFloat,
                       onEnded: @escaping () -> Void) -> some View {
//    imageWithScale(systemName: iconPhotosSelected, scale: .large)
//      .scaleEffect(3)
    VStack {
      let view = HStack(spacing: 1) {
        Rectangle()
        Rectangle()
        Rectangle()
        Rectangle()
        Rectangle()
      }
      VStack(spacing: 1, content: {
        view
        view
        view
        view
        view
        view
      })
      .foregroundStyle(Color.fancyBackground.opacity(0.3))
      .frame(height: geoProxy.size.width / 5 * 6)
      Spacer()
    }
//      .frame(width: 100, height: 100)
//      .padding(.bottom, 90)
//      .frame(width: abs(geoProxy.size.width),
//             height: abs(geoProxy.size.height - 90))
      .onAppear {
        if photoData.homeAlbum != nil {
          dispatchAnimation {
            self.photosMlAlbum = photoData.homeAlbum
          }
        } else {
          let homeAlbum = MLAlbum(isHome: true)
          photoData.homeAlbum = homeAlbum
          dispatchAnimation {
            self.photosMlAlbum = photoData.homeAlbum
          }
          
        }
        thumbnailCaching(width: cellWidth)
      }
  }
  func thumbnailCaching(width: CGFloat) {
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .fastFormat
    requestOptions.resizeMode = .exact
    requestOptions.isSynchronous = true
    requestOptions.isNetworkAccessAllowed = true
    let size = CGSize(width: width, height: width)
    
    let imageManager = photoData.cachingManager
    phImageQueue.async {
      let objects = filteredAssetArray().all
          .compactMap { $0.phAsset }
      imageManager
        .startCachingImages(
          for: objects,
          targetSize: size,
          contentMode: .aspectFill,
          options: requestOptions)
    }
  }
  func filteredAssetArray() -> (all: [MLAsset],
                                filtered: [MLAsset]) {
    guard let homeAlbum = self.photosMlAlbum
    else { return ([], []) }
    let subtracting: Set<MLAsset> = if filtering.zero == .allAlbums {
      photoData.albumsPhotosSet()
    } else if filtering.zero == .currentAlbum {
      if let album = photoData.albums["home"] {
        Set(album.photosArray)
      } else {
        []
      }
    } else {
      []
    }
    let homeAssets = homeAlbum.photosArray
      .setSubtraing(by: subtracting)
    
    return (homeAssets, homeAssets
      .filter({ asset in
        let first = filtering.first
        if first == .allMedia {
          return true
        } else {
          return asset.mediaType == FilterFirst
            .trueType(type: first)
        }
      })
      .filter({ asset in
        let second = filtering.second
        if second == .favorite {
          return asset.isFavorite
        } else if second == .screenshot {
          return (asset.phAsset
                    .mediaSubtypes
                    .contains(.photoScreenshot)
                  || asset.phAsset
                    .mediaSubtypes
                    .contains(.videoScreenRecording))
        } else {
          return true
        }
      })
      .sorted(by: { assetA, assetB in
        return assetA.creationDate < assetB.creationDate
      })
    )
  }
}

extension CustomPhotosPicker {
  func photosView(mlAlbum: MLAlbum,
                  geoProxy: GeometryProxy,
                  cellWidth: CGFloat,
                  assetArray: [MLAsset]) -> some View {
    let isHome = openedMLAlbumID == nil
    return NewPhotosCollectionView(
      mlAlbum: mlAlbum,
      albumType: albumType,
      isHiddenAssets: false,
      assetArray: assetArray,
      imageManager: imageManager,
      sampleImages: .constant([:]),
      geoProxy: geoProxy,
      cellWidth: cellWidth,
      edgeToScroll: $edgeToScroll,
      isReadyVolumeSort: .constant(false),
      isSelectMode: isHome ? $selectMode : .constant(true),
      selectedItems: $selectedItems,
      isSelectingBySwipe: $isSelectingBySwipe,
      isUnionMode: $isUnionMode,
      swipeSelectedItems: $swipeSelectedItems,
      isShowingFilter: $isShowingFilter,
      filtering: $filtering,
      reLoadingType: $reLoadingType,
      isExpanded: $isShowingDetailView,
      indexToView: $indexToview,
      isShowingPhotosPicker: .constant(false),
      refreshItems: .constant([]))
    .overlay(content: {
      Text(emptyText).foregroundStyle(.gray)
    })
    .matchedGeometryEffect(id: "homeAlbume", in: nameSpace)
    .animation(.easeOut, value: mlAlbum.fetchResult.count == 0)
    .transition(.opacity)
  }
  
  func gridMenuView(mlAlbum: MLAlbum,
                    width: CGFloat,
                    assetArray: ([MLAsset], [MLAsset])) -> some View {
    let albumType: AlbumType = openedMLAlbumID == nil ? .home : .picker
    return PhotosGridMenu(
      mlAlbum: mlAlbum,
      isShowingPhotosPicker: $isShowingPhotosPicker,
      albumType: albumType,
      isHiddenAssets: false,
      assetArray: assetArray,
      edgeToScroll: $edgeToScroll,
      isShowingFilter: $isShowingFilter,
      isReadyVolumeSort: .constant(false),
      isReadyHiddenAsset: .constant(false),
      showHiddenAssets: .constant(false),
      isSelectMode: albumType == .home
                    ? $selectMode : .constant(true),
      selectedItems: $selectedItems,
      isSelectingBySwipe: $isSelectingBySwipe,
      isUnionMode: $isUnionMode,
      swipeSelectedItems: $swipeSelectedItems,
      filtering: $filtering,
      reLoadingType: $reLoadingType,
      assetAlert: .constant(nil),
      moveAssetObject: $moveAssetObject ,
      isShowingMoveAssetSheet: $isShowingMoveAssetSheet,
      showEmptyNoticeView: .constant(false),
      isPhotosView: .constant(0),
      nameSpace: nameSpace,
      allPhotosNamespace: nameSpace,
      width: width,
      readyCount: 0,
      knockCount: 0) { }
    sortByVolume: { }
    completion: { addedAssets in
      completion(addedAssets)
    }
  }
  func titleView(width: CGFloat, height: CGFloat) -> some View {
    let pickerPadding: CGFloat = 10
    return VStack(alignment: .leading, spacing: 5) {
      Text("나의 사진\(filtering.zero == .allMedia ? "의" : "에서")")
        .foregroundStyle(.gray)
        .font(.footnote)
        .contentTransition(.numericText())
        .frame(height: 10)
        .padding(.horizontal, 10)
      ZStack {
        versionShape
          .frame(width: abs(width - (2 * pickerPadding)),
                 height: height - 40)
        Picker("",
               selection: .constant(filtering.zero),
               content: {
          ForEach(FilterZero.allCases) { filter in
            Text(FilterZero.string(type: filter))
              .tag(filter)
          }
          .font(.caption)
          .bold()
          .foregroundStyle(Color.fancyBackground)
        })
        .pickerStyle(.wheel)
        .disabled(true)
        .frame(width: abs(width), height: abs(height - 35))
        .padding(.horizontal, -pickerPadding)
        .clipShape(RoundedRectangle(cornerRadius: 7))
      }
    }
  }
  
  var versionShape: some View {
    Group {
      if #available(iOS 26.0, *) {
        Capsule()
          .foregroundColor(.white.opacity(0.7))
          .glassEffect(in: Capsule())
      } else {
        RoundedRectangle(cornerRadius: 10)
          .foregroundColor(.white.opacity(0.7))
      }
    }
  }
  
  func subTitleView(assetArray: [MLAsset], width: CGFloat) -> some View {
    let first = filtering.first
    let onlyImage = first == .image
    let onlyvideo = first == .video
    let imageCount = assetArray.filter { $0.mediaType == .image }.count
    let videoCount = assetArray.filter { $0.mediaType == .video }.count
    return HStack {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 12) {
          Text("사")
          Text("진 :")
        }
        .foregroundColor(onlyImage ? .blue : .gray)
        Text("비디오 :")
          .foregroundColor(onlyvideo ? .blue : .gray)
      }
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Text(photosMlAlbum != nil ? "\(imageCount)" : "--")
            .foregroundColor(onlyImage ? .blue : .gray)
          Text(photosMlAlbum != nil ? "\(videoCount)" : "--")
            .foregroundColor(onlyvideo ? .blue : .gray)
        }
        Spacer(minLength: 0)
      }
    }
    .font(Font.system(size: 14))
    .frame(alignment: .leading)
    .contentTransition(.numericText())
    .frame(width: width)
    .foregroundColor(.gray)
  }
  
  func columnCount(geoProxy: GeometryProxy) -> Int {
    device == .phone ? cellCount(type: .small) : cellCount(type: .middel2)
  }
}

//struct CustomPhotosPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        CustomPhotosPicker(isShowingPhotosPicker: .constant(true),
//                           stateChangeObject: StateChangeObject(),
//                           album: nil,
//                           size: .zero,
//                           imageCachingManager: PHCachingImageManager(),
//                           title: "Not in any Album",
////                           albumToEdit: Album(assetArray: [], title: "sample"))
//                           albumToEdit: MLAlbum(filterSet: Set<PHAsset>()))
//        .environmentObject(MLPhotoData())
//    }
//}

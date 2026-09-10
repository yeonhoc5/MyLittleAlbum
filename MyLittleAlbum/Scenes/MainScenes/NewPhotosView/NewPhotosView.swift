//
//  NewPhotosView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/25/25.
//

import SwiftUI
import Photos

struct NewAllPhotosView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @State var isShowingPhotosPicker: Bool = false
  var albumType: AlbumType = .album
  @State var album: MLAlbum!
  @State var edgeToScroll: EdgeToScroll = .none
  @Namespace var photosViewNameSpace
  
  var body: some View {
    ZStack(alignment: .bottom) {
      if album != nil {
        NewPhotosView(
          albumType: albumType,
          album: album,
          edgeToScroll: $edgeToScroll)
      } else {
        RefreshPhotoView(task: {
          if albumType == .home {
            DispatchQueue.main.async {
              let _ = Set(photoData.albums
                .values
                .flatMap {
                  $0.fetchResult
                    .objects(at: IndexSet(
                      integersIn: 0..<$0.fetchResult.count)
                    )
                })
              withAnimation {
                self.album = MLAlbum(isHome: true)
              }
            }
          }
        })
      }
      GeometryReader { geometry in
        let spacerWidth = device == .phone ? 0
        : ((geometry.size.width / 4) + (5 * tabbarTopPadding))
        if let _ = album {
          PhotosGridMenu(
            mlAlbum: MLAlbum(isHome: true),
            isShowingPhotosPicker: .constant(false),
            albumType: .album,
            isHiddenAssets: false,
            assetArray: ([], []),
            edgeToScroll: .constant(.none),
            isShowingFilter: .constant(false),
            isReadyVolumeSort: .constant(false),
            isReadyHiddenAsset: .constant(false),
            showHiddenAssets: .constant(false),
            isSelectMode: .constant(false),
            selectedItems: .constant([]),
            isSelectingBySwipe: .constant(false),
            isUnionMode: .constant(false),
            swipeSelectedItems: .constant([]),
            filtering: .constant(Filtering()),
            reLoadingType: .constant(.none),
            assetAlert: .constant(nil),
            moveAssetObject: .constant(nil),
            isShowingMoveAssetSheet: .constant(false),
            showEmptyNoticeView: .constant(false),
            isPhotosView: .constant(0),
            nameSpace: photosViewNameSpace,
            allPhotosNamespace: photosViewNameSpace,
            width: geometry.size.width - spacerWidth,
            readyCount: 0,
            knockCount: 0) {
            } sortByVolume: {
            } completion: { _ in }
        }
      }
      .padding(.horizontal, device == .phone ? tabbarTopPadding : 0)
      .padding(.trailing, device == .phone ? 0 : tabbarBottomPadding)
      .frame(height: tabbarHeight)
      .padding(.bottom, device == .phone ?
               tabbarHeight
               + tabbarTopPadding
               + tabbarBottomPadding : tabbarBottomPadding)
    }
  }
}

struct NewPhotosView: View {
  var albumType: AlbumType = .album
  @EnvironmentObject var photoData: MLPhotoData
  let imageCachingManager = PHCachingImageManager()
  @ObservedObject var album: MLAlbum
  @Binding var edgeToScroll: EdgeToScroll
  
  var body: some View {
    GeometryReader { geometry in
      let assets = album.frObject(isHidden: false)
      let width = (geometry.size.width - 4) / 5
      let columns = Array(repeating: GridItem(), count: 5)
      ScrollViewReader { scrollProxy in
        ScrollView {
          VStack {
            LazyVGrid(columns: columns, spacing: 1) {
              ForEach(assets) { asset in
                ZStack {
                  PhotoThumbnailView(
                    asset: asset,
                    cachingManager: imageCachingManager,
                    size: CGSize(width: width, height: width)
                  )
                  .id(asset.id)
                }
                .frame(width: abs(width),
                       height: abs(width))
              }
            }
            .id("scrollView")
            Rectangle()
              .fill(.orange)
              .frame(height: tabbarHeight + 30)
              .id("spacer")
          }
        }
        .onChange(of: edgeToScroll) { newValue in
          DispatchQueue.main.async {
            if newValue == .bottom {
              withAnimation {
                scrollProxy
                  .scrollTo("spacer", anchor: .bottom)
              }
            } else if newValue == .top {
              withAnimation {
                scrollProxy
                  .scrollTo("scrollView", anchor: .top)
              }
            }
          }
          edgeToScroll = .none
        }
      }
      .onAppear(perform: {
        print("caching start")
        phImageQueue.async {
          imageCachingManager
            .startCachingImages(for: assets.compactMap { $0.phAsset },
                                targetSize: CGSize(width: width,
                                                   height: width),
                                contentMode: .aspectFill,
                                options: nil)
        }
      })
      .onDisappear {
        print("delete caching")
        DispatchQueue.global(qos: .background).async {
          imageCachingManager
            .stopCachingImagesForAllAssets()
        }
      }
    }
    .ignoresSafeArea(.all)
  }
  
}

//#Preview {
//    NewPhotosView(count: 100)
//}

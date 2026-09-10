//
//  AlbumListView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/11/23.
//

import SwiftUI
import Photos

struct AlbumListView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @ObservedObject var pageFolder: MLFolder
  @Binding var isPhotosView: Int
  // 레이아웃
  let pageIndex: Int
  let screenWidth: CGFloat
  var isEditingMode: Bool
  // namespace
  var nameSpace: Namespace.ID
  var albumViewNameSpace: Namespace.ID
  // (i패드용) 탭바 위치 잡기용 프라퍼티
  @State var firstAppear: Bool = true
  // 보여주기 ui 스위칭 프라퍼티
  let isUnfolded: Bool
  @State var processingCollection: SubCollection!
  
  var body: some View {
    let widthOfAlbum = (screenWidth - (10 * CGFloat(listCount + 2))) / CGFloat(listCount)
    let albumListView = albumListView(widthOfAlbum: widthOfAlbum)
    return albumListLayout(pageFolder: pageFolder,
                           view: albumListView,
                           mode: isUnfolded,
                           widthOfAlbum: widthOfAlbum)
    .onChange(of: photoData.uiMode) { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        NotificationCenter.default
          .post(name: .showProgressEndView, object: nil)
      }
    }
  }
}


extension AlbumListView {
  
  func albumListView(widthOfAlbum: CGFloat) -> some View {
    ForEach(pageFolder.albumsArray, id: \.self) { subAlbum in
      let index = pageFolder.albumsArray.firstIndex(of: subAlbum) ?? 0
      viewForEach(subCollection: subAlbum,
                  widthOfAlbum: widthOfAlbum,
                  index: pageIndex + index)
      .id(subAlbum.id)
      .buttonStyle(ClickScaleEffect())
      .transition(.scale)
      .contextMenu {
        EditCollectionMenuView(
          pageFolder: pageFolder,
          processing: $processingCollection,
          isEditMode: .constant(false),
          subCollection: subAlbum,
          isSecondary: false,
          index: index,
          nameSpace: nameSpace) { subColl in
            deleteAlbumInDepth(subCollection: subColl)
          }
      }
    }
    .animation(.easeInOut, value: !pageFolder.albumsArray.isEmpty)
  }
  // 앨범 리스트 레이아웃 by modeOfAlbumList
  @ViewBuilder
  func albumListLayout(pageFolder: MLFolder,
                       view: some View,
                       mode: Bool,
                       widthOfAlbum: CGFloat) -> some View {
    let spacing = (self.screenWidth - 5.0 - (CGFloat(listCount) * widthOfAlbum)) / CGFloat(listCount)
    let column = Array(
      repeating: GridItem(.fixed(widthOfAlbum), spacing: !mode ? 10 : spacing),
      count: mode ? listCount : pageFolder.albumsArray.count
    )
    scrollViewWidthReader(.horizontal, scrollDisalble: mode) { proxy in
      LazyVGrid(columns: column) {
        view
      }
      .padding(.all, 10)
      .overlay(alignment: mode ? .bottom : .trailing, content: {
        Rectangle()
          .foregroundStyle(.clear)
          .id("newAlbumSpaceForScroll")
          .modify({ view in
            if mode {
              view.frame(height: 10)
            } else {
              view.frame(width: 10)
            }
          })
      })
      .onChange(of: pageFolder.albumsArray.count) { [oldValue = pageFolder.albumsArray.count] newValue in
        if !mode && newValue > oldValue && oldValue != 0 {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
              proxy
                .scrollTo("newAlbumSpaceForScroll",anchor: .trailing)
            }
          }
        }
      }
    }
  }
  
  @ViewBuilder
  func viewForEach(subCollection: SubCollection,
                   widthOfAlbum: CGFloat,
                   index: Int) -> some View {
    let albumID = subCollection.id
    NavigationLink {
      if let album = photoData.mlAlbum(type: pageFolder.folderType,
                                       albumID) {
        AllPhotosView(mlAlbum: album,
                      isHiddenAsset: false,
                      nameSpace: nameSpace,
                      isPhotosView: $isPhotosView) { _ in
        }
      }
    } label: {
      CellView(uiMode: photoData.uiMode,
               cellType: .album,
               index: index,
               width: widthOfAlbum) { uiMode, size, cellNameSpace in
        Group {
          if let album = photoData
            .mlAlbum(type: pageFolder.folderType, albumID) {
            AlbumCoverView(album: album,
                           uiMode: photoData.uiMode,
                           cellType: .album,
                           size: size,
                           colorIndex: index,
                           albumCell: cellNameSpace,
                           isEditingMode: isEditingMode)
            
          } else {
            VStack(alignment: .center, spacing: 0) {
              Text(subCollection.title)
                  .font(.footnote)
                  .lineLimit(2)
                  .matchedGeometryEffect(id: "title",
                                         in: cellNameSpace, isSource: false)
                  .frame(width: size.width - 14)
                  .padding(normalPadding)
                Rectangle()
                  .foregroundStyle(.clear)
                  .overlay(alignment: .center) {
                      ProgressView()
                          .progressViewStyle(.circular)
                          .controlSize(.regular)
                  }
            }
            .frame(width: size.width - 14, height: size.height)
          }
        }
      }
    }
    .id(albumID)
    .disabled(isEditingMode)
    .overlay(alignment: .topLeading) {
      btnDelete(album: subCollection)
        .offset(x: -1, y: -1)
    }
  }

  func btnDelete(album: SubCollection) -> some View {
    Button {
      dispatchAnimation {
        processingCollection = album
      }
      if let _ = photoData.albums[album.id] {
        deleteAlbumInDepth(subCollection: album)
      }
    } label: {
      RemoveButtonLabel(shapeType: .rectangle,
                        isProcessing: processingCollection == album)
    }
    .opacity(isEditingMode ? 1:0)
    .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
    .buttonStyle(ClickScaleEffect())
  }
  //    func tempCoverView(text: String, size: CGSize, nameSpace: Namespace.ID) -> some View {
  //        VStack(spacing: 10) {
  //            Text(text)
  //                .matchedGeometryEffect(id: "title", in: nameSpace)
  //            ProgressView()
  //                .progressViewStyle(.circular)
  //        }
  //        .frame(width: size.width, height: size.height)
  //    }
  
  func deleteAlbumInDepth(subCollection: SubCollection) {
    if let album = photoData.albums[subCollection.id] {
      pageFolder.deleteAlbum(album: album.phAssetCollection) { bool in
        if bool {
          dispatchAnimation {
            photoData.removeAlbumValue(album: album.phAssetCollection) {
              NotificationCenter.default
                .post(name: .outsideFetchChange, object: "myPhotos")
            }
          }
        }
        dispatchAnimation {
          processingCollection = nil
        }
      }
    }
  }
  
}

// contexMenu funcs
extension AlbumListView {
//  func albumViewModeChange(isFirstAppear: Bool, pageFolder: MLFolder?) {
//    guard let pageFolder = pageFolder else { return }
//    if firstAppear {
//      dispatchAnimation {
//        isUnfolded = pageFolder.foldersArray.isEmpty
//        && pageFolder.albumsArray.count > listCount
//      }
//    }
//    firstAppear = false
//  }
}


struct AlbumListView_Previews: PreviewProvider {
  static var previews: some View {
    AlbumView(pageFolder: MLFolder(collectionList: nil),
              isPhotosView: .constant(0),
              pageIndex: 0,
//              isShowingSettingView: .constant(false),
              isShowingMessageView: .constant(false),
              tutorialOn: .constant(false),
              nameSpace: Namespace().wrappedValue)
    .environmentObject(MLPhotoData())
  }
}

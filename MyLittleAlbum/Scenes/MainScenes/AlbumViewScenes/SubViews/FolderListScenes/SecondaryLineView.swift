//
//  SecondaryLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import SwiftUI
import Photos
import LottieUI

struct SecondaryLineView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @ObservedObject var pageFolder: MLFolder
  let subFolder: SubCollection
  let isHome: Bool
  let index: Int
  let screenWidth: CGFloat
  let secondaryWidth: CGFloat
  let lineHeight: CGFloat
  let isFolded: Bool
  
  @Binding var isPhotosView: Int
  let nameSpace: Namespace.ID
  let albumViewNameSpace: Namespace.ID
  
  let isEditingMode: Bool
  @State var processingCollection: SubCollection!
  
  @Environment(\.scenePhase) var scenePhase
  @State var isSetted: Bool = false
  
  var body: some View {
    return HStack(spacing: 0) {
      if photoData.uiMode != .classic {
        leadingPaddingView
      }
      scrollViewWidthReader(.horizontal,
                            scrollDisalble: !isFolded) { proxy in
        if isSetted {
          settedSecondaryViewList(width: secondaryWidth,
                                  proxy: proxy,
                                  onAppear: {
            if isHome && photoData.loadingState == .doneSecondaryLines {
              loadNextStep()
            }
          })
        } else {
          let padding: CGFloat = (secondaryWidth * 0.6) - 10
          lottieLoadingView(lottie: "secondaryLoadingJson",
                            size: CGSize(
                                  width: screenWidth - padding,
                                  height: lineHeight),
                            leadingPadding: padding)
          .onAppear {
            if photoData.mlFolder(type: pageFolder.folderType,
                                  subFolder.id) != nil {
              dispatchAnimation {
                isSetted = true
              }
            }
          }
        }
      }
      .onChange(of: photoData.loadingState) { newValue in
        if isHome && (newValue == .doneSecondaryLines
                      || newValue == .loadingComplete) {
          dispatchAnimation {
            isSetted = true
          }
        }
      }
    }
  }
}

// load photodata
extension SecondaryLineView {
  func settedSecondaryViewList(width: CGFloat,
                               proxy: ScrollViewProxy,
                               onAppear: @escaping () -> Void) -> some View {
    let secondaryItems = fetchSecondaryDepth(width: width, proxy: proxy)
    return Group {
      if photoData.uiMode != .classic {
        HStack(alignment: .bottom, spacing: 7)  {
          secondaryItems
        }
        .padding(.leading, 10 + (secondaryWidth * 0.3))
        .padding(.trailing, 10)
        .transition(.slide)
      } else {
        let spacing = (screenWidth - 20 - secondaryWidth * ( CGFloat(listCount + 1))) / CGFloat(listCount)
        let column = Array(
          repeating: GridItem(.fixed(secondaryWidth),
                              spacing: isFolded ? 7 : spacing),
          count: isFolded
          ? (pageFolder.foldersArray.count + pageFolder.albumsArray.count)
          : listCount + 1
        )
        LazyVGrid(columns: column)  {
          secondaryItems
        }
        .padding(.horizontal, 10)
        .transition(.move(edge: .top))
      }
    }
    .onAppear { onAppear() }
  }
  func fetchSecondaryDepth(width: CGFloat, proxy: ScrollViewProxy) -> some View {
    Group {
      ForEach(pageFolder.foldersArray, id: \.self) { subFolder in
        let secondaryIndex = pageFolder.foldersArray.firstIndex(of: subFolder) ?? 0
        folderListView(subFolder: subFolder,
                       index: index + ((secondaryIndex + 1) * 4),
                       width: width)
        .id(subFolder.id)
        .matchedGeometryEffect(id: subFolder.id,
                               in: albumViewNameSpace)
        .buttonStyle(ClickScaleEffect())
        .transition(.scale)
        .contextMenu{
          EditCollectionMenuView(
            pageFolder: pageFolder,
            processing: $processingCollection,
            isEditMode: .constant(false),
            subCollection: subFolder,
            isSecondary: true,
            index: index,
            nameSpace: nameSpace) { subCollection in
              deleteFolderInSecDepth(subFolder: subCollection)
            }
        }
      }
      ForEach(pageFolder.albumsArray, id: \.self) { subAlbum in
        let secondaryIndex = pageFolder.albumsArray.firstIndex(of: subAlbum) ?? 0
        albumListView(subAlbum: subAlbum,
                      index: index + secondaryIndex,
                      width: width)
        .id(subAlbum.id)
        .matchedGeometryEffect(id: subAlbum.id,
                               in: albumViewNameSpace)
        .buttonStyle(ClickScaleEffect())
        .transition(.scale)
        .contextMenu {
          EditCollectionMenuView(
            pageFolder: pageFolder,
            processing: $processingCollection,
            isEditMode: .constant(false),
            subCollection: subAlbum,
            isSecondary: true,
            index: index,
            nameSpace: nameSpace) { subCollection in
              deleteAlbumInSecDepth(subAlbum: subCollection)
            }
        }
      }
    }
    .padding(.vertical, 6)
    .onChange(of: pageFolder.foldersArray.count,
              perform: { [oldValue = pageFolder.foldersArray.count] newValue in
      if newValue > oldValue {
        scrollToNewitems(item: .folder, scrollProxy: proxy)
      }
    })
    .onChange(of: pageFolder.albumsArray.count,
              perform: { [oldValue = pageFolder.albumsArray.count] newValue in
      if newValue > oldValue {
        scrollToNewitems(item: .album, scrollProxy: proxy)
      }
    })
  }
  // MARK: - FolderCoverView
  func folderListView(subFolder: SubCollection,
                      index: Int,
                      width: CGFloat!) -> some View {
    NavigationLink {
      if let nextFolder = photoData.mlFolder(type: pageFolder.folderType, subFolder.id) {
        AlbumView(pageFolder: nextFolder,
                  isPhotosView: $isPhotosView,
                  pageIndex: index,
//                  isShowingSettingView: .constant(false),
                  isShowingMessageView: .constant(false),
                  tutorialOn: .constant(false),
                  nameSpace: albumViewNameSpace)
      }
    } label: {
      CellView(uiMode: photoData.uiMode,
               cellType: .folder,
               index: 0,
               width: width) { uiMode,  size, cellNameSpace in
        Group {
          if #available(iOS 26.0, *) {
            let innerHeight = size.height * (uiMode == .classic ? 0.8 : 0.75)
            ZStack(alignment: uiMode == .classic ? .topLeading : .bottomTrailing) {
              folderTitleView(subFolder: subFolder,
                              uiMode: uiMode)
              .matchedGeometryEffect(id: "title", in: cellNameSpace)
              .frame(width: width, height: innerHeight,
                     alignment: uiMode != .classic
                     ? .topLeading : .bottom)
              folderCountView(uiMode: uiMode,
                              subFolder: subFolder,
                              size: CGSize(width: size.width,
                                           height: innerHeight),
                              cellNameSpace: cellNameSpace)
            }
            .contentTransition(.numericText())
            .matchedGeometryEffect(id: subFolder.id,
                                   in: cellNameSpace)
          } else {
            Group {
              if let nextFolder = photoData.mlFolder(type: pageFolder.folderType, subFolder.id) {
                FolderCoverView(folder: nextFolder,
                                subFolder: subFolder,
                                uiMode: photoData.uiMode,
                                size: size,
                                cellNameSpace: cellNameSpace)
              } else {
                TempCoverView(title: subFolder.title,
                              nameSpace: cellNameSpace,
                              size: size,
                              cellType: .folder)
              }
            }
            .matchedGeometryEffect(id: subFolder.id,
                                   in: cellNameSpace)
            
          }
        }
      }
    }
    .buttonStyle(ClickScaleEffect())
    .disabled(isEditingMode)
    .overlay(alignment: .topLeading) {
      btnDelete(subCollection: subFolder)
        .offset(x: -1, y: -1)
    }
  }
  // MARK: - AlbumCoverView
  func albumListView(subAlbum: SubCollection,
                     index: Int = 0, width: CGFloat!) -> some View {
    return NavigationLink {
      let albumID = subAlbum.id
      if let album = photoData
        .mlAlbum(type: pageFolder.folderType, albumID) {
        AllPhotosView(mlAlbum: album,
                      isHiddenAsset: false,
                      nameSpace: albumViewNameSpace,
                      isPhotosView: $isPhotosView) { _ in }
      }
    } label: {
      VStack(spacing: 0) {
        Spacer(minLength: 0)
        CellView(uiMode: photoData.uiMode,
                 cellType: .miniAlbum,
                 index: index,
                 width: width) { uiMode, size, cellNameSpace in
          Group {
            if let album = photoData
              .mlAlbum(type: pageFolder.folderType, subAlbum.id) {
              AlbumCoverView(album: album,
                             uiMode: photoData.uiMode,
                             cellType: .miniAlbum,
                             size: size,
                             colorIndex: index,
                             albumCell: cellNameSpace,
                             isEditingMode: isEditingMode)
              .matchedGeometryEffect(id: subAlbum.id,
                                     in: cellNameSpace)
            } else {
              TempCoverView(title: subAlbum.title,
                            nameSpace: cellNameSpace,
                            size: size,
                            cellType: .miniAlbum)
            }
          }
        }
      }
    }
    .buttonStyle(ClickScaleEffect())
    .disabled(isEditingMode)
    .overlay(alignment: .topLeading) {
      btnDelete(subCollection: subAlbum)
        .offset(x: -1, y: photoData.uiMode != .fancy ? -1 : 10)
    }
  }
}

extension SecondaryLineView {
  func folderTitleView(subFolder: SubCollection, uiMode: UIMode) -> some View {
    Group {
      if let nextFolder = photoData.mlFolder(type: pageFolder.folderType, subFolder.id) {
        titleText(nextFolder.title,
                  font: .footnote,
                  color: uiMode == .classic ? .orange : .fancyBackground)
        .lineLimit(uiMode == .classic ? 1 : .max)
      } else {
        titleText(subFolder.title,
                  font: .footnote,
                  color: photoData.uiMode == .classic
                  ? .orange : .fancyBackground)
      }
    }
    .lineLimit(.max)
    .multilineTextAlignment(.leading)
    .padding([.horizontal, .top], 7)
  }
  func folderCountView(uiMode: UIMode,
                       subFolder: SubCollection,
                       size: CGSize,
                       cellNameSpace: Namespace.ID) -> some View {
    Group {
      if let nextFolder = photoData.mlFolder(type: pageFolder.folderType, subFolder.id) {
        let count = "\(nextFolder.foldersArray.count) / \(nextFolder.albumsArray.count)"
        titleText(count, font: .caption, color: .fancyBackground.opacity(0.5))
          .lineLimit(1)
          .matchedGeometryEffect(id: "count", in: cellNameSpace)
          .background {
            Rectangle()
              .foregroundStyle(uiMode == .classic
                               ? Color.orange : Color.folder)
          }
          .padding(7)
      } else {
        VStack(spacing: 0) {
          ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.mini)
            .foregroundStyle(.white)
            .matchedGeometryEffect(id: "count", in: cellNameSpace)
          if uiMode == .classic {
            Text(" ")
          }
        }
        .frame(width: size.width, height: size.height, alignment: .center)
      }
    }
  }
}

// edit funcs (1/2) 폴더
extension SecondaryLineView {
  var leadingPaddingView: some View {
    Color.fancyBackground
      .frame(width: 10 + secondaryWidth * 0.3)
      .zIndex(1)
  }

  func btnDelete(subCollection: SubCollection) -> some View {
    Button {
      if let _ = photoData.folders[subCollection.id] {
        processingCollection = subCollection
        deleteFolderInSecDepth(subFolder: subCollection)
      } else {
        if let _ = photoData.albums[subCollection.id] {
          deleteAlbumInSecDepth(subAlbum: subCollection)
        }
      }
    } label: {
      RemoveButtonLabel(shapeType: .circle,
                        isProcessing: processingCollection == subCollection)
    }
    .opacity(isEditingMode ? 1:0)
    .scaleEffect(isEditingMode ? 1:0.1, anchor: .center)
    .buttonStyle(ClickScaleEffect())
  }
}
// edit funcs (2/2) 앨범
extension SecondaryLineView {
  // 앨범 삭제
  func deleteFolderInSecDepth(subFolder: SubCollection) {
    guard let folder = photoData.mlFolder(type: pageFolder.folderType, subFolder.id)
    else { return }
    if folder.folderType == .userFolder {
      pageFolder.deleteFolder(
        folder: folder.phCollectionList) { bool in
        if bool {
          dispatchAnimation {
            photoData
              .removeFolderValue(folder: folder.phCollectionList) {
              NotificationCenter.default
                .post(name: .outsideFetchChange, object: "myPhotos")
            }
          }
        }
        dispatchAnimation {
          processingCollection = nil
        }
      }
    } else {
      let object = AlertObject(
        alertCase: .delShareCategory,
        folderType: .shareCategory,
        albumID: nil,
        folderID: folder.id,
        title: subFolder.title,
        parent: pageFolder.id)
      NotificationCenter.default
        .post(name: .showAlert, object: object)
    }
  }
  func deleteAlbumInSecDepth(subAlbum: SubCollection) {
    if let album = photoData.albums[subAlbum.id] {
      pageFolder.deleteAlbum(album: album.phAssetCollection) { bool in
        if bool {
          dispatchAnimation {
            photoData
              .removeAlbumValue(album: album.phAssetCollection) {
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
  func loadNextStep() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
      if photoData.startView == .album {
        photoData.loadingState = .loadAllAlbums
      } else {
        photoData.loadingState = .doneAllAlbums
      }
    }
  }
  func scrollToNewitems(item: CellType,
                        scrollProxy: ScrollViewProxy) {
    let newItem = item == .folder
    ? pageFolder.foldersArray.last?.id
    : pageFolder.albumsArray.last?.id
    withAnimation {
      scrollProxy.scrollTo(newItem, anchor: .center)
    }
  }
}

enum SecondarySeetType {
  case moveCollection, photosPicker
}

//struct FancyFolderLineView_Previews: PreviewProvider {
//    static var previews: some View {
//        FancyFolderLineView(stateChangeObject: StateChangeObject(), pageFolder: Folder(isHome: true), uiMode: .fancy, isShowingSheet: .constant(false), isShowingPhotosPicker: .constant(false), isEditingMode: false, currentFolder: .constant(Folder(isHome: true)))
//    }
//}


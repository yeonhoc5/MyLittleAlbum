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
    let phCollectionList: PHCollectionList
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
    @State var processingCollection: PHCollection!

    @Environment(\.scenePhase) var scenePhase
    @State var isSetted: Bool = false
    
    var body: some View {
        let spacing = (screenWidth - 20 - secondaryWidth * ( CGFloat(listCount + 1))) / CGFloat(listCount)
        return HStack(spacing: 0) {
            if photoData.uiMode != .classic {
                Color.fancyBackground
                    .frame(width: 10 + secondaryWidth * 0.3)
                    .zIndex(1)
            }
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    if isSetted {
                        let column = Array(
                            repeating: GridItem(.fixed(secondaryWidth), spacing: isFolded ? 7 : spacing),
                            count: isFolded
                                    ? (pageFolder.fetchResult.count) + 1
                                    : listCount + 1
                        )
                        LazyVGrid(columns: column)  {
                            fetchSecondaryDepth(width: secondaryWidth,
                                                proxy: scrollProxy)
                        }
                        .padding(.leading,
                                 10 + (photoData.uiMode == .classic
                                       ? 0 : secondaryWidth * 0.3)
                        )
                        .transition(.slide)
                        .onAppear {
                            if isHome && photoData.loadingState == .doneSecondaryLines {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    photoData.loadingState = .loadAllAlbums
                                }
                            }
                        }
                    } else {
                        let padding: CGFloat = (secondaryWidth * 0.6) - 10
                        lottieLoadingView(lottie: "secondaryLoadingJson",
                                          size: CGSize(width: screenWidth - padding,
                                                       height: lineHeight),
                                          leadingPadding:padding)
                        .onAppear {
                            if photoData.folders[phCollectionList.localIdentifier] != nil {
                                dispatchAnimation {
                                    isSetted = true
                                }
                            }
                        }
                    }
                }
                .scrollDisabled(!isFolded)
                .onChange(of: photoData.loadingState) { newValue in
                    if isHome && (newValue == .doneSecondaryLines
                                  || newValue == .loadingComplete) {
                        DispatchQueue.main.async {
                            withAnimation {
                                isSetted = true
                            }
                        }
                    }
                }
                .onChange(of: pageFolder.albumsArray.count,
                          perform: { [oldValue = pageFolder.albumsArray.count] newValue in
                    if newValue > oldValue {
                        withAnimation {
                            scrollProxy
                                .scrollTo(pageFolder.albumsArray.last?.localIdentifier,
                                          anchor: .trailing)
                        }
                    }
                })
                .onChange(of: pageFolder.foldersArray.count,
                          perform: { [oldValue = pageFolder.foldersArray.count] newValue in
                    if newValue > oldValue {
                        withAnimation {
                            scrollProxy
                                .scrollTo(pageFolder.foldersArray.last?.localIdentifier)
                        }
                    }
                })
            }
        }
    }
}

// load photodata
extension SecondaryLineView {
    func fetchSecondaryDepth(width: CGFloat, proxy: ScrollViewProxy) -> some View {
        Group {
            ForEach(pageFolder.foldersArray, id: \.self) { folder in
                let secondaryIndex = pageFolder.foldersArray.firstIndex(of: folder) ?? 0
                folderListView(collectionList: folder,
                               index: index + ((secondaryIndex + 1) * 4),
                               width: width)
                    .matchedGeometryEffect(id: folder.localIdentifier,
                                           in: albumViewNameSpace)
                    .buttonStyle(ClickScaleEffect())
                    .transition(.scale)
                    .id(folder.localIdentifier)
            }
            ForEach(pageFolder.albumsArray, id: \.self) { album in
                let secondaryIndex = pageFolder.albumsArray.firstIndex(of: album) ?? 0
                albumListView(assetCollection: album,
                              index: index + secondaryIndex,
                              width: width)
                    .matchedGeometryEffect(id: album.localIdentifier,
                                           in: albumViewNameSpace)
                    .buttonStyle(ClickScaleEffect())
                    .transition(.scale)
                    .id(album.localIdentifier)
            }
        }
        .padding(.vertical, 6)
    }

    func folderListView(collectionList: PHCollectionList,
                        index: Int, width: CGFloat!) -> some View {
        NavigationLink {
            if let nextFolder = photoData.folders[collectionList.localIdentifier] {
                AlbumView(pageFolder: nextFolder,
                          phCollectionList: collectionList,
                          pageIndex: index,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace,
                          isShowingSettingView: .constant(false))
            }
        } label: {
            CellView(uiMode: photoData.uiMode,
                     cellType: .folder,
                     index: 0,
                     width: width) { size, cellNameSpace in
                Group {
                    if let nextFolder = photoData.folders[collectionList.localIdentifier] {
                        FolderCoverView(folder: nextFolder,
                                        phCollectionList: collectionList,
                                        uiMode: photoData.uiMode,
                                        size: size,
                                        cellNameSpace: cellNameSpace)
                    } else {
                        TempCoverView(title: collectionList.localizedTitle ?? "Loading...",
                                      nameSpace: cellNameSpace,
                                      size: size,
                                      cellType: .folder)
                    }
                }
                .matchedGeometryEffect(id: collectionList.localIdentifier,
                                       in: cellNameSpace)
                
            }
        }
        .buttonStyle(ClickScaleEffect())
        .disabled(isEditingMode)
        .contextMenu{ editFolderMenu(folder: collectionList) }
        .overlay(alignment: .topLeading) {
            btnDelete(collection: collectionList as PHCollection)
                .offset(x: -1, y: -1)
        }
    }
    
    func albumListView(assetCollection: PHAssetCollection,
                       index: Int = 0, width: CGFloat!) -> some View {
        return NavigationLink {
            AllPhotosView(assetCollection: assetCollection,
                          isHiddenAsset: false,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace)
        } label: {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                CellView(uiMode: photoData.uiMode,
                         cellType: .miniAlbum,
                         index: index,
                         width: width) { size, cellNameSpace in
                    Group {
                        if let album = photoData.albums[assetCollection.localIdentifier] {
                            AlbumCoverView(album: album,
                                           assetCollection: assetCollection,
                                           uiMode: photoData.uiMode,
                                           cellType: .miniAlbum,
                                           size: size,
                                           colorIndex: index,
                                           albumCell: cellNameSpace,
                                           isEditingMode: isEditingMode)
                            .matchedGeometryEffect(id: assetCollection.localIdentifier,
                                                   in: cellNameSpace)
                        } else {
                            TempCoverView(title: assetCollection.localizedTitle ?? "Loading...",
                                          nameSpace: cellNameSpace,
                                          size: size,
                                          cellType: .miniAlbum)
                        }
                    }
                }
                 .contextMenu{
                     editAlbumMenu(assetCollection: assetCollection, index: index)
                 }
            }
        }
        .buttonStyle(ClickScaleEffect())
        .disabled(isEditingMode)
        .overlay(alignment: .topLeading) {
            btnDelete(collection: assetCollection as PHCollection)
                .offset(x: -1, y: photoData.uiMode != .fancy ? -1 : 10)
        }
    }
}

// edit funcs (1/2) 폴더
extension SecondaryLineView {
    
    func editFolderMenu(folder: PHCollectionList) -> some View {
        VStack {
            Button {
                let alertObject = AlertObject(
                    alertCase: .addFolderToFolder,
                    album: nil,
                    folder: folder,
                    needsTextField: true)
                DispatchQueue.main.async {
                    NotificationCenter.default
                        .post(name: .showAlert,
                              object: alertObject)
                }
            } label: {
                let folderIcon = "folder.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 폴더 추가하기", image: folderIcon)
            }
            Button {
                let alertObject = AlertObject(
                    alertCase: .addAlbumToFolder,
                    album: nil,
                    folder: folder,
                    needsTextField: true)
                DispatchQueue.main.async {
                    NotificationCenter.default
                        .post(name: .showAlert,
                              object: alertObject)
                }
            } label: {
                let albumIcon = "rectangle.stack.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 앨범 추가하기", image: albumIcon)
            }
            Divider()
            Button {
                let alertObject = AlertObject(alertCase: .folderNameChange,
                                              album: nil,
                                              folder: folder,
                                              needsTextField: true)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .showAlert,
                                                    object: alertObject)
                }
            } label: {
                ContextMenuItem(title: "폴더 이름 변경하기", image: "pencil")
            }
            Button {
                let moveObject = MoveCollectionObject(
                    currentParent: pageFolder,
                    objectCellType: .folder,
                    objectFolder: folder,
                    objectAlbum: nil,
                    objectColorIndex: index,
                    objectIdentifier: folder.localIdentifier,
                    nameSpace: nameSpace)
                NotificationCenter.default
                    .post(name: .showMoveCollectionSheet, object: moveObject)
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                deleteFolderInSecDepth(folder: folder)
            } label: {
                ContextMenuItem(title: "이 폴더 삭제하기", image: "trash")
            }
            
        }
    }
    func btnDelete(collection: PHCollection) -> some View {
        Button {
            processingCollection = collection
            if let folder = collection as? PHCollectionList {
                deleteFolderInSecDepth(folder: folder)
            } else {
                if let album = collection as? PHAssetCollection {
                    deleteAlbumInSecDepth(album: album)
                }
            }
        } label: {
            RemoveButtonLabel(shapeType: .circle,
                              isProcessing: processingCollection == collection)
        }
        .opacity(isEditingMode ? 1:0)
        .scaleEffect(isEditingMode ? 1:0.1, anchor: .center)
        .buttonStyle(ClickScaleEffect())
    }
}
// edit funcs (2/2) 앨범
extension SecondaryLineView {
    
    func editAlbumMenu(assetCollection: PHAssetCollection,
                       index: Int) -> some View {
        VStack {
            // 앨범에 미디어 추가
            Button {
                guard let album = photoData.albums[assetCollection.localIdentifier] else { return }
                let object = PickerObject(editToAlbum: album.id,
                                          imageManager: PHCachingImageManager())
                DispatchQueue.main.async {
                    NotificationCenter.default
                        .post(name: .showPhotosPicker, object: object)
                }
            } label: {
                let addPhotoIcon = "person.crop.rectangle.badge.plus.fill"
                ContextMenuItem(title: "앨범에 미디어 추가하기", image: addPhotoIcon)
            }
            Divider()
            // 앨범 이름 변경
            Button {
                guard let album = photoData.albums[assetCollection.localIdentifier]
                else { return }
                let alertObject = AlertObject(alertCase: .albumNameChange,
                                              album: album.phAssetCollection,
                                              folder: nil,
                                              needsTextField: true)
                NotificationCenter.default.post(name: .showAlert,
                                                object: alertObject)
            } label: {
                ContextMenuItem(title: "앨범 이름 변경하기", image: "pencil")
            }
            // 다른 폴더로 이동
            Button {
                let moveObject = MoveCollectionObject(
                    currentParent: pageFolder,
                    objectCellType: .miniAlbum,
                    objectFolder: nil,
                    objectAlbum: assetCollection,
                    objectColorIndex: index,
                    objectIdentifier: assetCollection.localIdentifier,
                    nameSpace: nameSpace)
                NotificationCenter.default
                    .post(name: .showMoveCollectionSheet,
                          object: moveObject)
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                deleteAlbumInSecDepth(album: assetCollection)
            } label: {
                ContextMenuItem(title: "이 앨범 삭제하기", image: "trash")
            }
            
        }
    }
    // 앨범 삭제
    func deleteFolderInSecDepth(folder: PHCollectionList) {
        pageFolder.deleteFolder(folder: folder) { bool in
            if bool {
                dispatchAnimation {
                    photoData.removeFolderValue(folder: folder) {
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
    func deleteAlbumInSecDepth(album: PHAssetCollection)  {
        pageFolder.deleteAlbum(album: album) { bool in
            if bool {
                dispatchAnimation {
                    photoData.removeAlbumValue(album: album) {
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

enum SecondarySeetType {
    case moveCollection, photosPicker
}

//struct FancyFolderLineView_Previews: PreviewProvider {
//    static var previews: some View {
//        FancyFolderLineView(stateChangeObject: StateChangeObject(), pageFolder: Folder(isHome: true), uiMode: .fancy, isShowingSheet: .constant(false), isShowingPhotosPicker: .constant(false), isEditingMode: false, currentFolder: .constant(Folder(isHome: true)))
//    }
//}


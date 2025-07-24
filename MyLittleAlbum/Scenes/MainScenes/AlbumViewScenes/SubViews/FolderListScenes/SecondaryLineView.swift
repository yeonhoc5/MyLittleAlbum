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
    let phCollectionList: PHCollectionList
    let index: Int
    let secondaryWidth: CGFloat
    let lineHeight: CGFloat
    let isFolded: Bool
    
    @Binding var isPhotosView: Int
    let nameSpace: Namespace.ID
    let albumViewNameSpace: Namespace.ID

    let isEditingMode: Bool
    @State var processingCollection: PHCollection!
    
    @Namespace private var albumEdge
    @Namespace private var secondaryEdge

    @Environment(\.scenePhase) var scenePhase
    @State var isSetted: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            if photoData.uiMode != .classic {
                Color.fancyBackground
                    .frame(width: 10 + secondaryWidth * 0.3)
                    .zIndex(1)
            }
            if isSetted {
                ScrollViewReader { scrollProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        let spacing = (screenWidth - 20 - secondaryWidth * ( CGFloat(listCount + 1))) / CGFloat(listCount)
                        if isSetted {
                            if let pageFolder = photoData.folders[phCollectionList.localIdentifier] {
                                let column = Array(
                                    repeating: GridItem(.fixed(secondaryWidth),
                                                        spacing: isFolded ? 7 : spacing),
                                    count: isFolded ? pageFolder.fetchResult.count + 1 : listCount + 1)
                                LazyVGrid(columns: column)  {
                                    secondaryDepthView(folder: pageFolder,
                                                       proxy: scrollProxy)
                                }
                                .matchedGeometryEffect(id: "contatiner", in: secondaryEdge)
                                .padding(.leading,
                                          10 + (photoData.uiMode == .classic
                                                ? 0 : secondaryWidth * 0.3)
                                )
                            }
                        }
                    }
                    .scrollDisabled(!isFolded)
                }
                .transition(.slide)
            } else {
                GeometryReader { geometry in
                    lottieLoadingView(lottie: "secondaryLoadingJson",
                                      size: geometry.size,
                                      leadingPadding: (secondaryWidth * 0.6) - 10)
                }
                .frame(height: abs(lineHeight))
                .task {
                    dispatchAnimation {
                        isSetted = true
                    }
                }
            }
        }
//        .onChange(of: scenePhase) { [oldValue = scenePhase] newValue in
//            if oldValue != newValue {
//                if newValue == .background {
//                    print("background View")
//                    DispatchQueue.global().async {
//                        self.isSetted = false
//                    }
//                } else if newValue == .active {
//                    print("active View")
//                    DispatchQueue.main.async {
//                        withAnimation {
//                            self.isSetted = true
//                        }
//                    }
//                }
//            }
//        }
    }
}

// load photodata
extension SecondaryLineView {
    func secondaryDepthView(folder: MLFolder, proxy: ScrollViewProxy) -> some View {
        fetchSecondaryDepth(pageFolder: folder, width: secondaryWidth, proxy: proxy)
            .id("secondaryEdge")
            .onChange(of: folder.fetchResult, perform: { [oldValue = folder.fetchResult] newValue in
                if newValue.count > oldValue.count {
                    if let id = (newValue.lastObject as? PHAssetCollection)?.localIdentifier {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.interactiveSpring()) {
                                proxy.scrollTo(id, anchor: .bottomTrailing)
                            }
                        }
                    } else {
                        if let id = (newValue.lastObject as? PHCollectionList)?.localIdentifier {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.interactiveSpring()) {
                                    proxy.scrollTo(id, anchor: .bottomTrailing)
                                }
                            }
                        }
                    }
                }
            })
            .onReceive(NotificationCenter.default
                .publisher(for: .scrollToItem)) { output in
                    if let scrollObject = output.object as? ScrollItem {
                        if folder.albumsArray
                            .compactMap({ $0.localIdentifier })
                            .contains(scrollObject.identifier) {
                            withAnimation {
                                proxy
                                    .scrollTo(scrollObject.identifier, anchor: .trailing)
                            }
                        }
                    }
                }
    }
    
    func fetchSecondaryDepth(pageFolder: MLFolder, width: CGFloat, proxy: ScrollViewProxy) -> some View {
        Group {
            ForEach(pageFolder.foldersArray, id: \.localIdentifier) { folder in
                let secondaryIndex = pageFolder.foldersArray.firstIndex(of: folder) ?? 0
                folderListView(collectionList: folder,
                               index: index + ((secondaryIndex + 1) * 4),
                               width: width)
                    .id(folder.localIdentifier)
                    .matchedGeometryEffect(id: folder.localIdentifier,
                                           in: albumViewNameSpace)
                    .buttonStyle(ClickScaleEffect())
                    .transition(.scale)
            }
            ForEach(pageFolder.albumsArray, id: \.localIdentifier) { album in
                let secondaryIndex = pageFolder.albumsArray.firstIndex(of: album) ?? 0
                albumListView(assetCollection: album,
                              index: index + secondaryIndex,
                              width: width)
                    .id(album.localIdentifier)
                    .matchedGeometryEffect(id: album.localIdentifier,
                                           in: albumViewNameSpace)
                    .buttonStyle(ClickScaleEffect())
                    .transition(.scale)
            }
        }
        .padding(.vertical, 6)
//        .id(albumEdge)
    }

    func folderListView(collectionList: PHCollectionList,
                        index: Int, width: CGFloat!) -> some View {
        NavigationLink {
            AlbumView(phCollectionList: collectionList,
                      pageIndex: index,
                      isPhotosView: $isPhotosView,
                      nameSpace: nameSpace,
                      isShowingSettingView: .constant(false))
        } label: {
            CellView(uiMode: photoData.uiMode,
                     cellType: .folder,
                     index: 0,
                     width: width, tapAction: {
            }) { size, cellNameSpace in
                Group {
                    if let nextFolder = photoData.folders[collectionList.localIdentifier] {
                        FolderCoverView(folder: nextFolder,
                                        uiMode: photoData.uiMode,
                                        size: size,
                                        cellNameSpace: cellNameSpace)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: size.width,
                                   height: size.height * 0.6)
                            .offset(y: size.height * 0.4)
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
                         width: width,
                         tapAction: {
                    guard let album = photoData.albums[assetCollection.localIdentifier]
                    else { return }
                    if album.frObject(isHiddenAsset: false) != album.photosArray.map({ $0.phAsset }) {
                        album.generateArray(isHiddenAsset: false) { }
                    }
                }) { size, cellNameSpace in
                    Group {
                    AlbumCoverView(assetCollection: assetCollection,
                                   cellType: .miniAlbum,
                                   size: size,
                                   colorIndex: index,
                                   padding: 5,
                                   albumCell: cellNameSpace)
                    .matchedGeometryEffect(id: assetCollection.localIdentifier,
                                           in: cellNameSpace)
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
                guard let pageFolder = photoData.folders[phCollectionList.localIdentifier]
                else { return }
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
        Group {
            if processingCollection == collection {
                ProgressView()
                    .tint(.red)
                    .progressViewStyle(.circular)
            } else {
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
                    RemoveButtonLabel(shapeType: .circle)
                }
                .opacity(isEditingMode ? 1:0)
                .scaleEffect(isEditingMode ? 1:0.1, anchor: .center)
                .buttonStyle(ClickScaleEffect())
            }
        }
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
                let object = PickerObject(editToAlbum: album,
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
                guard let pageFolder = photoData.folders[phCollectionList.localIdentifier]
                else { return }
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
        guard let pageFolder = photoData.folders[phCollectionList.localIdentifier]
        else { return }
        pageFolder.deleteFolder(folder: folder) { bool in
            if bool {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        let _ = photoData.folders
                            .removeValue(forKey: folder.localIdentifier)
                    }
                }
                DispatchQueue.global().async {
                    if let _ = photoData.recentWorkFolder.firstIndex(of: folder.localIdentifier) {
                        photoData
                            .removeRecentWork(isFolder: true, id: folder.localIdentifier)
                    }
                }
            }
            dispatchAnimation {
                processingCollection = nil 
            }
        }
    }
    func deleteAlbumInSecDepth(album: PHAssetCollection)  {
        guard let pageFolder = photoData.folders[phCollectionList.localIdentifier]
        else { return }
        pageFolder.deleteAlbum(album: album) { _ in
//            if bool {
//                DispatchQueue.global().async {
//                    if let index = photoData.recentWorkAlbum.firstIndex(of: album.localIdentifier) {
//                        photoData.removeRecentWork(isFolder: false, index: index)
//                    }
//                }
//            }
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


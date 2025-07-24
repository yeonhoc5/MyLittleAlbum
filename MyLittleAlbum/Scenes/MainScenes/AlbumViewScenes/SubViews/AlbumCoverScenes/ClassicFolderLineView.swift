//
//  ClassicFolderLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/11/26.
//

import SwiftUI
import Photos
import LottieUI

struct ClassicFolderLineView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @ObservedObject var stateChangeObject: StateChangeObject
    @StateObject var pageFolder: MLFolder
    
    var width: CGFloat
    @Binding var isPhotosView: Int

    @State private var showingLine: Bool = false
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    @Binding var isShowingReorderSheet: Bool
    var isEditingMode: Bool

    var nameSpace: Namespace.ID
    var albumViewNameSpace: Namespace.ID
    @Binding var currentFolder: MLFolder!
    @State var secondaryFolder: MLFolder!
    
    var body: some View {
        let secondaryWidth = width - 5
            Group {
                if secondaryFolder == nil {
                    LottieView("secondaryLoadingJson")
                            .play(true)
                            .loopMode(.loop)
                            .frame(width: screenWidth,
                                   height: cellHeight(width: secondaryWidth,
                                                      uiMode: .classic, cellType: .folder),
                                   alignment: .center)
                        .onAppear {
                            DispatchQueue.main.async {
                                withAnimation {
                                    secondaryFolder = pageFolder
                                }
                            }
                        }
                } else {
                    let secondaryDepthList = fetchSecondaryDepth(
                        pageFolder: pageFolder, width: secondaryWidth
                    )
                    secondaryDepthView(
                        view: secondaryDepthList,
                        mode: showingLine,
                        width: secondaryWidth)
                }
            }
            .padding(.leading, 5)
    }
}

extension ClassicFolderLineView {
    func secondaryDepthView(view: some View, mode: Bool, width: CGFloat) -> some View {
        let spacing = (screenWidth - (CGFloat(listCount+1) * width)) / CGFloat(listCount+1)
        let albumCount = pageFolder.albumsArray.count
        let folderCount = pageFolder.foldersArray.count
        
        let column = Array(
            repeating: GridItem(spacing: mode ? spacing : 10),
            count: albumCount + folderCount >= listCount+1
                    ? (mode ? (listCount+1) : albumCount + folderCount)
                    : albumCount + folderCount)
        return ScrollViewReader(content: { proxy in
            ScrollView(.horizontal, showsIndicators: false, content: {
                LazyVGrid(columns: column)  {
                    view
                }
                .transition(.scale(scale: 1, anchor: .topTrailing))
                .id("minialbumEdge")
                .padding([.leading, .vertical], 10)
                .padding(.trailing, 5)
            })
            .scrollDisabled(mode)
//            .onChange(of: pageFolder.albumsArray.count) {
//                [oldValue = pageFolder.albumsArray.count] newValue in
//                if oldValue < newValue && !mode {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                        withAnimation(.interactiveSpring()) {
//                            proxy.scrollTo(albumViewEdge, anchor: .trailing)
//                        }
//                    }
//                }
//            }
        })
    }
    
    func fetchSecondaryDepth(pageFolder: MLFolder, width: CGFloat) -> some View {
        Group {
            ForEach(pageFolder.foldersArray, id: \.localIdentifier) { folder in
//                let secondary = photoData.folders[folder.localIdentifier] ?? MLFolder(collectionList: folder)
                viewForEachfolder(folder: folder, width: width)
                    .id(folder.localIdentifier)
                    .matchedGeometryEffect(id: folder.localIdentifier,
                                           in: albumViewNameSpace)
                    .buttonStyle(ClickScaleEffect())
            }
            ForEach(pageFolder.albumsArray, id: \.localIdentifier) { album in
                viewForEachAlbum(album: album, width: width)
                    .id(album.localIdentifier)
                    .matchedGeometryEffect(id: album.localIdentifier,
                                           in: albumViewNameSpace)
                    .buttonStyle(ClickScaleEffect())
            }
        }
    }
    func viewForEachfolder(folder: PHCollectionList, width: CGFloat) -> some View {
        NavigationLink {
            AlbumView(phCollectionList: folder,
                      pageIndex: 0,
                      isPhotosView: $isPhotosView,
                      nameSpace: nameSpace,
                      isShowingSettingView: .constant(false))
        } label: {
//            CellView(uiMode: .classic,
//                     cellType: .folder,
//                     title: folder.title,
//                     index: 0,
//                     width: width) { size in
//                EmptyView()
//            }
        }
//        .contextMenu{ editFolderMenu(folder: folder, isUpper: false) }
        .overlay(alignment: .topLeading) {
            Button {
                deleteFolderInSecDepth(folder: folder)
            } label: {
                RemoveButtonLabel(shapeType: .circle)
            }
            .opacity(isEditingMode ? 1:0)
            .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
            .offset(x: -3, y: -2)
        }
    }
    func viewForEachAlbum(album: PHAssetCollection, width: CGFloat) -> some View {
        NavigationLink {
            if let mlAlbum = photoData.albums[album.localIdentifier] {
                AllPhotosView(assetCollection: album,
                              mlAlbum: mlAlbum,
                              isHiddenAsset: false,
                              isPhotosView: $isPhotosView,
                              nameSpace: nameSpace)
            }
        } label: {
//            let height = cellHeight(width: width, uiMode: photoData.uiMode, cellType: .folder)
//                CellView(uiMode: .classic,
//                         cellType: .miniAlbum,
//                         title: album.title,
//                         index: 0,
//                         width: width) { size in
//                    EmptyView()
//                }
                //            ClassicCell(cellType: .miniAlbum,
                //                        title: album.title,
                //                        count: album.fetchResult.count,
                //                        rprstPhoto1: album.rpstPhoto1,
                //                        width: width)
//            .frame(width: width, height: height)
        }
        .contextMenu{ editAlbumMenu(album: album) }
        .overlay(alignment: .topLeading) {
            Button {
//                deleteAlbumInSecDepth(album: album)
            } label: {
                RemoveButtonLabel(shapeType: .circle)
            }
            .opacity(isEditingMode ? 1:0)
            .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
            .offset(x: -3, y: -2)
        }
    }
    
    func sectionView(title: String, mode: Binding<Bool>) -> some View {
        HStack {
            Group {
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(.orange).font(.system(size: 12))
                    .rotationEffect(Angle(radians: !mode.wrappedValue ? -.pi/2 : 0))
                Text(title)
                    .foregroundColor(.orange).fontWeight(.bold)
                Text("(\(pageFolder.foldersArray.count) / \(pageFolder.albumsArray.count))")
                    .font(.footnote).foregroundColor(.gray)
            }
            .frame(height: 20)
            .onTapGesture {
                withAnimation(.interactiveSpring(response: 0.25,
                                                 dampingFraction: 0.9,
                                                 blendDuration: 0.2)) {
                    mode.wrappedValue.toggle()
                }
            }
            .disabled(isEditingMode || stateChangeObject.isShowingMenu)
            Spacer()
            Menu {
                editFolderMenu(folder: pageFolder, isUpper: true)
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 15)
            .buttonStyle(ClickScaleEffect(scale: 0.8))
        }
    }
    
//    var secondaryListViewOneLine: some View {
//        ScrollView(.horizontal, showsIndicators: false, content: {
//            HStack(alignment: .bottom, spacing: 5) {
//                fetchSecondaryDepth(pageFolder: self.pageFolder,
//                                    width: width)
//                .padding(.top, 5)
//            }
//            .padding(.leading, 25)
//            .padding(.trailing, 15)
//        })
//    }
//    
//    var secondaryListViewAllList: some View {
//        let column = Array(repeating: GridItem(.flexible(), alignment: .bottomLeading),
//                           count: Int(screenSize.width / (width + 10)))
//        return LazyVGrid(columns: column, alignment: .center, spacing: 5) {
//            fetchSecondaryDepth(pageFolder: self.pageFolder,
//                                width: width)
//            .padding(.top, 5)
//        }
//        .padding(.leading, 25)
//        .padding(.trailing, 10)
//    }
    
    
}


//struct FolderSectionView: View {
//    let title: String
//    
//    
//    var body: some View {
//        HStack {
//            Group {
//                Image(systemName: "arrowtriangle.down.fill")
//                    .foregroundColor(.orange).font(.system(size: 12))
//                    .rotationEffect(Angle(radians: !showingLine ? -.pi/2 : 0))
//                Text(title)
//                    .foregroundColor(.orange).fontWeight(.bold)
//                Text("(\(pageFolder.folderArray.count) / \(pageFolder.albumArray.count))")
//                    .font(.footnote).foregroundColor(.gray)
//            }
//            .frame(height: 20)
//            .onTapGesture {
//                withAnimation(.interactiveSpring(response: 0.25,
//                                                 dampingFraction: 0.9,
//                                                 blendDuration: 0.2)) {
//                    mode.wrappedValue.toggle()
//                }
//            }
//            .disabled(isEditingMode || stateChangeObject.isShowingMenu)
//            Spacer()
//            Menu {
//                if let folder = pageFolder.folder {
//                    editFolderMenu(folder: folder, isUpper: true)
//                }
//            } label: {
//                Image(systemName: "square.and.pencil")
//                    .foregroundColor(.secondary)
//            }
//            .padding(.trailing, 15)
//            .buttonStyle(ClickScaleEffect(scale: 0.8))
//        }
//    }
//}
 
extension ClassicFolderLineView {
    func deleteFolderInDepth(folder: PHCollection)  {
        let folder = folder as! PHCollectionList
        pageFolder.deleteFolder(folder: folder, completion: { bool in
        })
    }
    
    func deleteFolderInSecDepth(folder: PHCollectionList) {
        pageFolder.deleteFolder(folder: folder) { bool in
        }
    }
//    func deleteAlbumInSecDepth(album: MLAlbum)  {
//        album.deleteAlbum() { bool in
//        }
//    }
    
    func editFolderMenu(folder: MLFolder, isUpper: Bool = false) -> some View {
        VStack {
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .none,
                                 preesed: .folder,
                                 toAdd: .folder,
                                 edit: .add,
                                 collection: folder.phCollectionList)
                    let alertObject = AlertObject(
                        alertCase: .addFolderToFolder,
                        album: nil,
                        folder: folder.phCollectionList,
                        needsTextField: true)
                    NotificationCenter.default
                        .post(name: .showAlert,
                              object: alertObject)
                }
            } label: {
                let folderIcon = "folder.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 폴더 추가하기", image: folderIcon)
            }
            Button {
                DispatchQueue.main.async {
//                    showingAlert(depth: .none, preesed: .folder, toAdd: .album, edit: .add, collection: folder)
                    let alertObject = AlertObject(
                        alertCase: .addAlbumToFolder,
                        album: nil,
                        folder: folder.phCollectionList,
                        needsTextField: true)
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
                DispatchQueue.main.async {
                    let alertObject = AlertObject(
                        alertCase: .folderNameChange,
                        album: nil,
                        folder: folder.phCollectionList,
                        needsTextField: true)
                    NotificationCenter.default
                        .post(name: .showAlert,
                              object: alertObject)
//                    showingAlert(depth: .secondary, preesed: .folder, toAdd: .none, edit: .modify, collection: folder.folder)
                }
            } label: {
                ContextMenuItem(title: "폴더 이름 변경하기", image: "pencil")
            }
            if isUpper {
                Button {
                    currentFolder = pageFolder
                    isShowingReorderSheet = true
                } label: {
                    let albumIcon = "rectangle.stack.fill.badge.plus"
                    ContextMenuItem(title: "폴더 내 순서 조정하기", image: albumIcon)
                }
            }
            Divider()
            Button {
                currentFolder = pageFolder
                stateChangeObject.collectionToEdit = folder.phCollectionList as PHCollection
                self.isShowingSheet = true
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                deleteFolderInSecDepth(folder: folder.phCollectionList)
            } label: {
                ContextMenuItem(title: "이 폴더 삭제하기", image: "trash")
            }
        }
    }
    
    func editAlbumMenu(album: PHAssetCollection, fIndex: Int! = 0, aIndex: Int! = 0) -> some View {
        VStack {
            Button {
                stateChangeObject.collectionToEdit = album
                self.isShowingPhotosPicker.toggle()
            } label: {
                let addPhotoIcon = "person.crop.rectangle.badge.plus.fill"
                ContextMenuItem(title: "앨범에 사진 추가하기", image: addPhotoIcon)
            }
            Divider()
            Button {
                showingAlert(depth: .secondary, preesed: .album, toAdd: .album, edit: .modify, collection: album)
            } label: {
                ContextMenuItem(title: "앨범 이름 변경하기", image: "pencil")
            }
            Divider()
            Button {
                currentFolder = pageFolder
                stateChangeObject.collectionToEdit = album
                self.isShowingSheet = true
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
//                deleteAlbumInSecDepth(album: album.phAssetCollection)
            } label: {
                ContextMenuItem(title: "이 앨범 삭제하기", image: "trash")
            }
        }
    }
    
    func showingAlert(depth: DepthType, preesed: PressedType, toAdd: CollectionType, edit: EditType, collection: PHCollection) {
        stateChangeObject.depthType = depth
        stateChangeObject.pressedType = preesed
        stateChangeObject.collectionType = toAdd
        stateChangeObject.editType = edit
        stateChangeObject.collectionToEdit = collection
    }
    
    func showingSheet(type: SecondarySeetType,
                      currentFolder: MLFolder! = nil,
                      selectedCollection: PHCollection! = nil) {
        switch type {
        case .moveCollection:
            self.currentFolder = currentFolder
            stateChangeObject.collectionToEdit = selectedCollection
            isShowingSheet = true
        case .photosPicker:
            self.isShowingPhotosPicker = true
            stateChangeObject.collectionToEdit = selectedCollection
        }
    }
}

//struct ClassicFolderLineView_Previews: PreviewProvider {
//    static var previews: some View {
//        ClassicFolderLineView(stateChangeObject: StateChangeObject(),
//                              pageFolder: Folder(isHome: true),
//                              randomNum1: 0, randomNum2: 0,
//                              isShowingSheet: .constant(false),
//                              isShowingPhotosPicker: .constant(false),
//                              isShowingReorderSheet: .constant(false),
//                              isEditingMode: false,
//                              currentFolder: .constant(.none))
//    }
//}

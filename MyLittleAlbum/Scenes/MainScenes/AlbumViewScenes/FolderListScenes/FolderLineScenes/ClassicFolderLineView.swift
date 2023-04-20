//
//  FolderLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/11/26.
//

import SwiftUI
import Photos

struct ClassicFolderLineView: View {
    @ObservedObject var stateChangeObject: StateChangeObject
    @StateObject var pageFolder: Folder
    
    var randomNum1: Int = 0
    var randomNum2: Int = 0
    var widthOfAlbum: CGFloat? = (screenSize.width - 35) / 4 - 5
    var heightOfAlbum: CGFloat? = (screenSize.width - 35) / 4 - 10

    @State private var showingLine: Bool = true
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    @Binding var isShowingReorderSheet: Bool
    var isEditingMode: Bool
    
    @Namespace private var namespace    
    @Binding var currentFolder: Folder!
    
    @State var navigationOffset: CGFloat = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                sectionView(title: pageFolder.folder?.localizedTitle ?? "")
                    .zIndex(1)
                    .padding(.bottom, 5)
                CustomDivider(color: .secondary)
            }
            .padding(.leading, 0)
            if pageFolder.folderArray.count + pageFolder.albumArray.count < 5 {
                secondaryListViewOneLine
            } else {
                if showingLine {
                    secondaryListViewOneLine
                } else {
                    secondaryListViewAllList
                }
            }
        }
        .padding(.bottom, 5)
    }
}

extension ClassicFolderLineView {
    func sectionView(title: String) -> some View {
        HStack {
            Group {
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(.orange).font(.system(size: 12))
                    .rotationEffect(Angle(radians: showingLine ? -.pi/2 : 0))
                    .padding(.leading, 10)
                Text(title)
                    .foregroundColor(.orange).fontWeight(.bold)
                Text("(\(pageFolder.folderArray.count) / \(pageFolder.albumArray.count))")
                    .font(.footnote).foregroundColor(.gray)
            }
            .frame(height: 20)
            .onTapGesture {
                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.9, blendDuration: 0.2)) {
                    self.showingLine.toggle()
                }
            }
            .disabled(isEditingMode || stateChangeObject.isShowingMenu)
            Spacer()
            Menu {
                if let folder = pageFolder.folder {
                    editFolderMenu(folder: folder, isUpper: true)
                }
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 15)
            .buttonStyle(ClickScaleEffect(scale: 0.8))
        }
    }

    
    var secondaryListViewOneLine: some View {
        ScrollView(.horizontal, showsIndicators: false, content: {
            HStack(alignment: .bottom, spacing: 5) {
                fetchSecondaryDepth(pageFolder: self.pageFolder)
                    .padding(.top, 5)
            }
            .padding(.leading, 25)
            .padding(.trailing, 15)
        })
    }
    
    var secondaryListViewAllList: some View {
        let column = Array(repeating: GridItem(.flexible(), alignment: .bottomLeading), count: Int(screenSize.width / (widthOfAlbum! + 10)))
        return LazyVGrid(columns: column, alignment: .center, spacing: 5) {
            fetchSecondaryDepth(pageFolder: self.pageFolder)
                .padding(.top, 5)
        }
        .padding(.leading, 25)
        .padding(.trailing, 10)
    }
    
    func fetchSecondaryDepth(pageFolder: Folder) -> some View {
        Group {
            ForEach(pageFolder.folderArray, id: \.self) { secondaryFolder in
//                let index = pageFolder.folderArray.firstIndex(of: secondaryFolder) ?? 0
                let nextFolder = Folder(folder: secondaryFolder, colorIndex: 0)
                NavigationLink {
                    AlbumView(stateChangeObject: StateChangeObject(),
                              pageFolder: nextFolder,
                              isShowingSettingView: .constant(false))
                } label: {
                    ClassicCell(cellType: .folder,
                                title: nextFolder.title,
                                countAlbum: nextFolder.albumArray.count,
                                countFolder: nextFolder.folderArray.count,
                                showingLine: showingLine)
                }
                .buttonStyle(ClickScaleEffect())
                .contextMenu{ editFolderMenu(folder: nextFolder.folder, isUpper: false) }
                .overlay(alignment: .topLeading) {
                    Button {
                        deleteFolderInSecDepth(folder: nextFolder.folder)
                    } label: {
                        RemoveButtonLabel(shapeType: .circle)
                    }
                    .opacity(isEditingMode ? 1:0)
                    .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
                    .buttonStyle(ClickScaleEffect())
                    .offset(x: -3, y: -2)
                }
                .matchedGeometryEffect(id: nextFolder.identifier, in: namespace)
                .id(nextFolder.identifier)
            }
            ForEach(pageFolder.albumArray, id: \.self) { secondaryAlbum in
                let album = Album(album: secondaryAlbum, colorIndex: 0, randomNum1: randomNum1, randomNum2: randomNum2)
                NavigationLink {
                    AllPhotosView(album: album)
                } label: {
                    ClassicCell(cellType: .miniAlbum,
                                title: album.title,
                                rprsttivePhoto1: album.rprsttivePhoto1,
                                showingLine: showingLine)
                }
                .buttonStyle(ClickScaleEffect())
                .contextMenu{ editAlbumMenu(album: album) }
                .overlay(alignment: .topLeading) {
                    Button {
                        deleteAlbumInSecDepth(album: album)
                    } label: {
                        RemoveButtonLabel(shapeType: .circle)
                    }
                    .opacity(isEditingMode ? 1:0)
                    .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
                    .buttonStyle(ClickScaleEffect())
                    .offset(x: -3, y: -2)
                }
                .matchedGeometryEffect(id: album.identifier, in: namespace)
                .id(album.identifier)
            }
        }
    }
    
    func deleteFolderInDepth(folder: PHCollection)  {
        let folder = folder as! PHCollectionList
        pageFolder.deleteFolder(folder: folder, completion: { bool in
        })
    }
    
    func deleteFolderInSecDepth(folder: PHCollectionList) {
        pageFolder.deleteFolder(folder: folder) { bool in
        }
    }
    func deleteAlbumInSecDepth(album: Album)  {
        album.deleteAlbum() { bool in
        }
    }
    
    func editFolderMenu(folder: PHCollectionList, isUpper: Bool = false) -> some View {
        VStack {
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .none, preesed: .folder, toAdd: .folder, edit: .add, collection: folder)
                }
            } label: {
                let folderIcon = "folder.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 폴더 추가하기", image: folderIcon)
            }
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .none, preesed: .folder, toAdd: .album, edit: .add, collection: folder)
                }
            } label: {
                let albumIcon = "rectangle.stack.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 앨범 추가하기", image: albumIcon)
            }
            Divider()
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .secondary, preesed: .folder, toAdd: .none, edit: .modify, collection: folder)
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
                stateChangeObject.collectionToEdit = folder as PHCollection
                self.isShowingSheet = true
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
    
    func editAlbumMenu(album: Album, fIndex: Int! = 0, aIndex: Int! = 0) -> some View {
        VStack {
            Button {
                stateChangeObject.collectionToEdit = album.album
                self.isShowingPhotosPicker.toggle()
                
            } label: {
                let addPhotoIcon = "person.crop.rectangle.badge.plus.fill"
                ContextMenuItem(title: "앨범에 사진 추가하기", image: addPhotoIcon)
            }
            Divider()
            Button {
                showingAlert(depth: .secondary, preesed: .album, toAdd: .album, edit: .modify, collection: album.album)
            } label: {
                ContextMenuItem(title: "앨범 이름 변경하기", image: "pencil")
            }
            Divider()
            Button {
                currentFolder = pageFolder
                stateChangeObject.collectionToEdit = album.album
                self.isShowingSheet = true
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                deleteAlbumInSecDepth(album: album)
            } label: {
                ContextMenuItem(title: "이 앨범 삭제하기", image: "trash")
            }
        }
    }
    
    func showingAlert(depth: DepthType, preesed: PressedType, toAdd: CollectionType, edit: EditType, collection: PHCollection) {
        stateChangeObject.isShowingAlert = true
        stateChangeObject.depthType = depth
        stateChangeObject.pressedType = preesed
        stateChangeObject.collectionType = toAdd
        stateChangeObject.editType = edit
        stateChangeObject.collectionToEdit = collection
    }
    
    func showingSheet(type: SecondarySeetType, currentFolder: Folder! = nil, selectedCollection: PHCollection! = nil) {
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

struct ClassicFolderLineView_Previews: PreviewProvider {
    static var previews: some View {
        ClassicFolderLineView(stateChangeObject: StateChangeObject(),
                              pageFolder: Folder(isHome: true),
                              randomNum1: 0, randomNum2: 0,
                              isShowingSheet: .constant(false),
                              isShowingPhotosPicker: .constant(false),
                              isShowingReorderSheet: .constant(false),
                              isEditingMode: false,
                              currentFolder: .constant(.none))
    }
}

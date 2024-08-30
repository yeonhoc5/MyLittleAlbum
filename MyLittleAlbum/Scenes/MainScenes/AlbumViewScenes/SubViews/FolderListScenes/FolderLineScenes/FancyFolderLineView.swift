//
//  FancyFolderLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import SwiftUI
import Photos
import LottieUI


struct FancyFolderLineView: View {
    @ObservedObject var stateChangeObject: StateChangeObject
    @StateObject var pageFolder: Folder

    // 로딩뷰는 top폴더에서만 실행
    var isTopFolder = false
    var uiMode: UIMode
    var randomNum1: Int = 0
    var randomNum2: Int = 0
    var width: CGFloat
    @Binding var isPhotosView: Int
    var nameSpace: Namespace.ID
    var albumViewNameSpace: Namespace.ID
    
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    var isEditingMode: Bool
    
    @Namespace private var albumEdge
    @Namespace private var secondaryEdge
    @Binding var currentFolder: Folder!
    @State var secondaryFolder: Folder!

    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        GeometryReader(content: { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    if secondaryFolder == nil {
                        loadingView(size: geometry.size)
                            .onAppear {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        self.secondaryFolder = pageFolder
                                    }
                                }
                            }
                    } else {
                        secondaryDepthView(proxy: scrollProxy)
                    }
                }
            }
        })
        .padding(.leading, 20)
    }
}

// load photodata
extension FancyFolderLineView {
    func loadingView(size: CGSize) -> some View {
        Group {
            switch isTopFolder {
            case true: LottieView(secondaryLoadingJson)
                    .play(true)
                    .loopMode(.loop)
            default: Rectangle()}
        }
        .padding(.leading, width * 0.6 - 10)
        .frame(width: size.width, height: size.height)
        .foregroundColor(.clear)
    }
    
    func secondaryDepthView(proxy: ScrollViewProxy) -> some View {
        fetchSecondaryDepth(pageFolder: secondaryFolder, width: width)
            .transition(.slide.combined(with: .opacity))
            .padding(.leading, (width * 0.6 - 10))
            .padding(.trailing, 10)
            .padding(.vertical, 5)
            .id(secondaryEdge)
            .onChange(of: pageFolder.countFolder) { [oldValue = pageFolder.countFolder] newValue in
                if oldValue < newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.interactiveSpring()) {
                            proxy.scrollTo(pageFolder.folderArray[oldValue].localIdentifier,
                                           anchor: .trailing)
                        }
                    }
                }
            }
            .onChange(of: pageFolder.countAlbum) { [oldValue = pageFolder.countAlbum] newValue in
                if oldValue < newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.interactiveSpring()) {
                            proxy.scrollTo(secondaryEdge, 
                                           anchor: .trailing)
                        }
                    }
                }
            }
    }
    
    func fetchSecondaryDepth(pageFolder: Folder, width: CGFloat? = 100) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            let folders = pageFolder.folderArray
            let albums = pageFolder.albumArray
            HStack(alignment: .bottom) {
                ForEach(0..<folders.count, id: \.self) { index in
                    let nextFolder = Folder(folder: folders[index],
                                            colorIndex: pageFolder.colorIndex + 4 * (index + 1))
                    folderListView(nextFolder: nextFolder, width: width)
                        .id(nextFolder.identifier)
                        .matchedGeometryEffect(id: nextFolder.identifier,
                                               in: albumViewNameSpace)
                }
                ForEach(0..<albums.count, id: \.self) { index in
                    let album = Album(album: albums[index],
                                      colorIndex: pageFolder.colorIndex + index,
                                      randomNum1: randomNum1,
                                      randomNum2: randomNum2)
                    albumListView(album: album, width: width)
                        .matchedGeometryEffect(id: album.identifier, in: albumViewNameSpace)
                        .id(album.identifier)
                }
            }
            .id(albumEdge)
        }
    }
    
    func fetchSecondaryDepth(folders: [Folder], albums: [Album], width: CGFloat) -> some View {
        HStack(alignment: .bottom) {
            ForEach(folders) { folder in
                folderListView(nextFolder: folder, width: width)
                    .id(folder.identifier)
                    .matchedGeometryEffect(id: folder.identifier, 
                                           in: albumViewNameSpace)
            }
            ForEach(albums) { album in
                albumListView(album: album, width: width)
                    .id(album.identifier)
                    .matchedGeometryEffect(id: album.identifier, 
                                           in: albumViewNameSpace)
            }
        }
            .id(albumEdge)
    }

    func folderListView(nextFolder: Folder, width: CGFloat!) -> some View {
        NavigationLink {
            AlbumView(pageFolder: nextFolder,
                      isPhotosView: $isPhotosView,
                      nameSpace: nameSpace,
                      isShowingSettingView: .constant(false),
                      stateChangeObject: StateChangeObject())
        } label: {
            if uiMode == .fancy {
                FancyCell(cellType: .folder,
                          title: nextFolder.title,
                          countFolder: nextFolder.folderArray.count,
                          countAlbum: nextFolder.albumArray.count,
                          colorIndex: nextFolder.colorIndex,
                          rprstPhoto1: nil,
                          rprstPhoto2: nil,
                          width: width)
            } else if uiMode == .modern {
                ModernCell(cellType: .folder,
                          title: nextFolder.title,
                          countFolder: nextFolder.folderArray.count,
                          countAlbum: nextFolder.albumArray.count,
                          rprstPhoto1: nil,
                          width: width)
            }
        }
        .buttonStyle(ClickScaleEffect())
        .disabled(isEditingMode )
        .contextMenu{ editFolderMenu(folder: nextFolder.folder) }
        .overlay(alignment: .topLeading) {
            Button {
                deleteFolderInSecDepth(folder: nextFolder.folder)
            } label: {
                RemoveButtonLabel(shapeType: .circle)
            }
            .opacity(isEditingMode ? 1:0)
            .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
            .buttonStyle(ClickScaleEffect())
            .offset(x: -5)
        }
    }
    
    func albumListView(album: Album, width: CGFloat!) -> some View {
        NavigationLink {
            AllPhotosView(album: album,
                          title: album.title,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace)
        } label: {
            if uiMode == .fancy {
                FancyCell(cellType: .miniAlbum,
                          title: album.title,
                          colorIndex: album.colorIndex % colorSet.count,
                          rprstPhoto1: album.rprsttivePhoto1,
                          rprstPhoto2: nil,
                          width: width)
            } else if uiMode == .modern {
                ModernCell(cellType: .miniAlbum,
                          title: album.title,
                          rprstPhoto1: album.rprsttivePhoto1,
                          width: width)
            }
        }
        .buttonStyle(ClickScaleEffect())
        .disabled(isEditingMode || stateChangeObject.isShowingMenu)
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
            .offset(x: -5)
        }
    }
}

// edit funcs (1/2) 폴더
extension FancyFolderLineView {
    
    func showingAlert(depth: DepthType, preesed: PressedType, toAdd: CollectionType, edit: EditType, collection: PHCollection) {
        stateChangeObject.isShowingAlert = true
        stateChangeObject.depthType = depth
        stateChangeObject.pressedType = preesed
        stateChangeObject.collectionType = toAdd
        stateChangeObject.editType = edit
        stateChangeObject.collectionToEdit = collection
    }
    func editFolderMenu(folder: PHCollectionList) -> some View {
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
            Button {
                showingSheet(type: .moveCollection, currentFolder: pageFolder, selectedCollection: folder)
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
    
}
// edit funcs (2/2) 앨범
extension FancyFolderLineView {
    
    func editAlbumMenu(album: Album, fIndex: Int! = 0, aIndex: Int! = 0) -> some View {
        VStack {
            Button {
                DispatchQueue.main.async {
                    showingSheet(type: .photosPicker, selectedCollection: album.album)
                }
            } label: {
                let addPhotoIcon = "person.crop.rectangle.badge.plus.fill"
                ContextMenuItem(title: "앨범에 사진 추가하기", image: addPhotoIcon)
            }
            Divider()
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .secondary, preesed: .album, toAdd: .album, edit: .modify, collection: album.album)
                }
            } label: {
                ContextMenuItem(title: "앨범 이름 변경하기", image: "pencil")
            }
            Button {
                DispatchQueue.main.async {
                    showingSheet(type: .moveCollection,
                                 currentFolder: pageFolder,
                                 selectedCollection: album.album)
                }
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
    
    func deleteFolderInSecDepth(folder: PHCollectionList) {
        pageFolder.deleteFolder(folder: folder) { bool in
        }
    }
    func deleteAlbumInSecDepth(album: Album)  {
        album.deleteAlbum() { bool in
        }
    }
    
    func showingSheet(type: SecondarySeetType, 
                      currentFolder: Folder! = nil,
                      selectedCollection: PHCollection! = nil) {
        switch type {
        case .moveCollection:
            isShowingSheet = true
            self.currentFolder = currentFolder
            stateChangeObject.collectionToEdit = selectedCollection
        case .photosPicker:
            self.isShowingPhotosPicker = true
            stateChangeObject.collectionToEdit = selectedCollection
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


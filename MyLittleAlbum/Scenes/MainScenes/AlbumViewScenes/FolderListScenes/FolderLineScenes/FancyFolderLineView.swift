//
//  FancyFolderLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import SwiftUI
import Photos

struct FancyFolderLineView: View {
    @ObservedObject var stateChangeObject: StateChangeObject
    @StateObject var pageFolder: Folder
    
    var randomNum1: Int = 0
    var randomNum2: Int = 0
    var widthOfAlbum: CGFloat? = (min(screenSize.width, screenSize.height) - 35) / 4 - 5
    var heightOfAlbum: CGFloat? = (min(screenSize.width, screenSize.height) - 35) / 4 - 10
    
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    var isEditingMode: Bool
    
    @Namespace private var namespace
    @Namespace private var albumEdge
    @Namespace private var secondaryEdge
    @Binding var currentFolder: Folder!
    @State var navigationOffset: CGFloat = .zero

    @State var secondaryFolder: Folder!
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false, content: {
                if secondaryFolder == nil {
                    Rectangle()
                        .frame(width: 200, height: 90)
                        .padding(.vertical, 5)
                        .padding(.leading, 40)
                        .padding(.trailing, 10)
                        .foregroundColor(.clear)
                        .onAppear(perform: {
                            DispatchQueue.main.async {
                                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
                                    secondaryFolder = pageFolder
                                }
                            }
                        })
                } else {
                    fetchSecondaryDepth(pageFolder: secondaryFolder)
                        .transition(.slide.combined(with: .opacity))
                        .padding(.vertical, 5)
                        .padding(.leading, 40)
                        .padding(.trailing, 10)
                        .id(secondaryEdge)
                        .onChange(of: pageFolder.countFolder) { [oldValue = pageFolder.countFolder] newValue in
                            if oldValue < newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.interactiveSpring()) {
                                        proxy.scrollTo(pageFolder.folderArray[oldValue].localIdentifier, anchor: .trailing)
                                    }
                                }
                            }
                        }
                        .onChange(of: pageFolder.countAlbum) { [oldValue = pageFolder.countAlbum] newValue in
                            if oldValue < newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.interactiveSpring()) {
                                        proxy.scrollTo(secondaryEdge, anchor: .trailing)
                                    }
                                }
                            }
                        }
                }
            })
            .padding(.leading, 30)
        }
//        .onChange(of: scenePhase) { newValue in
//            if newValue == .background {
//                print("MyLittleAlbum is in Background Status")
//                self.secondaryFolder = nil
//            }
//            if newValue == .active {
//                print("MyLittleAlbum is in Active Status")
//                DispatchQueue.main.async {
//                    withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.1)) {
//                        secondaryFolder = pageFolder
//                    }
//                }
//            }
//        }
    }
}

// load photodata
extension FancyFolderLineView {
    func fetchSecondaryDepth(pageFolder: Folder, width: CGFloat? = 100) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            let folders = pageFolder.folderArray
            let albums = pageFolder.albumArray
            HStack {
                ForEach(0..<folders.count, id: \.self) { index in
                    let nextFolder = Folder(folder: folders[index],
                                            colorIndex: pageFolder.colorIndex + 4 * (index + 1))
                    folderListView(nextFolder: nextFolder, width: width)
                        .id(nextFolder.identifier)
                        .matchedGeometryEffect(id: nextFolder.identifier, in: namespace)
                }
                ForEach(0..<albums.count, id: \.self) { index in
                    let album = Album(album: albums[index],
                                      colorIndex: pageFolder.colorIndex + index,
                                      randomNum1: randomNum1,
                                      randomNum2: randomNum2)
                    albumListView(album: album, width: width)
                        .matchedGeometryEffect(id: album.identifier, in: namespace)
                        .id(album.identifier)
                }
            }
            .id(albumEdge)
        }
    }

    func folderListView(nextFolder: Folder, width: CGFloat!) -> some View {
        NavigationLink {
            AlbumView(stateChangeObject: StateChangeObject(),
                      pageFolder: nextFolder,
                      isShowingSettingView: .constant(false))
        } label: {
            FancyCell(cellType: .folder,
                      title: nextFolder.title,
                      countOfFolder: nextFolder.folderArray.count,
                      countOfAlbum: nextFolder.albumArray.count,
                      colorIndex: nextFolder.colorIndex,
                      rprstPhoto1: nil,
                      rprstPhoto2: nil,
                      width: width)
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
            AllPhotosView(album: album, title: album.title)
        } label: {
            FancyCell(cellType: .miniAlbum,
                      title: album.title,
                      colorIndex: album.colorIndex % colorSet.count,
                      rprstPhoto1: album.rprsttivePhoto1,
                      rprstPhoto2: nil,
                      width: width)
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
    
    func showingAlert(depth: DepthType, preesed: PressedType, toAdd: CollectionType, edit: EditType, collection: PHCollection) {
        stateChangeObject.isShowingAlert = true
        stateChangeObject.depthType = depth
        stateChangeObject.pressedType = preesed
        stateChangeObject.collectionType = toAdd
        stateChangeObject.editType = edit
        stateChangeObject.collectionToEdit = collection
    }
}

// edit funcs (1/2) 폴더
extension FancyFolderLineView {
    
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
            Divider()
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
            Divider()
            Button {
                DispatchQueue.main.async {
                    showingSheet(type: .moveCollection, currentFolder: pageFolder, selectedCollection: album.album)
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

enum SecondarySeetType {
    case moveCollection, photosPicker
}

struct FancyFolderLineView_Previews: PreviewProvider {
    static var previews: some View {
        FancyFolderLineView(stateChangeObject: StateChangeObject(), pageFolder: Folder(isHome: true), isShowingSheet: .constant(false), isShowingPhotosPicker: .constant(false), isEditingMode: false, currentFolder: .constant(Folder(isHome: true)))
    }
}


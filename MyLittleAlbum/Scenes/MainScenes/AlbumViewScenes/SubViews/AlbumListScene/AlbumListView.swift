//
//  AlbumListView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/11/23.
//

import SwiftUI
import Photos
//import PhotosUI


struct AlbumListView: View {
    // 앨범 추가됐는지 확인용 프라퍼티
    @ObservedObject var stateChangeObject: StateChangeObject
    // 현재 앨범들이 속한 폴더
    @ObservedObject var pageFolder: Folder
    // 레이아웃
    let uiMode: UIMode
    let widthOfAlbum: CGFloat
    let randomNum1: Int
    let randomNum2: Int
    @State var firstAppear: Bool = true
    // 보여주기 ui 스위칭 프라퍼티
    @State var modeOfAlbumList: Bool = false
    @State var spacing: CGFloat = 10.0
    // 화면 전환용 프라퍼티
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    var isEditingMode: Bool
    // namespace
    var nameSpace: Namespace.ID
    var albumViewNameSpace: Namespace.ID
    // 앨범 / 폴더 위치 이동 시 현재 폴더 나타내기용 프라퍼티
    @Binding var currentFolder: Folder!
    @Binding var isPhotosView: Bool
    
    var body: some View {
        let albumList = albumList(pageFolder: pageFolder,
                                  widthOfAlbum: widthOfAlbum)
        VStack(spacing: 0) {
            SectionView(sectionType: .album,
                        uiMode: uiMode,
                        collectionCount: pageFolder.countAlbum,
                        viewMode: $modeOfAlbumList)
            albumListView(view: albumList,
                          mode: modeOfAlbumList,
                          widthOfAlbum: widthOfAlbum)
            .onAppear(perform: {
                albumViewModeChange(isFirstAppear: firstAppear)
            })
        }
    }
}

extension AlbumListView {
    // 앨범 리스트 레이아웃 by modeOfAlbumList
    @ViewBuilder
    func albumListView(view: some View, mode: Bool, widthOfAlbum: CGFloat) -> some View {
        let spacing = (screenWidth - 5.0 - (CGFloat(listCount) * widthOfAlbum)) / CGFloat(listCount)
        let column = Array(
            repeating: GridItem(spacing: !mode ? 10 : spacing),
            count: mode ? listCount : pageFolder.countAlbum)
        ScrollViewReader(content: { proxy in
            ScrollView(.horizontal, showsIndicators: false, content: {
                LazyVGrid(columns: column)  {
                    view
                }
                .transition(.scale(scale: 1, anchor: .topTrailing))
                .id("albumViewEdge")
                .padding([.leading, .vertical], 10)
                .padding(.trailing, 5)
                
            })
            .scrollDisabled(mode)
            .onChange(of: pageFolder.albumArray.count) { 
                [oldValue = pageFolder.albumArray.count] newValue in
                if oldValue < newValue && !mode {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.interactiveSpring()) {
                            proxy.scrollTo("albumViewEdge", anchor: .trailing)
                        }
                    }
                }
            }
        })
    }
    
    func albumList(pageFolder: Folder, widthOfAlbum: CGFloat) -> some View {
        return ForEach(pageFolder.albumArray, id: \.self) { phAssetCollection in
            let index = pageFolder.albumArray.firstIndex(of: phAssetCollection)!
            let album = Album(album: phAssetCollection,
                              colorIndex: pageFolder.colorIndex + index,
                              randomNum1: randomNum1,
                              randomNum2: randomNum2)
            viewForEach(album: album, widthOfAlbum: widthOfAlbum)
                .matchedGeometryEffect(id: album.identifier,
                                       in: albumViewNameSpace)
                .buttonStyle(ClickScaleEffect())
        }
    }
    
    func viewForEach(album: Album, widthOfAlbum: CGFloat) -> some View {
        NavigationLink {
            AllPhotosView(album: album,
                          title: album.title,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace)
        } label: {
            switch uiMode {
            case .classic:
                ClassicCell(cellType: .album,
                            title: album.title,
                            rprstPhoto1: album.rprsttivePhoto1,
                            width: widthOfAlbum)
            case .fancy:
                FancyCell(cellType: .album,
                          title: album.title,
                          colorIndex: album.colorIndex % colorSet.count,
                          rprstPhoto1: album.rprsttivePhoto1,
                          rprstPhoto2: album.rprsttivePhoto2,
                          width: widthOfAlbum)
            case .modern:
                ModernCell(cellType: .album,
                          title: album.title,
                          rprstPhoto1: album.rprsttivePhoto1,
                          width: widthOfAlbum)
            }
        }
        .disabled(isEditingMode || stateChangeObject.isShowingMenu)
        .contextMenu {
            if !stateChangeObject.isEditingMode { editAlumbMenu(album: album) }
        }
        .overlay(alignment: .topLeading) {
            Button {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    deleteAlbumInDepth(album: album)
                }
            } label: {
                RemoveButtonLabel(shapeType: .rectangle)
            }
            .opacity(isEditingMode ? 1:0)
            .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
            .offset(CGSize(width: uiMode == .classic ? -2:0, height: uiMode == .classic ? -2:0))
        }
    }
}

// contexMenu funcs
extension AlbumListView {
    func albumViewModeChange(isFirstAppear: Bool) {
        if firstAppear {
            DispatchQueue.main.async {
                withAnimation {
                    modeOfAlbumList
                    = pageFolder.folderArray.count == 0
                    && pageFolder.albumArray.count > listCount
                }
            }
        }
        firstAppear = false
    }
    
    func editAlumbMenu(album: Album) -> some View {
        VStack {
            Button {
                showingSheet(sheetType: .photosPicker, collection: album)
            } label: {
                let addPhotoIcon = "person.crop.rectangle.badge.plus.fill"
                ContextMenuItem(title: "앨범에 사진 추가하기", image: addPhotoIcon)
            }
            Divider()
            Button {
                showingAlert(depth: .current, preesed: .album, toAdd: .album, edit: .modify, collection: album.album)
            } label: {
                ContextMenuItem(title: "앨범 이름 변경하기", image: "pencil")
            }
            Divider()
            Button {
                showingSheet(sheetType: .moveCollection, folder: pageFolder, collection: album)
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                deleteAlbumInDepth(album: album)
            } label: {
                ContextMenuItem(title: "이 앨범 삭제하기", image: "trash")
            }
        }
    }
    
    func deleteAlbumInDepth(album: Album) {
        DispatchQueue.main.async {
            album.deleteAlbum() { bool in
            }
        }
    }
    func showingSheet(sheetType: SheetType, folder: Folder! = nil, collection: Album) {
        if sheetType == .moveCollection {
            self.isShowingSheet = true
            self.currentFolder = folder
            DispatchQueue.main.async {
                stateChangeObject.collectionToEdit = collection.album
            }
        } else if sheetType == .photosPicker {
            stateChangeObject.collectionToEdit = collection.album
            DispatchQueue.main.async {
                self.isShowingPhotosPicker = true
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
    
}


struct AlbumListView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView(pageFolder: Folder(isHome: true),
                  isPhotosView: .constant(false),
                  nameSpace: Namespace().wrappedValue,
                  isShowingSettingView: .constant(false),
                  stateChangeObject: StateChangeObject())
            .environmentObject(PhotoData())
    }
}

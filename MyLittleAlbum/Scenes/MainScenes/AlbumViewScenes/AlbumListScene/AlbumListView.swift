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
    let randomNum1: Int
    let randomNum2: Int
    let widthOfAlbum: CGFloat? = (min(screenSize.width, screenSize.height) - 35) / 3 - 5
    let heightOfAlbum: CGFloat? = (min(screenSize.width, screenSize.height) - 35) / 3 - 5
    // 보여주기 ui 스위칭 프라퍼티
    @State var modeOfAlbumList: Bool
    // 화면 전환용 프라퍼티
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    var isEditingMode: Bool
    // namespace
    @Namespace var albumViewEdge
    @Namespace var namespace
    // 앨범 / 폴더 위치 이동 시 현재 폴더 나타내기용 프라퍼티
    @Binding var currentFolder: Folder!

    var body: some View {
        VStack(spacing: 0) {
            let albumList = albumList(pageFolder: pageFolder)
            sectionView(countAlbum: pageFolder.countAlbum, mode: modeOfAlbumList)
            albumListView(view: albumList, mode: modeOfAlbumList, widthOfAlbum: widthOfAlbum ?? 0)
                .buttonStyle(ClickScaleEffect())
        }
    }
}

extension AlbumListView {
    // 섹션 뷰
    func sectionView(countAlbum: Int, mode: Bool) -> some View{
        let changeLabel = mode ? "한줄 보기" : "펼쳐 보기"
        return HStack(alignment: .bottom) {
            SectionView(sectionType: .album, uiMode: uiMode, collectionCount: countAlbum)
                .zIndex(1)
            if countAlbum > 3 {
                titleText(changeLabel, font: .footnote, color: .gray)
            }
        }
        .padding(.horizontal, 10)
        .onTapGesture {
            DispatchQueue.global(qos: .userInteractive).async {
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
                    self.modeOfAlbumList.toggle()
                }
            }
        }
    }
    
    
    
    
    
    // 앨범 리스트 레이아웃 by modeOfAlbumList
    @ViewBuilder
    func albumListView(view: some View, mode: Bool, widthOfAlbum: CGFloat) -> some View {
//    func albumListView(view: some View, count: Int, mode: Bool, widthOfAlbum: CGFloat) -> some View {
        let modeOfAlbumList = mode
        let columnOrRow = Array(repeating: GridItem(.flexible(), alignment: .leading),
                                count: mode ? Int(screenSize.width / (widthOfAlbum + 10)) : 1)
        
        if modeOfAlbumList {
            LazyVGrid(columns: columnOrRow, alignment: .center, spacing: 10) {
                view
            }
            .id(albumViewEdge)
            .padding([.leading, .vertical], 10)
            .padding(.trailing, 5)
        } else {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: columnOrRow, alignment: .center, spacing: 4) {
                        HStack {
                            view
                        }
                    }
                    .padding(.all, 10)
                    .id(albumViewEdge)
                    .onChange(of: pageFolder.albumArray.count) { [oldValue = pageFolder.albumArray.count] newValue in
                        if oldValue < newValue && !modeOfAlbumList {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.interactiveSpring()) {
                                    proxy.scrollTo(albumViewEdge, anchor: .trailing)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
//    func albumList(albums: [PHAssetCollection], colorIndex: Int, editingMode: Bool, randomNum1: Int, randomNum2: Int) -> some View {
    func albumList(pageFolder: Folder) -> some View {
        return ForEach(pageFolder.albumArray, id: \.self) { phAssetCollection in
            let index = pageFolder.albumArray.firstIndex(of: phAssetCollection)!
            let album = Album(album: phAssetCollection,
                              colorIndex: pageFolder.colorIndex + index,
                              randomNum1: randomNum1,
                              randomNum2: randomNum2)
            viewForEach(album: album)
                .matchedGeometryEffect(id: album.identifier, in: namespace)
                .id(album.identifier)
        }
        
    }
    
    func deleteAlbumInDepth(album: Album) {
        DispatchQueue.main.async {
            album.deleteAlbum() { bool in
            }
        }
    }

    func viewForEach(album: Album) -> some View {
        NavigationLink {
            AllPhotosView(album: album, title: album.title)
        } label: {
            switch uiMode {
            case .classic:
                ClassicCell(cellType: .album,
                            title: album.title,
                            rprstPhoto1: album.rprsttivePhoto1,
                            width: widthOfAlbum,
                            height: heightOfAlbum)
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
        .buttonStyle(ClickScaleEffect())
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
            .buttonStyle(ClickScaleEffect())
            .offset(CGSize(width: uiMode == .classic ? -2:0, height: uiMode == .classic ? -2:0))
        }
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
    
}


// contexMenu funcs
extension AlbumListView {
    
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
    
//    func deleteAlbumInDepth(album: Album) {
//        DispatchQueue.main.async {
//            album.deleteAlbum() { bool in
//            }
//        }
//    }
    
    
}


//struct AlbumListView_Previews: PreviewProvider {
//    static var previews: some View {
//        AlbumListView(modeOfAlbumList: .constant(false), isShowingAlert: .constant(false), isShowingMenu: .constant(false), pressedPhotosPicker: .constant(false), draggedItem: .constant(nil), depthType: .constant(.none), pressedType: .constant(.none), collectionType: .constant(.none), editType: .constant(.none), collectionToEdit: .constant(nil), isAlbumAdded: .constant(false))
//            .background(Color.fancyBackground)
//    }
//}

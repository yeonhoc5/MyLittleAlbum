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
    // 현재 앨범들이 속한 폴더
//    let phCollectionList: PHCollectionList!
    @ObservedObject var pageFolder: MLFolder
    let isHome: Bool
    // 레이아웃
    let pageIndex: Int
    let screenWidth: CGFloat
    let widthOfAlbum: CGFloat
    @State var firstAppear: Bool = true
    // 보여주기 ui 스위칭 프라퍼티
    @State var isUnfolded: Bool = false
    @State var processingCollection: PHAssetCollection!
    var isEditingMode: Bool
    // namespace
    var nameSpace: Namespace.ID
    var albumViewNameSpace: Namespace.ID
    // (i패드용) 탭바 위치 잡기용 프라퍼티
    @Binding var isPhotosView: Int
    
    var body: some View {
        let albumListView = albumListView(widthOfAlbum: widthOfAlbum)
        VStack(spacing: 0) {
            SectionView(sectionType: .album,
                        uiMode: photoData.uiMode,
                        collectionCount: pageFolder.albumsArray.count,
                        isUnfolded: $isUnfolded)
                        .zIndex(1.0)
            albumListLayout(pageFolder: pageFolder,
                            view: albumListView,
                            mode: isUnfolded,
                            widthOfAlbum: widthOfAlbum)
            .onAppear(perform: {
                albumViewModeChange(isFirstAppear: firstAppear,
                                    pageFolder: pageFolder)
            })
        }
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
        return ForEach(pageFolder.albumsArray, id: \.self) { assetCollection in
            let index = pageFolder.albumsArray.firstIndex(of: assetCollection) ?? 0
            viewForEach(assetCollection: assetCollection,
                        widthOfAlbum: widthOfAlbum,
                        index: pageIndex + index)
                .buttonStyle(ClickScaleEffect())
                .transition(.scale)
                .contextMenu {
                    editAlbumMenu(assetCollection: assetCollection, index: index)
                }
        }
        .animation(.easeInOut, value: !pageFolder.albumsArray.isEmpty)
    }
    // 앨범 리스트 레이아웃 by modeOfAlbumList
    @ViewBuilder
    func albumListLayout(pageFolder: MLFolder, view: some View,
                         mode: Bool, widthOfAlbum: CGFloat) -> some View {
        let spacing = (self.screenWidth - 5.0 - (CGFloat(listCount) * widthOfAlbum)) / CGFloat(listCount)
        let column = Array(
            repeating: GridItem(.fixed(widthOfAlbum),
                                spacing: !mode ? 10 : spacing),
            count: mode ? listCount : pageFolder.albumsArray.count
        )
        ScrollViewReader(content: { proxy in
            ScrollView(.horizontal, showsIndicators: false, content: {
                LazyVGrid(columns: column)  {
                    view
                }
                .padding(.all, 10)
                .onChange(of: pageFolder.albumsArray.count) { [oldValue = pageFolder.albumsArray.count] newValue in
                    if newValue > oldValue && oldValue != 0 {
                        withAnimation {
                            proxy
                                .scrollTo(pageFolder.albumsArray.last?.localIdentifier)
                        }
                    }
                }
            })
            .scrollDisabled(mode)
        })
    }
    
    @ViewBuilder
    func viewForEach(assetCollection: PHAssetCollection,
                     widthOfAlbum: CGFloat,
                     index: Int) -> some View {
        NavigationLink {
            AllPhotosView(assetCollection: assetCollection,
                          isHiddenAsset: false,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace)
        } label: {
            CellView(uiMode: photoData.uiMode,
                     cellType: .album,
                     index: index,
                     width: widthOfAlbum) { size, cellNameSpace in
                Group {
                    if let album = photoData.albums[assetCollection.localIdentifier] {
                        AlbumCoverView(album: album,
                                       assetCollection: assetCollection,
                                       uiMode: photoData.uiMode,
                                       cellType: .album,
                                       size: size,
                                       colorIndex: index,
                                       albumCell: cellNameSpace,
                                       isEditingMode: isEditingMode)
                        .matchedGeometryEffect(id: assetCollection.localIdentifier,
                                               in: nameSpace)
                    } else {
                        TempCoverView(title: assetCollection.localizedTitle ?? "Loading...",
                                      nameSpace: cellNameSpace,
                                      size: size,
                                      cellType: .album)
                    }
                }
            }
        }
        .disabled(isEditingMode)
        .overlay(alignment: .topLeading) {
            btnDelete(album: assetCollection)
                .offset(x: -1, y: -1)
        }
        .id(assetCollection.localIdentifier)
    }
    
    func btnDelete(album: PHAssetCollection) -> some View {
        Button {
            dispatchAnimation {
                processingCollection = album
            }
            deleteAlbumInDepth(assetCollection: album)
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
}

// contexMenu funcs
extension AlbumListView {
    func albumViewModeChange(isFirstAppear: Bool, pageFolder: MLFolder?) {
        guard let pageFolder = pageFolder else { return }
        if firstAppear {
            dispatchAnimation {
                isUnfolded = pageFolder.foldersArray.isEmpty
                            && pageFolder.albumsArray.count > listCount
            }
        }
        firstAppear = false
    }
    
    func editAlbumMenu(assetCollection: PHAssetCollection, index: Int) -> some View {
        VStack {
            Button {
                let object = PickerObject(editToAlbum: assetCollection.localIdentifier,
                                          imageManager: PHCachingImageManager())
                DispatchQueue.main.async {
                    NotificationCenter.default
                        .post(name: .showPhotosPicker, object: object)
                }
            } label: {
                let addPhotoIcon = "person.crop.rectangle.badge.plus.fill"
                ContextMenuItem(title: "앨범에 미디어 추가하기",
                                image: addPhotoIcon)
            }
            Divider()
            Button {
                guard let album = photoData.albums[assetCollection.localIdentifier] else { return }
                let alertObject = AlertObject(
                    alertCase: .albumNameChange,
                    album: album.phAssetCollection,
                    folder: nil,
                    needsTextField: true)
                NotificationCenter.default
                    .post(name: .showAlert, object: alertObject)
            } label: {
                ContextMenuItem(title: "앨범 이름 변경하기", image: "pencil")
            }
            Button {
                let moveObject = MoveCollectionObject(
                    currentParent: pageFolder,
                    objectCellType: .album,
                    objectFolder: nil,
                    objectAlbum: assetCollection,
                    objectColorIndex: index,
                    objectIdentifier: assetCollection.localIdentifier,
                    nameSpace: nameSpace)
                NotificationCenter.default
                    .post(name: .showMoveCollectionSheet, object: moveObject)
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                deleteAlbumInDepth(assetCollection: assetCollection)
            } label: {
                ContextMenuItem(title: "이 앨범 삭제하기", image: "trash")
            }
        }
    }
    
    func deleteAlbumInDepth(assetCollection: PHAssetCollection) {
        pageFolder.deleteAlbum(album: assetCollection) { _ in
            dispatchAnimation {
                photoData.removeAlbumValue(album: assetCollection) { 
                    processingCollection = nil
                    NotificationCenter.default
                        .post(name: .outsideFetchChange, object: "myPhotos")
                }
            }
        }
    }
}


struct AlbumListView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView(pageFolder: MLFolder(collectionList: nil),
                  phCollectionList: nil,
                  pageIndex: 0,
                  isPhotosView: .constant(0),
                  nameSpace: Namespace().wrappedValue,
                  isShowingSettingView: .constant(false))
            .environmentObject(MLPhotoData())
    }
}

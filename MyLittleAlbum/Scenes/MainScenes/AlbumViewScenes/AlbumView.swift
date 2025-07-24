//
//  AlbumView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
//import PhotosUI

// 앨범 뷰
struct AlbumView: View {
    // 사진 데이터 프라퍼티
    @EnvironmentObject var photoData: MLPhotoData
    @Environment(\.dismiss) var dismiss
    let phCollectionList: PHCollectionList!
    // UI 프라퍼티
    var pageIndex: Int = 0
    @State var isPortrait: Bool = true
    @Binding var isPhotosView: Int
    // 애니메이션 프라퍼티
    var nameSpace: Namespace.ID
    @Namespace var albumViewNameSpace
    @Namespace var folderViewInScroll
    @Namespace var albumViewInScroll
    @State var scrollToEdge: EdgeToScroll = .none
    // 추가 뷰 프라퍼티
    @Binding var isShowingSettingView: Bool
    // 수정용 프라퍼티
    // 수정 모드 프라퍼티
    @State var isEditingMode: Bool = false
    // 앨범 밖에서 사진 추가용 프라퍼티
    @State var selectedItems: [Int] = []
    // 제스처로 팝오프용 프라퍼티
    @Environment(\.presentationMode) var isPresented: Binding<PresentationMode>
    
    @State var isHome: Bool = false
    
    var body: some View {
        GeometryReader(content: { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    Group {
                        let pageFolder = photoData.folders[phCollectionList?.localIdentifier ?? "topFolder"] ?? MLFolder(collectionList: phCollectionList)
                            VStack(alignment: .leading, spacing: 0) {
                                let widthOfAlbum = (geometry.size.width - (10 * CGFloat(listCount + 2))) / CGFloat(listCount)
                                let secondaryWidth = (geometry.size.width - 20 - CGFloat(listCount * 10)) / CGFloat(listCount + 1)
                                AlbumListView(
                                    phCollectionList: phCollectionList,
                                    pageIndex: pageIndex,
                                    widthOfAlbum: widthOfAlbum,
                                    isEditingMode: isEditingMode,
                                    nameSpace: nameSpace,
                                    albumViewNameSpace: albumViewNameSpace,
                                    isPhotosView: $isPhotosView)
                                ZStack(alignment: .top) {
                                    // album 추가시 스크롤을 위한 임시 뷰
                                    scrollHelperView(id: "albumScrollItem",
                                                     height: tabbarHeight)
                                    FolderListView(
                                        phCollectionList: phCollectionList,
                                        pageIndex: pageIndex,
                                        screenWidth: geometry.size.width,
                                        secondaryWidth: secondaryWidth,
                                        isEditingMode: isEditingMode,
                                        nameSpace: nameSpace,
                                        albumViewNameSpace: albumViewNameSpace,
                                        isPhotosView: $isPhotosView)
                                        .id(folderViewInScroll)
                                }
                                // folder 추가시 스크롤을 위한 임시 뷰
                                scrollHelperView(id: "FolderScrollItem",
                                                 height: tabbarHeight
                                                 + tabbarTopPadding
                                                 + tabbarBottomPadding)
                            }
                            .onReceive(NotificationCenter.default
                                .publisher(for: .scrollToItem)) { output in
                                    if let scrollObject = output.object as? ScrollItem {
                                        phDataQueue.async {
                                            scrollCheck(pageFolder: pageFolder,
                                                        proxy: proxy,
                                                        identifier: scrollObject.identifier)
                                        }
                                    }
                                }
                    }
                }
//                .onTapGesture {
//                    stateChangeObject.isShowingMenu = false
//                }
//                .simultaneousGesture(popOffCurrentPage)
                .disabled(isShowingSettingView)
            }
            .overlay {
                Rectangle()
                    .foregroundStyle(Color.black)
                    .opacity(isShowingSettingView ? 0.5 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            // 아이패드에서 외부 터치 시 저장없이 닫기
                            isShowingSettingView = false
                        }
                    }
            }
            SettingView(isShowingSettingView: $isShowingSettingView)
                .frame(width: device == .phone
                       ? geometry.size.width : 400)
                .position(x: isShowingSettingView
                          ? (device == .phone
                            ? (geometry.size.width / 2) : 220)
                          : (device == .phone
                               ? (-geometry.size.width)
                               : (-geometry.size.width + 200)),
                          y: geometry.size.height / 2)
                .animation(isShowingSettingView
                           ? .linear.delay(0.15) : .linear,
                           value: isShowingSettingView)
        })
        .colorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(navigationTitle())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                rightToolBarItems
                    .opacity(isShowingSettingView ? 0 : 1)
                    .offset(y: isShowingSettingView ? -100 : 0)
            }
            if isHome {
                ToolbarItem(placement: .navigationBarLeading) {
                    leftHomeToolBarItem
                }
            }
            if !isHome && navigationTitle() == "(No Title)" {
                ToolbarItem(placement: .principal) {
                    Text("(No Title)")
                        .foregroundStyle(.gray )
                }
            }
        }
        .foregroundColor(.secondary)
        .background { FancyBackground() }
        .edgesIgnoringSafeArea(.trailing)
        .onReceive(NotificationCenter.default
            .publisher(for: .collectionInserted), perform: { object in
            if let folder = object.object as? PHCollectionList {
                let mlFolder = MLFolder(collectionList: folder)
                DispatchQueue.main.async {
                    photoData.folders
                        .updateValue(mlFolder, forKey: mlFolder.id)
                }
            } else if let album = object.object as? PHAssetCollection {
                let mlAlbum = MLAlbum(assetCollection: album)
                DispatchQueue.main.async {
                    photoData.albums
                        .updateValue(mlAlbum, forKey: mlAlbum.id)
                }
            }
        })
        .onReceive(NotificationCenter.default
            .publisher(for: .collectionRemoved), perform: { object in
            if let folder = object.object as? PHCollectionList {
                photoData
                    .checkRemoveCollection(type: .folder,
                                           folder: folder.localIdentifier) { bool in
                    if bool {
                        print("ok \(folder.localizedTitle ?? "(No Title)") is Removed")
                    } else {
                        print("oh \(folder.localizedTitle ?? "(No Title)") is Moved")
                    }
                }
            } else if let album = object.object as? PHAssetCollection {
                photoData
                    .checkRemoveCollection(type: .album,
                                           album: album.localIdentifier) { bool in
                    if bool {
                        print("ok \(album.localizedTitle ?? "(No Title)") is Removed")
                    } else {
                        print("oh \(album.localizedTitle ?? "(No Title)") is Moved")
                    }
                }
            }
        })
    }
    
    func navigationTitle() -> String {
        if let folder = photoData.folders[phCollectionList?.localIdentifier ?? "topFolder"] {
            return folder.title != "" ? folder.title : "(No Title)"
        } else {
            return "마이 리틀 앨범"
        }
    }
}

// MARK: - functions
extension AlbumView {
    var popOffCurrentPage: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onEnded({ value in
                if phCollectionList != nil {
                    if value.translation.width > 50 {
                        isPresented.wrappedValue.dismiss()
                    }
                }
            })
    }
    
    func scrollHelperView(id: String, height: CGFloat) -> some View {
        Rectangle()
            .foregroundStyle(Color.fancyBackground)
            .frame(height: height)
            .id(id)
    }
}

// MARK: - [툴바] 아이템 / context 메뉴
extension AlbumView {
    // Trailing 툴바 아이텝 (2개)
    @ViewBuilder
    var rightToolBarItems: some View {
        let iconWidth: CGFloat = 45
        Group {
            if isEditingMode {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isEditingMode = false
                    }
                } label: {
                    ZStack {
                        Rectangle().foregroundColor(.clear)
                        Text("Done")
                    }
                }
                .frame(width: iconWidth, height: 20, alignment: .center)
                .buttonStyle(ClickScaleEffect())
            } else {
                Menu {
                    contextMenu
                } label: {
                    ZStack {
                        Rectangle().foregroundColor(.clear)
                        imageWithScale(
                            systemName: iconFolderSetting,
                            scale: .large)
                    }
                }
                .menuStyle(.borderlessButton)
                .frame(width: iconWidth, height: 20, alignment: .center)
            }
        }
        .foregroundStyle(.gray)
    }
    // Leading 툴바 아이텝 (1개) - Home에서만 출현
    var leftHomeToolBarItem: some View {
        Button {
            DispatchQueue.main.async {
                withAnimation {
                    isShowingSettingView.toggle()
                }
            }
        } label: {
            ZStack {
                Rectangle().foregroundStyle(Color.fancyBackground)
                imageWithScale(systemName: iconSetting, scale: .large)
                    .foregroundStyle(.gray)
                    .rotationEffect(
                        .degrees(isShowingSettingView ? -180 : 0)
                    )
                Rectangle().foregroundColor(.clear)
            }
        }
        .buttonStyle(ClickScaleEffect())
    }
    // 툴바 아이템 (Trailing) - contextMenu
    var contextMenu: some View {
        let albumIcon = "rectangle.stack.fill.badge.plus"
        let folderIcon = "folder.fill.badge.plus"
        let deleteModeIcon = "pencil"
        return VStack {
            Button {
                let alertObject = AlertObject(
                    alertCase: .addAlbumToFolder,
                    album: nil,
                    folder: phCollectionList,
                    needsTextField: true)
                NotificationCenter.default
                    .post(name: .showAlert, object: alertObject)
            } label: {
                ContextMenuItem(title: "앨범 추가하기",
                                image: albumIcon)
            }
            Button {
                let alertObject = AlertObject(
                    alertCase: .addFolderToFolder,
                    album: nil,
                    folder: phCollectionList,
                    needsTextField: true)
                NotificationCenter.default
                    .post(name: .showAlert, object: alertObject)
            } label: {
                ContextMenuItem(title: "폴더 추가하기",
                                image: folderIcon)
            }
            Divider()
            Button {
                withAnimation {
                    isEditingMode = true
                }
            } label: {
                ContextMenuItem(title: "폴더 / 앨범 지우기 모드",
                                image: deleteModeIcon)
            }
            Divider()
            Button {
                let reorderObject = ReorderObject(
                    localIdentifier: phCollectionList?.localIdentifier ?? "topFolder")
                NotificationCenter.default
                    .post(name: .showReorderSheet,
                          object: reorderObject)
            } label: {
                ContextMenuItem(title: "리스트 순서 조정하기",
                                image: "arrow.up.arrow.down")
            }
        }
    }
    func scrollCheck(pageFolder: MLFolder, proxy: ScrollViewProxy, identifier: String) {
        if pageFolder.albumsArray
            .compactMap({ $0.localIdentifier })
            .contains(identifier) {
                withAnimation {
                    proxy
                        .scrollTo("albumScrollItem",
                                  anchor: .bottom)
                }
        } else if pageFolder.foldersArray
            .compactMap({ $0.localIdentifier })
            .contains(identifier) {
                withAnimation {
                    proxy
                        .scrollTo("FolderScrollItem",
                                  anchor: .bottom)
                }
            
        }
    }
}

// MARK: - [Funcs] 앨범 추가 / 수정 Alert
extension AlbumView {
    enum ObjectType {
        case menu, editingMode
    }
}

struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView(phCollectionList: nil,
                  pageIndex: 0,
                  isPhotosView: .constant(0),
                  nameSpace: Namespace().wrappedValue,
                  isShowingSettingView: .constant(false))
            .environmentObject(MLPhotoData())
    }
}


struct ScrollObject: Equatable {
    let id: String
}

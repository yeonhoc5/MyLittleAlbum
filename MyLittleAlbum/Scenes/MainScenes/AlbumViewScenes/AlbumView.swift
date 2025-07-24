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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var photoData: MLPhotoData
    @ObservedObject var pageFolder: MLFolder
    let phCollectionList: PHCollectionList!
    // UI 프라퍼티
    var pageIndex: Int = 0
    @Binding var isPhotosView: Int
    // 애니메이션 프라퍼티
    var nameSpace: Namespace.ID
    @Namespace var albumViewNameSpace
    @State var scrollToEdge: EdgeToScroll = .none
    // 추가 뷰 프라퍼티
    @Binding var isShowingSettingView: Bool
    // 수정용 프라퍼티
    // 수정 모드 프라퍼티
    @State var isEditingMode: Bool = false
    // 앨범 밖에서 사진 추가용 프라퍼티
    @State var selectedItems: [Int] = []
    
    var body: some View {
        GeometryReader(content: { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    Group {
                        let widthOfAlbum = (geometry.size.width - (10 * CGFloat(listCount + 2))) / CGFloat(listCount)
                        let secondaryWidth = (geometry.size.width - 20 - CGFloat(listCount * 10)) / CGFloat(listCount + 1)
                        VStack(alignment: .leading, spacing: 0) {
                            AlbumListView(
                                pageFolder: pageFolder,
                                isHome: phCollectionList == nil,
                                pageIndex: pageIndex,
                                screenWidth: geometry.size.width,
                                widthOfAlbum: widthOfAlbum,
                                isEditingMode: isEditingMode,
                                nameSpace: nameSpace,
                                albumViewNameSpace: albumViewNameSpace,
                                isPhotosView: $isPhotosView)
                            .id("albumScrollItem")
                            FolderListView(
                                pageFolder: pageFolder,
                                isHome: phCollectionList == nil,
                                pageIndex: pageIndex,
                                screenWidth: geometry.size.width,
                                secondaryWidth: secondaryWidth,
                                isEditingMode: isEditingMode,
                                nameSpace: nameSpace,
                                albumViewNameSpace: albumViewNameSpace,
                                scrollProxy: proxy,
                                isPhotosView: $isPhotosView)
                            // folder 추가시 스크롤을 위한 임시 뷰
                            scrollHelperView(id: "FolderScrollItem",
                                             height: tabbarHeight
                                             + tabbarTopPadding
                                             + tabbarBottomPadding)
                        }
                        .onChange(of: pageFolder.albumsArray.count,
                                  perform: { [oldValue = pageFolder.albumsArray.count] newValue in
                            if newValue > oldValue {
                                withAnimation {
                                    proxy.scrollTo("albumScrollItem")
                                }
                            }
                        })
                        .onChange(of: pageFolder.foldersArray.count,
                                  perform: { [oldValue = pageFolder.foldersArray.count] newValue in
                            if newValue > oldValue && oldValue != 0 {
                                withAnimation {
                                    proxy.scrollTo("FolderScrollItem")
                                }
                            }
                        })
                    }
                }
                .disabled(isShowingSettingView)
            }
            .overlay {
                Rectangle()
                    .foregroundStyle(.ultraThinMaterial)
                    .opacity(isShowingSettingView ? (device == .pad ? 1 : 1) : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            // 아이패드에서 외부 터치 시 저장없이 닫기
                            isShowingSettingView = false
                        }
                    }
            }
            SettingView(isShowingSettingView: $isShowingSettingView)
                .frame(width: device == .phone ? geometry.size.width : 400)
                .position(x: isShowingSettingView
                          ? (device == .phone
                            ? (geometry.size.width / 2) : 220)
                          : (device == .phone
                               ? (-geometry.size.width)
                               : (-geometry.size.width + 200)),
                          y: geometry.size.height / 2)
                .animation(isShowingSettingView ? .linear.delay(0.15) : .linear,
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
            if phCollectionList == nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    leftHomeToolBarItem
                }
            }
            if phCollectionList != nil && navigationTitle() == "(No Title)" {
                ToolbarItem(placement: .principal) {
                    Text("(No Title)")
                        .foregroundStyle(.gray )
                }
            }
        }
        .foregroundColor(.secondary)
        .background { FancyBackground() }
        .edgesIgnoringSafeArea(.trailing)
        .onChange(of: photoData.loadingState) { newValue in
            if photoData.loadingState != .loadingComplete {
                switch newValue {
                case .doneTopFolder:
                    photoData.loadAlbumData(step: .loadSecondaryLines)
                case .loadAllAlbums:
                    DispatchQueue.global(qos: .background).async {
                        photoData.loadAlbumData(step: .loadAllAlbums)
                    }
                case .doneAllAlbums:
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
                        photoData.loadAlbumData(step: .loadRemainFolders)
                    }
                case .doneRemainfolders:
                    photoData.loadAlbumData(step: .loadHomeAlbum)
                default: break
                }
            }
        }
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
                        dismiss()
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
            dispatchAnimation {
                self.isShowingSettingView.toggle()
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
            if phCollectionList != nil {
                Button {
                    let alertObject = AlertObject(
                        alertCase: .folderNameChange,
                        album: nil,
                        folder: phCollectionList,
                        needsTextField: true)
                    NotificationCenter.default
                        .post(name: .showAlert, object: alertObject)
                } label: {
                    ContextMenuItem(title: "폴더 이름 변경하기",
                                    image: "pencil")
                }
                Divider()
            }
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
}

// MARK: - [Funcs] 앨범 추가 / 수정 Alert
extension AlbumView {
    enum ObjectType {
        case menu, editingMode
    }
}

struct AlbumView_Previews: PreviewProvider {
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


struct ScrollObject: Equatable {
    let id: String
}

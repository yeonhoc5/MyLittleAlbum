//
//  CollectionLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI
import Photos
import LottieUI

struct FolderListView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @ObservedObject var pageFolder: MLFolder
    let isHome: Bool
    // ui 프라퍼티
    let pageIndex: Int
    let screenWidth: CGFloat
    let secondaryWidth: CGFloat
    var isEditingMode: Bool
    var nameSpace: Namespace.ID
    var albumViewNameSpace: Namespace.ID
    let scrollProxy: ScrollViewProxy
    @Binding var isPhotosView: Int
    @State var foldedFolder: [String] = []
    @State var processingCollection: PHCollection!
    
    var body: some View {
        VStack(spacing: 5) {
            SectionView(sectionType: .folder,
                        uiMode: photoData.uiMode,
                        collectionCount: pageFolder.foldersArray.count,
                        isUnfolded: .constant(false))
            folderListView(pageFolder: pageFolder,
                           idEditingMode: isEditingMode)
        }
    }
}

extension FolderListView {
    func folderListView(pageFolder: MLFolder!,
                        idEditingMode: Bool) -> some View {
        let lineHeight = cellHeight(width: secondaryWidth,
                                    uiMode: photoData.uiMode,
                                    cellType: .folder)
        return VStack(spacing: 0) {
            ForEach(pageFolder?.foldersArray ?? [], id: \.localIdentifier) { phCollectionList in
                let isFolded = !self.foldedFolder
                    .contains(phCollectionList.localIdentifier)
                let index = (pageFolder?.foldersArray ?? []).firstIndex(of: phCollectionList) ?? 0
                nextFolderView(uiMode: photoData.uiMode,
                               collectionList: phCollectionList,
                               index: index,
                               height: lineHeight,
                               isFolded: isFolded,
                               lineView: { folderIndex in
                    Group {
                        if let secondaryFolder = photoData.folders[phCollectionList.localIdentifier] {
                            SecondaryLineView(
                                pageFolder: secondaryFolder,
                                phCollectionList: phCollectionList,
                                isHome: isHome,
                                index: folderIndex,
                                screenWidth: screenWidth,
                                secondaryWidth: secondaryWidth,
                                lineHeight: lineHeight,
                                isFolded: isFolded,
                                isPhotosView: $isPhotosView,
                                nameSpace: nameSpace,
                                albumViewNameSpace: albumViewNameSpace,
                                isEditingMode: isEditingMode
                            )
                            .onChange(of: secondaryFolder.fetchResult.count,
                                      perform: { [oldValue = secondaryFolder.fetchResult.count] newValue in
                                if newValue > oldValue {
                                    withAnimation {
                                        scrollProxy
                                            .scrollTo(secondaryFolder.id, anchor: .center)
                                    }
                                }
                            })
                        } else {
                            FancyBackground()
                        }
                    }
                })
                .transition(.move(edge: .leading))
            }
        }
        .onChange(of: photoData.uiMode) { newValue in
            if newValue != .classic {
                dispatchAnimation {
                    foldedFolder.removeAll()
                }
            }
        }
    }
}

extension FolderListView {
    @ViewBuilder
    func nextFolderView(uiMode: UIMode,
                        collectionList: PHCollectionList,
                        index: Int,
                        height: CGFloat,
                        isFolded: Bool,
                        lineView: @escaping (Int) -> some View) -> some View {
        let folderIndex = pageIndex + ((index + 1) * 4)
        switch uiMode {
        case .classic:
            VStack(alignment: .leading, spacing: 0) {
                classicNextFolderView(folder: collectionList,
                                      isFolded: isFolded)
                .zIndex(1)
                .padding(.horizontal , 10)
                lineView(folderIndex)
            }
            .padding(.vertical, 5)
        default:
            ZStack(alignment: .leading) {
                fancyModernNextFolderview(folder: collectionList,
                                          index: folderIndex,
                                          height: height)
                .disabled(isEditingMode)
                .overlay(alignment: .topLeading) {
                    btnDelete(folder: collectionList)
                        .offset(x: -1, y: -1)
                }
                .contextMenu(menuItems: {
                    editFolderMenu(folder: collectionList)
                })
                .padding(.vertical, 6)
                .padding(.leading, 10)
                .zIndex(1)
                    lineView(folderIndex)
            }
        }
    }
    
    func classicFolderLineView(pageFolder: MLFolder!, view: some View, mode: Bool, width: CGFloat) -> some View {
        let spacing = (self.screenWidth - (CGFloat(listCount+1) * width)) / CGFloat(listCount+1)
        let albumCount = pageFolder?.albumsArray.count ?? 0
        let folderCount = pageFolder?.foldersArray.count ?? 0
        
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
//                .padding([.leading, .vertical], 10)
//                .padding(.trailing, 5)
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
    
    
    func classicNextFolderView(folder: PHCollectionList, isFolded: Bool) -> some View {
        let folderCount = photoData.folders[folder.localIdentifier]?
            .foldersArray.count ?? 0
        let albumCount = photoData.folders[folder.localIdentifier]?
            .albumsArray.count ?? 0
        return VStack {
            HStack {
                Group {
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundColor(.orange).font(.system(size: 12))
                        .rotationEffect(Angle(radians: isFolded ? -.pi/2 : 0))
                    Text(folder.localizedTitle ?? "")
                        .foregroundColor(.orange).fontWeight(.bold)
                        .contentTransition(.numericText())
                    Text("(\(folderCount) / \(albumCount))")
                        .font(.footnote).foregroundColor(.gray)
                        .contentTransition(.numericText())
                }
                .frame(height: 20)
                .onTapGesture {
                    dispatchAnimation {
                        foldFolder(folder: folder.localIdentifier)
                    }
                }
                Spacer()
                Group {
                    if !isEditingMode {
                        Menu {
                            editFolderMenu(folder: folder)
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        btnDelete(folder: folder)
                    }
                }
                .buttonStyle(ClickScaleEffect(scale: 0.8))
                .transition(.scale)
//                .padding(.leading, 5)
//                .padding(.trailing, 15)
            }
            .zIndex(1)
            CustomDivider(color: .secondary)
        }
//        .padding(.leading, 10)
    }
    
    func fancyModernNextFolderview(folder: PHCollectionList, index: Int, height: CGFloat) -> some View {
        return NavigationLink {
            if let pageFolder = photoData.folders[folder.localIdentifier] {
                AlbumView(pageFolder: pageFolder,
                          phCollectionList: folder,
                          pageIndex: index,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace,
                          isShowingSettingView: .constant(false))

            }
        } label: {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.folder)
                if let folder = photoData.folders[folder.localIdentifier] {
                    FolderTitleView(folder: folder)
                } else {
                    Text(folder.localizedTitle ?? "")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .padding(.all, 5)
                }
            }
            .shadow(radius: 2)
        }
        .buttonStyle(ClickScaleEffect())
        .frame(width: abs(secondaryWidth * 0.6),
               height: abs(height))
        .transition(.scale)
    }
}

struct FolderTitleView: View {
    @ObservedObject var folder: MLFolder
    var body: some View {
        Text(folder.title)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .contentTransition(.numericText())
            .padding(.all, 5)
    }
}

// editfoldercontext funcs
extension FolderListView {
    func editFolderMenu(folder: PHCollectionList) -> some View {
        VStack {
            Button {
                let alertObject = AlertObject(
                    alertCase: .addFolderToFolder,
                    album: nil,
                    folder: folder,
                    needsTextField: true)
                NotificationCenter.default
                    .post(name: .showAlert,
                          object: alertObject)
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
                NotificationCenter.default
                    .post(name: .showAlert,
                          object: alertObject)
            } label: {
                let albumIcon = "rectangle.stack.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 앨범 추가하기", image: albumIcon)
            }
            Divider()
            Button {
                let alertObject = AlertObject(
                    alertCase: .folderNameChange,
                    album: nil,
                    folder: folder,
                    needsTextField: true)
                NotificationCenter.default
                    .post(name: .showAlert, object: alertObject)
            } label: {
                ContextMenuItem(title: "폴더 이름 변경하기", image: "pencil")
            }
            Button {
                let reorderObject = ReorderObject(localIdentifier: folder.localIdentifier)
                NotificationCenter.default
                    .post(name: .showReorderSheet,object: reorderObject)
            } label: {
                let albumIcon = "rectangle.stack.fill.badge.plus"
                ContextMenuItem(title: "폴더 내 순서 조정하기", image: albumIcon)
            }
            Divider()
            Button {
                let moveObject = MoveCollectionObject(
                    currentParent: pageFolder,
                    objectCellType: .folder,
                    objectFolder: folder,
                    objectAlbum: nil,
                    objectColorIndex: pageIndex,
                    objectIdentifier: folder.localIdentifier,
                    nameSpace: nameSpace)
                NotificationCenter.default
                    .post(name: .showMoveCollectionSheet, object: moveObject)
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기",
                                image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                deleteFolderInDepth(folder: folder)
            } label: {
                ContextMenuItem(title: "이 폴더 삭제하기", image: "trash")
            }
        }
    }
    
    func btnDelete(folder: PHCollectionList) -> some View {
        Button {
            processingCollection = folder as PHCollection
            deleteFolderInDepth(folder: folder)
        } label: {
            RemoveButtonLabel(shapeType: .rectangle,
                              isProcessing: processingCollection == folder)
        }
        .opacity(isEditingMode ? 1:0)
        .scaleEffect(isEditingMode ? 1:0.1, anchor: .center)
        .buttonStyle(ClickScaleEffect())
    }
        
    func deleteFolderInDepth(folder: PHCollectionList)  {
        pageFolder.deleteFolder(folder: folder) { bool in
            dispatchAnimation {
                if bool {
                    photoData.removeFolderValue(folder: folder) { 
                        NotificationCenter.default
                            .post(name: .outsideFetchChange, object: "myPhotos")
                    }
                }
                self.processingCollection = nil
            }
        }
    }
    func foldFolder(folder: String)  {
        if let index = self.foldedFolder.firstIndex(of: folder) {
            withAnimation {
                let _ = self.foldedFolder.remove(at: index)
            }
        } else {
            withAnimation {
                foldedFolder.append(folder)
            }
        }
    }
}

enum SheetType {
    case reOrder, moveCollection, moveAsset, photosPicker
}

struct CollectionLineView_Previews: PreviewProvider {
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

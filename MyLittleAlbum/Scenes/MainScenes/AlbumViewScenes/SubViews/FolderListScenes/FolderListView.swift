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
    // 사진 데이터
    @ObservedObject var stateChangeObject: StateChangeObject
    @ObservedObject var pageFolder: Folder
    // ui 프라퍼티
    var color: Color! = .orange
    var isTopFolder: Bool! = false
    var uiMode: UIMode
    let secondaryWidth: CGFloat
    var randomNum1: Int = 0
    var randomNum2: Int = 0
    
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    @Binding var isShowingReorderSheet: Bool
    var isEditingMode: Bool
    
    var nameSpace: Namespace.ID
    var albumViewNameSpace: Namespace.ID
    @Binding var currentFolder: Folder!
    @Binding var isPhotosView: Bool

    
    var body: some View {
        VStack(spacing: 5) {
            SectionView(sectionType: .folder,
                        uiMode: uiMode,
                        collectionCount: pageFolder.countFolder,
                        viewMode: .constant(false))
            folderListView(pageFolder: pageFolder,
                           idEditingMode: isEditingMode)
        }
    }
}

extension FolderListView {
    func folderListView(pageFolder: Folder,
                        idEditingMode: Bool) -> some View {
        return VStack(spacing: 0) {
            ForEach(pageFolder.folderArray,
                    id: \.self) { phCollectionList in
                let index = pageFolder.folderArray
                    .firstIndex(of: phCollectionList)!
                let nextFolder = Folder(
                    folder: phCollectionList,
                    colorIndex: (pageFolder.colorIndex + (index + 1) * 4))
                Group {
                    switch uiMode {
                    case .classic:
                        ClassicFolderLineView(
                            stateChangeObject: stateChangeObject,
                            pageFolder: nextFolder,
                            randomNum1: randomNum1,
                            randomNum2: randomNum2,
                            width: secondaryWidth,
                            isPhotosView: $isPhotosView,
                            isShowingSheet: $isShowingSheet,
                            isShowingPhotosPicker: $isShowingPhotosPicker,
                            isShowingReorderSheet: $isShowingReorderSheet,
                            isEditingMode: isEditingMode,
                            nameSpace: nameSpace,
                            albumViewNameSpace: albumViewNameSpace,
                            currentFolder: $currentFolder)
                    case .fancy, .modern:
                        fancySecondaryFolderLineView(
                            folder: nextFolder,
                            animationID: nameSpace,
                            width: secondaryWidth)
                    }
                }
                .overlay(alignment: .topLeading) {
                    btnDelete(folder: nextFolder.folder)
                        .offset(CGSize(
                            width: uiMode == .classic ? 5 : 0,
                            height: uiMode == .classic ? 0 : 5)
                        )
                }
            }
            .padding(.leading, uiMode == .classic ? 0 : 10)
        }
    }

    func fancySecondaryFolderLineView(folder: Folder,
                                      animationID: Namespace.ID,
                                      width: CGFloat) -> some View {
        let secondaryHeight = secondaryHeight(width: width, uiMode: uiMode)
        let thirdList = FancyFolderLineView(
            stateChangeObject: stateChangeObject,
            pageFolder: folder,
            isTopFolder: isTopFolder,
            uiMode: uiMode,
            randomNum1: randomNum1,
            randomNum2: randomNum2,
            width: width,
            isPhotosView: $isPhotosView,
            nameSpace: nameSpace,
            albumViewNameSpace: albumViewNameSpace,
            isShowingSheet: $isShowingSheet,
            isShowingPhotosPicker: $isShowingPhotosPicker,
            isEditingMode: isEditingMode,
            currentFolder: $currentFolder
        )
        return ZStack(alignment: .bottomLeading) {
            thirdList
            NavigationLink {
                AlbumView(pageFolder: folder,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace,
                          isShowingSettingView: .constant(false),
                          stateChangeObject: StateChangeObject())
            } label: {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.folder)
                    Text(folder.title)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.all, 5)
                        .onSubmit {
                            print(width * 0.6, secondaryHeight)
                        }
                }
                .frame(width: width * 0.6, height: secondaryHeight)
                .padding(.vertical, 5)
                .shadow(radius: 2)
            }
            .buttonStyle(ClickScaleEffect())
            .contextMenu{ editFolderMenu(folder: folder.folder) }
            .disabled(isEditingMode || stateChangeObject.isShowingMenu)
        }
        .matchedGeometryEffect(id: folder.identifier, in: albumViewNameSpace)
    }
}

// editfoldercontext funcs
extension FolderListView {
    func editFolderMenu(folder: PHCollectionList) -> some View {
        VStack {
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .secondary,
                                 preesed: .folder,
                                 toAdd: .folder,
                                 edit: .add,
                                 collection: folder)
                }
            } label: {
                let folderIcon = "folder.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 폴더 추가하기", image: folderIcon)
            }
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .secondary,
                                 preesed: .folder,
                                 toAdd: .album,
                                 edit: .add,
                                 collection: folder)
                }
            } label: {
                let albumIcon = "rectangle.stack.fill.badge.plus"
                ContextMenuItem(title: "폴더 안에 앨범 추가하기", image: albumIcon)
            }
            Divider()
            Button {
                DispatchQueue.main.async {
                    showingAlert(depth: .current,
                                 preesed: .folder,
                                 toAdd: .none,
                                 edit: .modify,
                                 collection: folder)
                }
            } label: {
                ContextMenuItem(title: "폴더 이름 변경하기", image: "pencil")
            }
            Button {
                DispatchQueue.main.async {
                    showingSheet(type: .reOrder, currentFolder: Folder(folder: folder))
                }
            } label: {
                let albumIcon = "rectangle.stack.fill.badge.plus"
                ContextMenuItem(title: "폴더 내 순서 조정하기", image: albumIcon)
            }
            Divider()
            Button {
                showingSheet(type: .moveCollection, currentFolder: pageFolder, selectedFolder: folder as PHCollection)
            } label: {
                ContextMenuItem(title: "다른 폴더로 이동하기", image: "rectangle.portrait.and.arrow.forward.fill")
            }
            Divider()
            Button(role: .destructive) {
                pageFolder.deleteFolder(folder: folder) { _ in
                    
                }
            } label: {
                ContextMenuItem(title: "이 폴더 삭제하기", image: "trash")
            }
        }
    }
    
    func btnDelete(folder: PHCollectionList) -> some View {
        Button {
            deleteFolderInDepth(folder: folder)
        } label: {
            RemoveButtonLabel(shapeType: .rectangle)
        }
        .opacity(isEditingMode ? 1:0)
        .scaleEffect(isEditingMode ? 1:0.1, anchor: .center)
        .buttonStyle(ClickScaleEffect())
    }

    func showingAlert(depth: DepthType, preesed: PressedType, toAdd: CollectionType, edit: EditType, collection: PHCollection) {
        stateChangeObject.isShowingAlert = true
        stateChangeObject.depthType = depth
        stateChangeObject.pressedType = preesed
        stateChangeObject.collectionType = toAdd
        stateChangeObject.editType = edit
        stateChangeObject.collectionToEdit = collection
    }
        
    func deleteFolderInDepth(folder: PHCollectionList)  {
        DispatchQueue.main.async {
            pageFolder.deleteFolder(folder: folder) { bool in
            }
        }
    }
    
    func showingSheet(type: SheetType, currentFolder: Folder, selectedFolder: PHCollection! = nil) {
        switch type {
        case .reOrder: self.isShowingReorderSheet = true
        case .moveCollection:
            self.isShowingSheet = true
            stateChangeObject.collectionToEdit = selectedFolder
        default: break
        }
        self.currentFolder = currentFolder
    }
    
}

enum SheetType {
    case reOrder, moveCollection, moveAsset, photosPicker
}

struct CollectionLineView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView(pageFolder: Folder(isHome: true),
                  isPhotosView: .constant(false),
                  nameSpace: Namespace().wrappedValue,
                  isShowingSettingView: .constant(false),
                  stateChangeObject: StateChangeObject())
            .environmentObject(PhotoData())
    }
}

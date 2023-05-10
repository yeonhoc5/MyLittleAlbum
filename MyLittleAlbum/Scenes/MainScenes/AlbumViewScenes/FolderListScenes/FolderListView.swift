//
//  CollectionLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI
import Photos

struct FolderListView: View {
    // 사진 데이터
    @ObservedObject var stateChangeObject: StateChangeObject
    @ObservedObject var pageFolder: Folder
    // ui 프라퍼티
    var color: Color! = .orange
    var uiMode: UIMode
    var randomNum1: Int = 0
    var randomNum2: Int = 0
    
    @Binding var isShowingSheet: Bool
    @Binding var isShowingPhotosPicker: Bool
    @Binding var isShowingReorderSheet: Bool
    var isEditingMode: Bool
    
    @Namespace private var namespace
    @Binding var currentFolder: Folder!
    
    var body: some View {
        VStack(spacing: 8) {
            SectionView(sectionType: .folder, uiMode: uiMode, collectionCount: pageFolder.countFolder)
                .padding(.leading, 10)
            folderListView(pageFolder: pageFolder, idEditingMode: isEditingMode)
        }
    }
}

extension FolderListView {
    func folderListView(pageFolder: Folder, idEditingMode: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(pageFolder.folderArray, id: \.self) { phCollectionList in
                let index = pageFolder.folderArray.firstIndex(of: phCollectionList)!
                let nextFolder = Folder(folder: phCollectionList,
                                        colorIndex: (pageFolder.colorIndex + (index + 1) * 4))
                
                switch uiMode {
                case .classic:
                    ClassicFolderLineView(stateChangeObject: stateChangeObject,
                                          pageFolder: nextFolder,
                                          randomNum1: randomNum1, randomNum2: randomNum2,
                                          isShowingSheet: $isShowingSheet,
                                          isShowingPhotosPicker: $isShowingPhotosPicker,
                                          isShowingReorderSheet: $isShowingReorderSheet,
                                          isEditingMode: isEditingMode,
                                          currentFolder: $currentFolder)
                        .overlay(alignment: .topLeading) {
                            Button {
                                deleteFolderInDepth(folder: nextFolder.folder)
                            } label: {
                                RemoveButtonLabel(shapeType: .rectangle)
                            }
                            .opacity(isEditingMode ? 1:0)
                            .scaleEffect(isEditingMode ? 1:0.1, anchor: .center)
                            .buttonStyle(ClickScaleEffect())
                            .offset(CGSize(width: 5, height: 0))
                        }
                        .matchedGeometryEffect(id: nextFolder.identifier, in: namespace)
                        .id(nextFolder.identifier)
                case .fancy:
                    fancySecondaryFolderLineView(folder: nextFolder, animationID: namespace)
                        .overlay(alignment: .topLeading) {
                            Button {
                                deleteFolderInDepth(folder: nextFolder.folder)
                            } label: {
                                RemoveButtonLabel(shapeType: .rectangle)
                            }
                            .opacity(isEditingMode ? 1:0)
                            .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
                            .buttonStyle(ClickScaleEffect())
                            .offset(CGSize(width: 10, height: 5))
                        }
                        .matchedGeometryEffect(id: nextFolder.identifier, in: namespace)
                        .id(nextFolder.identifier)
                case .modern:
                    fancySecondaryFolderLineView(folder: nextFolder, animationID: namespace)
                        .overlay(alignment: .topLeading) {
                            Button {
                                deleteFolderInDepth(folder: nextFolder.folder)
                            } label: {
                                RemoveButtonLabel(shapeType: .rectangle)
                            }
                            .opacity(isEditingMode ? 1:0)
                            .scaleEffect(isEditingMode ? 1:0.1, anchor: .topLeading)
                            .buttonStyle(ClickScaleEffect())
                            .offset(CGSize(width: 10, height: 5))
                        }
                        .matchedGeometryEffect(id: nextFolder.identifier, in: namespace)
                        .id(nextFolder.identifier)
                }
            }
        }
    }
    
    
    func fancySecondaryFolderLineView(folder: Folder, animationID: Namespace.ID) -> some View {
        let thirdList = FancyFolderLineView(stateChangeObject: stateChangeObject,
                                            pageFolder: folder,
                                            uiMode: uiMode,
                                            randomNum1: randomNum1, randomNum2: randomNum2,
                                            isShowingSheet: $isShowingSheet,
                                            isShowingPhotosPicker: $isShowingPhotosPicker,
                                            isEditingMode: isEditingMode,
                                            currentFolder: $currentFolder)
        return ZStack(alignment: .bottomLeading) {
            thirdList
            NavigationLink {
                AlbumView(stateChangeObject: StateChangeObject(),
                          pageFolder: folder,
                          isShowingSettingView: .constant(false))
                } label: {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.folder)
                        Text(folder.title)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding(.all, 5)
                    }
                    .shadow(radius: 2)
                }
                .frame(width: 50, height: 130 * 0.7)
                .buttonStyle(ClickScaleEffect())
                .disabled(isEditingMode || stateChangeObject.isShowingMenu)
                .padding(.leading, 10)
                .padding(.vertical, 5)
        }
        .contextMenu{ editFolderMenu(folder: folder.folder) }
    }
    
    
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
}

// editfoldercontext funcs
extension FolderListView {
    
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

//struct CollectionLineView_Previews: PreviewProvider {
//    static var previews: some View {
//        FolderListView(stateChangeObject: StateChangeObject(), pageFolder: Folder(isHome: true), uiMode: .fancy, isShowingSheet: .constant(false), isShowingPhotosPicker: .constant(false), isShowingReorderSheet: .constant(false), isEditingMode: false, currentFolder: .constant(nil))
//    }
//}

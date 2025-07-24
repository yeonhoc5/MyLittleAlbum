//
//  FolderCategoryView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/16/25.
//

import SwiftUI
import Photos

struct FolderCategoryView: View {
    var isHome: Bool
    @EnvironmentObject var photoData: MLPhotoData
    // 현재 위치
    var currentFolder: PHCollectionList!
    var lowerFolder: [PHCollectionList]!
    var currentAlbum: PHAssetCollection!
    // 해당 라인 폴더
    var lineFolder: PHCollectionList
    // 이동시킬 앨범/폴더
    var toMoveCollection: PHCollection!
    // 이동할 목표지로 선택할 폴더
    @Binding var isTopFolderSelected: Bool
    @Binding var folderToAddCollection: PHCollectionList!
    @Binding var albumToAddPhotos: PHAssetCollection!
    // (폴더 이동의 경우) 이동시킬 폴더의 하위폴더들은 전부 disable 처리
    let inheritedDisable: Bool
    // 폴더 depth 정보
    var depthCount = 1
    @State var folded: Bool = true
    let showAlbumList: Bool
    
    @Binding var moveBtnTitle: String
    let scrollProxy: ScrollViewProxy
    let onTapAction: (PHCollectionList) -> Void
    
    var body: some View {
        let folder = photoData
            .folders[lineFolder.localIdentifier] ?? MLFolder(collectionList: lineFolder)
        let disable = (folder.phCollectionList == currentFolder
                       || (toMoveCollection?.isKind(of: PHCollectionList.self) ?? false
                           && toMoveCollection == folder.phCollectionList))
        let isSelected = folderToAddCollection == folder.phCollectionList
        return Group {
            folderLineView(folder: folder, disable: disable)
                .id(folder.id)
                .listRowSeparator(isSelected ? .hidden : .visible)
            if showAlbumList && isSelected && !folder.albumsArray.isEmpty {
                SelectableCollectionView(
                    collectionType: .album,
                    emptytext: "이 폴더에는 앨범이 없습니다.",
                    currentAlbum: currentAlbum,
                    albumArray: folder.albumsArray.map({ $0.localIdentifier }),
                    albumToAddPhotos: $albumToAddPhotos,
                    depthCount: depthCount,
                    objectFolder: nil,
                    currentParent: nil,
                    folderToAddCollection: .constant(nil),
                    isTopFolderSelected: $isTopFolderSelected,
                    lowers: [])
            }
            if !folded {
                ForEach(folder.foldersArray, id: \.self) { subFolder in
                    let inherited = toMoveCollection?
                        .isKind(of: PHCollectionList.self) ?? false
                                    && toMoveCollection == subFolder
                    FolderCategoryView(isHome: isHome,
                                       currentFolder: currentFolder,
                                       currentAlbum: currentAlbum,
                                       lineFolder: subFolder,
                                       toMoveCollection: toMoveCollection,
                                       isTopFolderSelected: $isTopFolderSelected,
                                       folderToAddCollection: $folderToAddCollection,
                                       albumToAddPhotos: $albumToAddPhotos,
                                       inheritedDisable: inherited || inheritedDisable,
                                       depthCount: depthCount + 1,
                                       showAlbumList: showAlbumList,
                                       moveBtnTitle: $moveBtnTitle,
                                       scrollProxy: scrollProxy) { folder in
                        dispatchAnimation {
                            onTapAction(folder)
                        }
                    }
                }
            }
        }
    }
    
    func folderLineView(folder: MLFolder, disable: Bool) -> some View {
        let sideImage = folder.phCollectionList == currentFolder
        ? "chevron.up.circle.fill"
        : folder.phCollectionList == toMoveCollection
                ? "circle.circle.fill"
                : (inheritedDisable ? "chevron.down.circle.fill" : "" )
        return HStack(spacing: 7) {
            DepthArrow(folded: folder.foldersArray.isEmpty ? true : folded,
                        isSelected: folderToAddCollection == folder.phCollectionList,
                        count: depthCount,
                        subCount: folder.foldersArray.count)
                .onTapGesture {
                    withAnimation {
                        folded.toggle()
                    }
                    if !folded {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                scrollProxy.scrollTo(
                                    folder.id,
                                    anchor: .top
                                )
                            }
                        }
                    }
                }
                .disabled(false)
            FolderLineView(isCollectionMoveView: !showAlbumList,
                           title: "\(folder.title)",
                           subImage: sideImage,
                           isSelected: folderToAddCollection == folder.phCollectionList,
                           albumEmpty: folder.albumsArray.isEmpty)
            .foregroundColor(disable || inheritedDisable
                             ? .disabledColor
                             : (folderToAddCollection == folder.phCollectionList
                                                 ? .selectedColor : .nonSelectedColor))
            .onTapGesture {
                if !disable && !inheritedDisable {
                    withAnimation {
                        folderToAddCollection = folderToAddCollection == folder.phCollectionList ? nil : folder.phCollectionList
                        isTopFolderSelected = false
                    }
                    let letter = isHome ? "에" : "로"
                    moveBtnTitle = folderToAddCollection == nil ? "" : "[\(folder.title)] 폴더\(letter)"
                    onTapAction(folder.phCollectionList)
                }
            }
            .disabled(disable || inheritedDisable)
        }
        .listRowBackground(Color.white)
    }
}

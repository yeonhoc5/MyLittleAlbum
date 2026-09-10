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
  let folderType: FolderType
  // 현재 위치
  var currentFolder: SubCollection!
  var lowerFolder: [SubCollection]!
  var currentAlbumID: String!
  // 해당 라인 폴더
  var lineSubFolder: SubCollection
  // 이동시킬 앨범/폴더
  var toMoveCollection: SubCollection!
  // 이동할 목표지로 선택할 폴더
  @Binding var isTopFolderSelected: Bool
  @Binding var folderToAddCollection: SubCollection!
  @Binding var albumToAddPhotos: SubCollection!
  // (폴더 이동의 경우) 이동시킬 폴더의 하위폴더들은 전부 disable 처리
  let inheritedDisable: Bool
  // 폴더 depth 정보
  var depthCount = 1
  @State var folded: Bool = true
  let showAlbumList: Bool
  
  @Binding var moveBtnTitle: String
  let scrollProxy: ScrollViewProxy
  let onTapAction: (SubCollection) -> Void
  
  var body: some View {
    Group {
      if let folder = photoData.mlFolder(type: folderType,
                                         lineSubFolder.id) {
        let disable = (folder.id == currentFolder?.id
                       || (toMoveCollection?.type == .folder
                           && toMoveCollection?.id == folder.id))
        let isSelected = folderToAddCollection?.id == folder.id
        Group {
          folderLineView(folder: folder, disable: disable)
            .id(folder.id)
            .listRowSeparator(isSelected ? .hidden : .visible)
          if showAlbumList && isSelected && !folder.albumsArray.isEmpty {
            SelectableCollectionView(
              folderType: .userFolder,
              recentType: .album,
              emptytext: "이 폴더에는 앨범이 없습니다.",
              currentAlbumID: currentAlbumID,
              albumArray: folder.albumsArray.map({ $0.id }),
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
              let inherited = (toMoveCollection?.type == .folder) && (toMoveCollection?.id ?? "" == subFolder.id)
              FolderCategoryView(
                isHome: isHome,
                folderType: folderType,
                currentFolder: currentFolder,
                currentAlbumID: currentAlbumID,
                lineSubFolder: subFolder,
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
      } else {
        EmptyView()
      }
    }
  }
  
  func folderLineView(folder: MLFolder, disable: Bool) -> some View {
    let sideImage = folder.id == currentFolder?.id
    ? "chevron.left.circle.fill"
    : folder.id == toMoveCollection?.id
    ? "circle.circle.fill"
    : (inheritedDisable ? "chevron.down.circle.fill" : "" )
    return HStack(spacing: 7) {
      DepthArrow(
        folded: folder.foldersArray.isEmpty ? true : folded,
        isSelected: folderToAddCollection?.id == folder.id,
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
      FolderLineView(
        isCollectionMoveView: !showAlbumList,
        title: "\(folder.title)",
        subImage: sideImage,
        isSelected: folderToAddCollection?.id == folder.id,
        albumEmpty: folder.albumsArray.isEmpty)
      .foregroundColor(disable || inheritedDisable
                       ? .disabledColor
                       : (folderToAddCollection?.id == folder.id
                          ? .selectedColor : .nonSelectedColor))
      .onTapGesture {
        if !disable && !inheritedDisable {
          withAnimation {
            if folderToAddCollection?.id == folder.id {
              folderToAddCollection = nil
            } else {
              folderToAddCollection = SubCollection(
                id: folder.id,
                title: folder.title,
                type: .folder)
            }
            isTopFolderSelected = false
          }
          let letter = isHome ? "에" : "로"
          moveBtnTitle = folderToAddCollection == nil ? "" : "[\(folder.title)] 폴더\(letter)"
          let subFolder = SubCollection(id: folder.id, title: folder.title, type: .folder)
          onTapAction(subFolder)
        }
      }
      .disabled(disable || inheritedDisable)
    }
    .listRowBackground(Color.white)
  }
}

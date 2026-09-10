//
//  SelectAlbumListView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/16/25.
//

import SwiftUI
import Photos

struct SelectableCollectionView: View {
  @EnvironmentObject var photoData: MLPhotoData
  let folderType: FolderType
  let recentType: RecentType
  let emptytext: String
  
  // move asset
  let currentAlbumID: String
  let albumArray: [String] // recent + category albumList View
  @Binding var albumToAddPhotos: SubCollection!
  let depthCount: Int
  
  // move collection
  let objectFolder: SubCollection!
  let currentParent: SubCollection!
  @Binding var folderToAddCollection: SubCollection!
  @Binding var isTopFolderSelected: Bool
  let lowers: [String]
  
  var body: some View {
    let array = switch recentType {
    case .folder: photoData.recentWorkFolder
    case .category: photoData.recentWorkCategory
    case .album: albumArray
    }
    return GeometryReader { geoProxy in
      let size = geoProxy.size
      collectionLayout(count: array.count, emptyText: emptytext) {
        collectionList(recentType: recentType,
                       array: array,
                       size: size)
      }
      .padding(.bottom, 10)
      .frame(width: size.width, height: size.height)
    }
    .frame(height: 80)
    .transition(.opacity)
    .listRowInsets(
      EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
    )
  }
  
  func collectionList(recentType: RecentType,
                      array: [String],
                      size: CGSize) -> some View {
    ForEach(array, id: \.self) { list in
      if recentType != .album {
        if let folder = photoData
                        .mlFolder(type: folderType, list),
           let parentID = currentParent?.id,
           let objectID = objectFolder?.id {
          let current = list == parentID
          let oneSelf = list == objectID
          let lowerFolder = self.lowers.contains(list)
          let selected = folder.id == folderToAddCollection?.id
          Button {
            if !(current || oneSelf || lowerFolder) {
              withAnimation {
                if selected {
                    folderToAddCollection = nil
                } else {
                  folderToAddCollection = folder.subCollection(id: folder.id, type: .folder)
                }
              }
            }
          } label: {
            labelView(title: (folder.id == "topFolder"
                              || folder.id == "shareTop")
                              ? "최상위 폴더" : folder.title,
                      current: current,
                      isSelf: oneSelf,
                      isLower: lowerFolder,
                      selected: selected,
                      size: size)
            //                .contextMenu(menuItems: {
            //                    deleteRecent(assetCollection: album)
            //                })
          }
          .disabled(current || oneSelf || lowerFolder)
        }
      } else {
        if let album = photoData.albums[list] {
          let oneSelf = currentAlbumID == album.phAssetCollection?.localIdentifier
          let selected = albumToAddPhotos?.id == album.id
          Button {
            if !oneSelf {
              withAnimation {
                let subAlbum = SubCollection(id: album.id,
                                             title: album.title,
                                             type: .album)
                if self.albumToAddPhotos == nil {
                  albumToAddPhotos = subAlbum
                } else {
                  albumToAddPhotos = albumToAddPhotos?.id == album.id
                  ? nil : subAlbum
                }
              }
            }
          } label: {
            labelView(title: album.title,
                      current: false,
                      isSelf: oneSelf,
                      isLower: false,
                      selected: selected,
                      size: size)
//                .contextMenu(menuItems: {
//                    deleteRecent(assetCollection: album)
//                })
          }
          .disabled(oneSelf)
        }
      }
    }
  }
  
  func labelView(title: String,
                 current: Bool,
                 isSelf: Bool,
                 isLower: Bool,
                 selected: Bool,
                 size: CGSize) -> some View {
    let disable = current || isSelf || isLower
    return ZStack {
      Text(title)
        .foregroundStyle(disable ? .gray
                                : (selected ? .blue : .white))
        .padding(.horizontal, 15)
        .frame(minWidth: current ? 52 : 0)
        .background {
          ZStack(alignment: .topLeading) {
            if recentType == .album {
              RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color.fancyBackground)
            }
            RoundedRectangle(cornerRadius: 10)
              .foregroundStyle(disable
                               ? .gray.opacity(0.1)
                               : (selected ? .white.opacity(0.9)
                                          : .white.opacity(0.1)))
              .conditionalModifier(!disable, transform: { view in
                view
                  .availabeGlassEffect(cornerR: 10,
                                       foreground: .thickMaterial) { view in
                    view
                      .shadow(color: .gray,
                              radius: selected ? 0 : 1, x: 0, y: 0)

                  }
              })
//              .foregroundStyle((current || isSelf || isLower)
//                               ? .gray.opacity(0.1)
//                               : (selected
//                                  ? Color.orange
//                                  : Color.white)
//              )
              .frame(height: size.height - 25)
            Group {
              if current {
                chevronDirection(direction: .current)
              } else if isSelf {
                chevronDirection(direction: .none)
              } else if isLower {
                chevronDirection(direction: .secondary)
              }
            }
            .padding(3)
          }
        }
    }
  }
  
  func deleteRecent(assetCollection: PHAssetCollection) -> some View {
    Button {
      
    } label: {
      ContextMenuItem(title: "내역 지우기")
    }
    
  }
  func collectionLayout(count: Int, emptyText: String, listView: @escaping ( ) -> some View) -> some View {
    Group {
      if count > 0 {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHGrid(rows: [GridItem(spacing: 10)]) {
            listView()
          }
          .padding(.trailing, 20)
          .padding(.leading, 20 + CGFloat(27 * depthCount))
        }
      } else {
        ZStack {
          Text(emptyText)
            .foregroundStyle(.gray)
        }
      }
    }
  }
  
  func chevronDirection(direction: DepthType) -> some View {
    let image = switch direction {
    case .current: "chevron.left.circle.fill" // 현재위치
    case .none: "circle.circle.fill" // 오브젝트 대상
    case .secondary: "chevron.down.circle.fill" // 하위
    }
    return imageScaledFit(systemName: image, width: 14, height: 14)
      .foregroundStyle(.gray)
  }
}

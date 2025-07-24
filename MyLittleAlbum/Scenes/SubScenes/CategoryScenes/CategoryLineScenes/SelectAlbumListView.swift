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
    let collectionType: CollectionType
    let emptytext: String
    
    // move asset
    let currentAlbum: PHAssetCollection!
    let albumArray: [String] // recent + category albumList View
    @Binding var albumToAddPhotos: PHAssetCollection!
    let depthCount: Int
    
    // move collection
    let objectFolder: PHCollectionList!
    let currentParent: PHCollectionList!
    @Binding var folderToAddCollection: PHCollectionList!
    @Binding var isTopFolderSelected: Bool
    let lowers: [String]
    
    var body: some View {
        let array = collectionType == .folder
                                ? photoData.recentWorkFolder
                                : albumArray
        return GeometryReader { geoProxy in
            let size = geoProxy.size
            collectionLayout(count: array.count, emptyText: emptytext) {
                collectionList(isFolder: collectionType == .folder,
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

    func collectionList(isFolder: Bool, array: [String], size: CGSize) -> some View {
        ForEach(array, id: \.self) { list in
            if isFolder {
                if let folder = photoData.folders[list] {
                    let current = list == currentParent?.localIdentifier ?? "topFolder"
                    let oneSelf = list == objectFolder?.localIdentifier ?? ""
                    let lowerFolder = self.lowers.contains(list)
                    let selected = folder.phCollectionList == nil ? isTopFolderSelected : (folder.phCollectionList == folderToAddCollection)
                    Button {
                        if !(current || oneSelf || lowerFolder) {
                            withAnimation {
                                if folder.phCollectionList == nil {
                                    isTopFolderSelected.toggle()
                                    if isTopFolderSelected && folderToAddCollection != nil {
                                        folderToAddCollection = nil
                                    }
                                } else {
                                    if self.isTopFolderSelected {
                                        isTopFolderSelected = false
                                    }
                                    folderToAddCollection = folderToAddCollection == folder.phCollectionList
                                                            ? nil : folder.phCollectionList
                                }
                            }
                        }
                    } label: {
                        labelView(title: folder.phCollectionList == nil ? "최상위 폴더" : folder.title,
                                  current: current,
                                  isSelf: oneSelf,
                                  isLower: lowerFolder,
                                  selected: selected,
                                  size: size)
                        //                .contextMenu(menuItems: {
                        //                    deleteRecent(assetCollection: album)
                        //                })
                    }
                }
            } else {
                if let album = photoData.albums[list] {
                    let oneSelf = currentAlbum == album.phAssetCollection
                    let selected = albumToAddPhotos == album.phAssetCollection
                    Button {
                        if !oneSelf {
                            withAnimation {
                                if self.albumToAddPhotos == nil {
                                    albumToAddPhotos = album.phAssetCollection
                                } else {
                                    albumToAddPhotos = albumToAddPhotos == album.phAssetCollection
                                    ? nil : album.phAssetCollection
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
        return ZStack {
            Text(title)
                .foregroundStyle((current || isSelf || isLower) ? Color.gray
                                 : (selected ? Color.white : Color.fancyBackground))
                .padding(.horizontal, 15)
                .frame(minWidth: current ? 52 : 0)
                .background {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle((current || isSelf || isLower)
                                             ? .gray.opacity(0.1)
                                             : (selected
                                                ? Color.orange
                                                : Color.white)
                            )
                            .shadow(color: .gray, radius: selected ? 0 : 1, x: 0, y: 0)
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

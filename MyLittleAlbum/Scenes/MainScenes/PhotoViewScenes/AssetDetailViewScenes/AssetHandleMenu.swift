//
//  AssetHandleMenu.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/17/25.
//

import SwiftUI
import Photos

struct AssetHandleMenu: View {
    @EnvironmentObject var photoData: MLPhotoData
    var albumType: AlbumType = .album
    let assetCollection: PHAssetCollection!
    let isHiddenAssets: Bool
    let asset: MLAsset
    @Binding var reLoadingType: ReLoadingType
    @Binding var selectedItems: [MLAsset]
    @Binding var copyDone: Bool
    
    var body: some View {
        Group {
            if let album = albumType == .album
                ? photoData.albums[assetCollection.localIdentifier]
                : (albumType == .smartAlbum
                   ? photoData.smartAlbums[assetCollection.localIdentifier]
                   : photoData.homeAlbum) {
                HStack(spacing: 3) {
                    // 0. 삭제 버튼
                    assetHandleButton(imageName: iconDelete, imageColor: Color.color1) {
                        album.deleteAssetFromDevice(albumType: albumType,
                                                    assets: [asset],
                                                    isHiddenAsset: isHiddenAssets,
                                                    isDetailView: true) { bool in
                            if bool {
                                DispatchQueue.main.async {
                                    NotificationCenter.default
                                        .post(name: .innerFetchChange, object: album.id)
                                    NotificationCenter.default
                                        .post(name: .innerFetchChange, object: "myPhotos")
                                }
                            }
                        }
                    }
                    separator
                    if albumType == .home || albumType == .smartAlbum {
                        // 1-1. 앨범에 추가 버튼
                        assetHandleButton(imageName: iconInsertToAlbum) {
                            dispatchAnimation {
                                let moveAssetObject = MoveAssetObject(
                                    albumType: self.albumType,
                                    currentAlbum: assetCollection,
                                    selectedItems: [asset],
                                    isHidden: isHiddenAssets)
                                NotificationCenter.default
                                    .post(name: .showMoveAssetSheetInDetailView,
                                          object: moveAssetObject)
                            }
                        }
                    } else if albumType == .album {
                        // 1-2-1. 앨범에서 빼기 버튼
                        assetHandleButton(imageName: "rectangle.stack.badge.minus") {
                            let alertObject = AlertObject(alertCase: .mediaTakeFromAlbum,
                                                          album: assetCollection,
                                                          folder: nil,
                                                          selectedItems: [asset],
                                                          isDetailView: true
                                                          
                            )
                            NotificationCenter.default
                                .post(name: .showAlertInDetailView, object: alertObject)
                        }
                        separator
                        // 1-2-2. 앨범 이동 버튼
                        assetHandleButton(isImage: false, titleName: "이동") {
                            let moveAssetObject = MoveAssetObject(
                                albumType: self.albumType,
                                currentAlbum: assetCollection,
                                selectedItems: [asset],
                                isHidden: isHiddenAssets,
                                isDetailView: true)
                            NotificationCenter.default
                                .post(name: .showMoveAssetSheetInDetailView,
                                      object: moveAssetObject)
                        }
                    }
                    Spacer()
                    // 즐겨찾기 버튼
                    assetHandleButton(
                        imageName: asset.isFavorite ? iconFavorite : iconNotFavorite,
                        imageColor: asset.isFavorite ? .color2 : .gray) {
                            asset.favoriteAsset(bool: !asset.isFavorite) { bool in
                                if bool {
                                    //                            dispatchAnimation {
                                    //                                let object = ChangedItem(asset: [asset])
                                    //                                NotificationCenter.default
                                    //                                    .post(name: .assetChanged, object: object)
                                    //                            }
                                }
                            }
                        }
                    
                    separator
                    if !isHiddenAssets {
                        // 2-1. 가리기 버튼
                        assetHandleButton(imageName: iconHide, imageColor: .gray) {
                            guard let album = photoData.albums[assetCollection?.localIdentifier ?? ""] else { return }
                            album.hideOrUnhideAsset(assets: [asset],
                                                    toHide: !asset.isFavorite,
                                                    isDetailView: true) { bool in
                                if bool {
                                    DispatchQueue.main.async {
                                        NotificationCenter.default
                                            .post(name: .innerFetchChange, object: album.id)
                                        NotificationCenter.default
                                            .post(name: .innerFetchChange, object: "myPhotos")
                                    }
                                }
                            }
                        }
                    } else {
                        // 2-2. 가리기 해제 버튼
                        assetHandleButton(imageName: iconUnhide, imageColor: .gray) {
                            let alertObject = AlertObject(alertCase: .mediaUnhide,
                                                          album: assetCollection,
                                                          folder: nil,
                                                          selectedItems: [asset],
                                                          isHiddenAsset: isHiddenAssets,
                                                          isDetailView: true)
                            NotificationCenter.default.post(name: .showAlertInDetailView,
                                                            object: alertObject)
                        }
                        //                }
                    }
                    separator
                    // 이미지 복사 버튼
                    
                    assetHandleButton(imageName: "document.on.document", imageColor: .gray) {
                        let imageManager = PHImageManager()
                        imageManager.requestImage(for: asset.phAsset, targetSize: CGSize(width: .max, height: .max), contentMode: .aspectFit, options: nil) { image, _ in
                            UIPasteboard.general.image = image
                            dispatchAnimation {
                                copyDone = true
                            }
                        }
                    }
                    // 3. 공유 버튼
                    //            separator
                    //                .opacity(0.2)
                    //            assetHandleButton(imageName: "square.and.arrow.up", imageColor: .gray) {
                    //            }
                }
                .foregroundStyle(.gray)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black)
                        .frame(height: vcHeight)
                }
            } else {
                EmptyView()
            }
        }
    }
    var separator: some View {
        Text("|")
            .foregroundStyle(.white)
            .opacity(0.4)
    }
    func assetHandleButton(isImage: Bool = true,
                           imageName: String = "",
                           titleName: String = "",
                           buttonColor: Color! = nil,
                           imageColor: Color! = .white,
                           action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(.black)
                .frame(width: 40, height: 30)
                .overlay {
                    if isImage {
                        Image(systemName: imageName)
                            .foregroundStyle(imageColor)
                            .imageScale(.medium)
                    } else {
                        Text(titleName)
                    }
                }
        }
    }
    
}
#Preview {
    AssetHandleMenu(assetCollection: nil,
                    isHiddenAssets: false,
                    asset: MLAsset(phAsset: PHAsset()),
                    reLoadingType: .constant(.none),
                    selectedItems: .constant([]),
                    copyDone: .constant(false))
}


struct ChangedItem {
    let assets: [MLAsset]
    let albumType: AlbumType
}

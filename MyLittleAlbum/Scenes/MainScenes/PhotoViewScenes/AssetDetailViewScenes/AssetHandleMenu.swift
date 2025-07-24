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
    @ObservedObject var asset: MLAsset
    @Binding var reLoadingType: ReLoadingType
    @Binding var selectedItems: [MLAsset]
    
    var body: some View {
        HStack(spacing: 3) {
            // 0. 삭제 버튼
            assetHandleButton(imageName: iconDelete, imageColor: Color.color1) {
                guard let album = albumType == .home
                                ? photoData.homeAlbum
                                : photoData.homeAlbum
                else { return }
                
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
                    asset.favoriteAsset { bool in
                        if bool {
                            dispatchAnimation {
                                let object = ItemChangedView(id: assetCollection?.localIdentifier ?? "home",
                                                             items: [asset.id])
                                NotificationCenter.default
                                    .post(name: .itemChanged, object: object)
                            }
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
                    asset: MLAsset(phAsset: PHAsset(), isAlbum: false),
                    reLoadingType: .constant(.none),
                    selectedItems: .constant([]))
}


struct ItemChangedView {
    let id: String
    let items: [String]
}

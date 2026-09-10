//
//  InAppMoveAssetSheet.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/17/25.
//

import SwiftUI
import Photos

struct InAppMoveAssetSheet: ViewModifier {
  @EnvironmentObject var photoData: MLPhotoData
  @Binding var isShowingMoveAssetSheet: Bool
  @Binding var moveAssetObject: MoveAssetObject?
  let assetMoved: (Bool) -> Void

  func body(content: Content) -> some View {
    content
      .sheet(
        isPresented: .constant(isShowingMoveAssetSheet),
        onDismiss: {
          self.isShowingMoveAssetSheet = false
          self.moveAssetObject = nil
      }) {
        if let object = self.moveAssetObject {
          MoveAssetCategoryView(
            isShowingMoveAssetSheet: $isShowingMoveAssetSheet,
            isShowingSelectFolderSheet: .constant(false),
            albumType: object.albumType,
            currentAlbumID: object.currentAlbumID,
            isHiddenAssets: object.isHidden,
            isDetailView: object.isDetailView,
            selectedItems: object.selectedItems,
            selectedFolder: nil,
            completion: { albumID, selectedAssets in
              addAssetIntoAlbum(albumToMove: albumID,
                                currentAlbumType: object.albumType,
                                currentAlbumID: object.currentAlbumID,
                                assets: selectedAssets,
                                isHidden: object.isHidden) { bool in
                DispatchQueue.main.async {
                  assetMoved(bool)
                }
              }
            }
          )
          .interactiveDismissDisabled()
          .ignoresSafeArea()
        }
      }
  }
  func addAssetIntoAlbum(albumToMove: String,
                         currentAlbumType: AlbumType,
                         currentAlbumID: String,
                         assets: [MLAsset],
                         isHidden: Bool,
                         completion: @escaping (Bool) -> Void) {
    guard let toAlbum = photoData.albums[albumToMove]
    else { return }
    // 목표 앨범에 삽입
    toAlbum.addAsset(assets: assets, completion: { bool in
      // 현재 앨범에서 제거
      if bool {
        // 최근 작업 앨범 저장
        DispatchQueue.global(qos: .utility).async {
          photoData
            .addRecentWorkSpace(id: toAlbum.id,
                                recentType: .album)
        }
        switch currentAlbumType {
        case .home:
          DispatchQueue.main.async {
            NotificationCenter.default
              .post(name: .outsideFetchChange, object: toAlbum.id)
          }
          completion(bool)
        case .album:
          // 다른 앨범으로 이동한 asset 제거
          if let current = photoData.albums[currentAlbumID] {
            current.removeAssetFromAlbum(
              assets: assets,
              isHidden: isHidden) { bool in
                completion(bool)
              }
          }
        default: break
        }
      }
    })
  }
}

#Preview {
  ContentView()
//    .modifier(
//      InAppMoveAssetSheet(viewState: AllPhotosState(),
//                          assetMoved: { bool in })
//    )
    .environmentObject(MLPhotoData())
}

struct MoveAssetObject: Equatable {
  var albumType: AlbumType
  let currentAlbumID: String!
  let selectedItems: [MLAsset]
  var isHidden: Bool
  var isDetailView: Bool = false
}


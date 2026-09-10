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
  let media: UIImage?
  var albumType: AlbumType = .album
  let localID: String
  let isHiddenAssets: Bool
  let isPad: Bool
  let backGroundColor = Color.black.opacity(0.5)
  @ObservedObject var asset: MLAsset
  @Binding var playStatus: VideoState
  @Binding var copyDone: Bool
  @Binding var assetAlert: AssetAlert!
  @Binding var moveAssetObject: MoveAssetObject!
  @Binding var isShowingMoveAssetSheet: Bool
  @Binding var workState: WorkState
  
  let removeAsset: () -> Void
  let reloadAssets: (MLAsset) -> Void
  
  var body: some View {
    Group {
      if let album = albumType == .album
          ? photoData.albums[localID]
          : (albumType == .share
             ? photoData.smartAlbums[localID]
             : photoData.homeAlbum) {
        ZStack {
          RoundedRectangle(cornerRadius: 10)
            .availabeGlassEffect(cornerR: 10,
                                 foreground: backGroundColor) { view in
              view
            }
          HStack(spacing: 3 * (isPad ? 2 : 1)) {
            // 0. 삭제 버튼
            assetHandleButton(imageName: iconDelete,
                              imageColor: Color.color1,
                              workState: .delete) { completion in
              album.deleteAssetFromDevice(albumType: albumType,
                                          assets: [asset],
                                          isHiddenAsset: isHiddenAssets,
                                          isDetailView: true) { bool in
                if bool {
                  removeAsset()
                }
                completion()
              }
            }
            separator
            if albumType == .home || albumType == .share {
              // 1-1. 앨범에 추가 버튼
              assetHandleButton(imageName: iconInsertToAlbum,
                                workState: .addSubtrack) {  completion in
                let moveAssetObject = MoveAssetObject(
                  albumType: self.albumType,
                  currentAlbumID: localID,
                  selectedItems: [asset],
                  isHidden: isHiddenAssets)
                dispatchAnimation {
                  self.moveAssetObject = moveAssetObject
                  self.isShowingMoveAssetSheet = true
                }
                completion()
              }
            } else if albumType == .album {
              // 1-2-1. 앨범에서 빼기 버튼
              assetHandleButton(imageName: iconSubtract,
                                workState: .addSubtrack) {  completion in
                showAlert(alertCase: .subtract)
              }
              separator
              // 1-2-2. 앨범 이동 버튼
              assetHandleButton(isImage: false,
                                titleName: "이동",
                                workState: .move) {  completion in
                if playStatus == .play {
                  DispatchQueue.main.async {
                    playStatus = .processPause
                  }
                }
                let moveAssetObject = MoveAssetObject(
                  albumType: self.albumType,
                  currentAlbumID: localID,
                  selectedItems: [asset],
                  isHidden: isHiddenAssets)
                dispatchAnimation {
                  self.moveAssetObject = moveAssetObject
                  self.isShowingMoveAssetSheet = true
                }
                completion()
              }
            }
            Spacer()
            // 즐겨찾기 버튼
            assetHandleButton(
              custom: asset.isFavorite,
              imageName: asset.isFavorite ? "CrayonRed" : iconNotFavorite,
              imageColor: asset.isFavorite ? .heart : .white,
              workState: .favorite) { completion in
                asset.favoriteAsset(toFavorite: !asset.isFavorite) { bool in
                  if bool {
                    reloadAssets(asset)
                  }
                  completion()
                }
              }
              .contentTransition(.interpolate)
            separator
            if !isHiddenAssets {
              // 2-1. 가리기 버튼
              assetHandleButton(imageName: iconHide,
                                workState: .hide) { completion in
                guard let album = photoData.albums[localID]
                else { return }
                album.hideOrUnhideAsset(
                  assets: [asset],
                  toHide: !asset.isFavorite) { bool in
                    if bool {
                      removeAsset()
                    }
                    completion()
                  }
              }
            } else {
              // 2-2. 가리기 해제 버튼
              assetHandleButton(imageName: iconUnhide,
                                workState: .hide) { completion in
                showAlert(alertCase: .unHide)
                completion()
              }
            }
            separator
            // 이미지 복사 버튼
            assetHandleButton(imageName: "document.on.document",
                              workState: .copy) { completion in
              
//              let imageManager = PHImageManager()
////              if asset.mediaType == .image {
//              imageManager.requestImage(
//                for: asset.phAsset,
//                targetSize: CGSize(width: .max, height: .max),
//                contentMode: .aspectFit,
//                options: nil) { image, _ in
//              guard let image = media else { return }
//              UIPasteboard.general.image = image
//                  UIPasteboard.general.image = image
//                  dispatchAnimation {
//                    copyDone = true
//                  }
//                  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    withAnimation {
//                      self.copyDone = false
//                    }
//                  }
//                  completion()
//                }
//              } else {
//                imageManager.requestAVAsset(forVideo: asset.phAsset,
//                                            options: nil) { (avAsset, audioMix, info) in
//                  print("step 1")
//                    guard let urlAsset = avAsset as? AVURLAsset else {
//                      print("no urlAsset")
//                      return }
//                    do {
//                      print("step 2")
//                      let videoData = try Data(contentsOf: urlAsset.url)
//                      // Proceed to copy to clipboard
//                      print("step 3")
//                      UIPasteboard.general
//                        .setData(videoData,
//                                 forPasteboardType: UTType.mpeg4Movie.identifier)
//                      dispatchAnimation {
//                        copyDone = true
//                      }
//                      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        withAnimation {
//                          self.copyDone = false
//                        }
//                      }
//                      completion()
//                    } catch {
//                      print("Error loading video data: \(error.localizedDescription)")
//                      completion()
//                    }
//                  }
//              }
            }
            // 3. 공유 버튼
            //            separator
            //                .opacity(0.2)
            //            assetHandleButton(imageName: "square.and.arrow.up", imageColor: .gray) {
            //            }
          }
          .foregroundStyle(.gray)
          .padding(.horizontal, isPad ? 10 : 5)
        }
      } else {
        EmptyView()
      }
    }
  }
  var separator: some View {
    Text("|")
      .foregroundStyle(.gray)
  }
  func assetHandleButton(isImage: Bool = true,
                         custom: Bool = false,
                         imageName: String = "",
                         titleName: String = "",
                         buttonColor: Color! = nil,
                         imageColor: Color! = .white,
                         workState: WorkState,
                         action: @escaping (@escaping () -> Void) -> Void) -> some View {
    Button {
      dispatchAnimation {
        self.workState = workState
      }
      action {
        dispatchAnimation {
          self.workState = .none
        }
      }
    } label: {
      Group {
        if self.workState == workState {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(.blue)
        } else {
          Group {
            if !custom {
              Label(titleName, systemImage: imageName)
                .modify { view in
                  if isImage {
                    view.labelStyle(.iconOnly)
                  } else {
                    view.labelStyle(.titleOnly)
                  }
                }
            } else {
              Image(imageName)
                .resizable()
                .mask {
                  Image(systemName: "star.fill")
                }
            }
          }
          .foregroundStyle(imageColor)
        }
      }
      .frame(width: isPad ? 50 : 40, height: isPad ? 50 : 30)
    }
  }
  
  func showAlert(alertCase: AssetAlertCase) {
    guard let album = photoData.albums[localID] else { return }
    let alertObject = AssetAlert(alertCase: alertCase,
                                 assets: [asset],
                                 album: album,
                                 isHiddenAsset: isHiddenAssets)
    dispatchAnimation {
      self.assetAlert = alertObject
    }
  }
}
#Preview {
  AssetHandleMenu(media: nil,
                  localID: "",
                  isHiddenAssets: false,
                  isPad: false,
                  asset: MLAsset(phAsset: PHAsset()),
                  playStatus: .constant(.pause),
                  copyDone: .constant(false),
                  assetAlert: .constant(nil),
                  moveAssetObject: .constant(nil),
                  isShowingMoveAssetSheet: .constant(true),
                  workState: .constant(.none),
                  removeAsset: { },
                  reloadAssets: { _ in })
}


struct ChangedItem {
  let assets: [MLAsset]
  let albumType: AlbumType
}

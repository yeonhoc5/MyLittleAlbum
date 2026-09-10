//
//  AssetAlertModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/19/26.
//

import SwiftUI
import Photos

enum collectionAlert {
  case createAlbum, createFolder, modifyAlbumTitle, modifyFolderTitle
  //    case deleteAlbum, deleteFolder        // device self-Alert
}

struct CollectionAlert {
  let alertCase: collectionAlert
  let cellType: CellType
  let assetcolelction: PHAssetCollection!
  let collectionList: PHCollectionList!
}


struct AssetAlertModifier: ViewModifier {
  @State var collectionAlert: CollectionAlert!
  @Binding var assetAlert: AssetAlert!
  let completion: (Bool) -> Void
  
  func body(content: Content) -> some View {
    content
      .alert(AssetAlert.title(alert: assetAlert),
             isPresented: .constant(assetAlert != nil)) {
        Button("취소") {
          DispatchQueue.main.async {
            self.assetAlert = nil
          }
          completion(false)
        }
        Button("확인") {
          DispatchQueue.main.async {
            self.assetAlert = nil
          }
          assetAction { bool in
            completion(bool)
          }
        }
        .keyboardShortcut(.defaultAction) // 키보드 엔터 처리
      } message: {
        configMessage(
          alertCase: self.assetAlert?.alertCase,
          count: self.assetAlert?.assets.count ?? 0
        )
      }
  }
  
  
  func configMessage(alertCase: AssetAlertCase! = .unHide,
                     count: Int) -> some View {
    switch alertCase {
    case .subtract:
        Text("- 선택한 항목 : \(count)개\n- 해당 항목\(count > 1 ? "들" : "")은 [나의 포토] 탭에서 찾을 수 있습니다.")
    case .unHide:
        Text("- 선택한 항목 : \(count)개")
    default: Text("")
    }
  }
  func assetAction(completion: @escaping (Bool) -> Void) {
    guard let alert = self.assetAlert else { return }
    switch alert.alertCase {
    case .unHide:
      alert.album
        .hideOrUnhideAsset(assets: alert.assets,
                           toHide: false) { bool in
          if bool {
            completion(bool)
          }
        }
    case .subtract:
      alert.album
        .removeAssetFromAlbum(assets: alert.assets,
                              isHidden: alert.isHiddenAsset) { bool in
          if bool {
            completion(bool)
          }
        }
    }
  }
}

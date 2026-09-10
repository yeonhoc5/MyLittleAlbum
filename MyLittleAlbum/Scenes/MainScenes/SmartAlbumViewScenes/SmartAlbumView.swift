//
//  SmarAlbumView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/03.
//

import SwiftUI
import Photos
import LottieUI

struct SmartAlbumView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @Binding var isShowingSettingView: Bool
  let smartAlbums: [SmartAlbum] = [SmartAlbum(smatType: .favorite),
                                   SmartAlbum(smatType: .hiddenAsset)]
  @State var isShowingSmartAlbum: Bool = false
  @State var smartAlbumToSee: SmartAlbum! = nil
  @Binding var isPhotosView: Int
  var nameSpace: Namespace.ID
  
  var body: some View {
    VStack {
      List {
        ForEach(smartAlbums, id: \.id) { smart in
          listRow(smart: smart, rowBackground: Color.white) {
            smartAlbumToSee = smart
            dispatchAnimation {
              isShowingSmartAlbum = true
            }
          } afterAuthenticate: {
            smartAlbumToSee = smart
            // isShowing은 자물쇠 애니메이션(Lottie) onFrame에서 결정
          }
          .foregroundColor(.fancyBackground)
        }
        .navigationDestination(isPresented: $isShowingSmartAlbum,
                               destination: {
          if let smart = self.smartAlbumToSee {
            if let album = photoData.smartAlbums[smart.id] {
              AllPhotosView(
                mlAlbum: album,
                isHiddenAsset: album.isPrivacy,
                nameSpace: nameSpace,
                isPhotosView: $isPhotosView) { _ in }
            } else {
              let album = MLAlbum(assetCollection: smart.phAssetCollection,
                                  smartAlbumType: smart.smartAlbumType,
                                  title: smart.title,
                                  isPrivacy: smart.isPrivacy)
              AllPhotosView(mlAlbum: album,
                            isHiddenAsset: smart.isPrivacy,
                            nameSpace: nameSpace,
                            isPhotosView: $isPhotosView) { _ in }
            }
          }
             
        })
        //            footer: {
        //                Text("애플(APPLE)의 정책에 의해,\n[설정>앱>사진]에서 \"암호사용\" 또는 \"FaceID사용\"을 활성화 한 경우,\n아이폰 [사진] 앱을 제외한 앱에서는 \"가린 항목\"을 볼 수 없습니다.")
        //                    .foregroundColor(.gray)
        //                    .font(Font.system(size: 11))
        //                    .multilineTextAlignment(.leading)
        //                    .lineSpacing(7)
        //                    .padding(.vertical, 10)
        //                    .padding(.horizontal, -10)
        //            }
        //            Section {
        //                NavigationLink {
        //                    ImageVolumeView()
        //                } label: {
        //                    Text("미디어 용량")
        //                }
        //
        //            }
      }
      .safeAreaInset(edge: .top) {
        Color.clear
          .frame(height: photoData.premiumUser ? 0 : adsRegionSpacing-30) 
      }
      .padding(.bottom, tabbarHeight)
      .listStyle(.insetGrouped)
      .listItemTint(.fancyBackground)
      .scrollContentBackground(.hidden)
    }
    .ignoresSafeArea(edges: .bottom)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("사진 관리")
    .background(Color.fancyBackground)
    .onAppear {
      dispatchAnimation {
        isPhotosView = 0
      }
      let imageManger = photoData.cachingManager
      DispatchQueue.global(qos: .default).async {
        imageManger
            .stopCachingImagesForAllAssets()
        smartAlbumToSee = nil
      }
    }
  }
}

extension SmartAlbumView {
  func checkSmartAlbum(smart: SmartAlbum, result: @escaping () -> Void) {
    if let _ = photoData.smartAlbums[smart.id] {
      result()
    } else {
      generateSmart(smart: smart) {
        result()
      }
    }
  }
  func listRow(smart: SmartAlbum,
               rowBackground: Color,
               directMove: @escaping () -> Void,
               afterAuthenticate: @escaping () -> Void) -> some View {
    GeometryReader { geoproxy in
      HStack {
        imageScaledFit(systemName: smart.icon, width: 20, height: 20)
        ZStack(alignment: .leading) {
          Rectangle()
            .foregroundColor(.white)
          Text(smart.title)
            .lineLimit(1)
            .truncationMode(.tail)
        }
        if smart.isPrivacy {
          Spacer()
          LottieView("unlock")
            .renderingEngine(.automatic)
            .play(smartAlbumToSee?.id ?? "" == smart.id)
            .loopMode(.playOnce)
            .backgroundBehavior(.pauseAndRestore)
            .onFrame({ frame in
              if frame == 18.0 {
                isShowingSmartAlbum = true
              }
            })
            .frame(width: geoproxy.size.height,
                   height: geoproxy.size.height)
        }
      }
    }
    .listRowBackground(rowBackground)
    .onTapGesture {
      checkSmartAlbum(smart: smart) {
        if !smart.isPrivacy {
          directMove()
        } else {
          authenticate { bool in
            if bool {
              afterAuthenticate()
            }
          }
        }
      }
    }
  }
  
  func generateSmart(smart: SmartAlbum, async completion: @escaping () -> Void) {
    let smartAlbum = MLAlbum(assetCollection: smart.phAssetCollection,
                             smartAlbumType: smart.smartAlbumType,
                             title: smart.title,
                             isPrivacy: smart.isPrivacy)
    DispatchQueue.main.async {
      photoData.smartAlbums
        .updateValue(
          smartAlbum,
          forKey: smartAlbum.phAssetCollection?.localIdentifier ?? "\(smart.title)")
      completion()
    }
  }
}

struct SmarAlbumView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(isOpen: true)
      .environmentObject(PhotoData())
  }
}


struct SmartAlbum: Equatable {
  let id: String
  let phAssetCollection: PHAssetCollection!
  let smartAlbumType: SmartType
  let title: String
  let icon: String
  let isPrivacy: Bool
  
  init(smatType: SmartType) {
    switch smatType {
    case .hiddenAsset:
      title = "가려진 항목"
      icon = iconHide
      isPrivacy = true
      phAssetCollection = PHAssetCollection
        .fetchAssetCollections(with: .smartAlbum,
                               subtype: .smartAlbumAllHidden,
                               options: nil)
        .firstObject!
      smartAlbumType = .hiddenAsset
      id = phAssetCollection.localIdentifier
    default:
      title = "즐겨찾는 항목"
      icon = iconFavorite
      isPrivacy = false
      phAssetCollection = PHAssetCollection
        .fetchAssetCollections(with: .smartAlbum,
                               subtype: .smartAlbumFavorites,
                               options: nil)
        .firstObject!
      smartAlbumType = .favorite
      id = phAssetCollection.localIdentifier
    }
  }
}

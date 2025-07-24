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
    @Binding var isPhotosView: Int
    let smartAlbums: [SmartAlbum] = [SmartAlbum(smatType: .favorite),
                                     SmartAlbum(smatType: .hiddenAsset)]
    var nameSpace: Namespace.ID
    @State var isShowingSmartAlbum: Bool = false
    @State var smartAlbum: SmartAlbum!
    
    var body: some View {
        List {
            Section {
                ForEach(smartAlbums, id: \.id) { smart in
                    listRow(smart: smart, tapAction: {
                        if smart.isPrivacy {
                            authenticate(albumType: .smartAlbum) { bool in
                                if bool {
                                    dispatchAnimation {
                                        self.smartAlbum = smart
                                    } 
                                }
                            }
                        } else {
                            dispatchAnimation {
                                self.smartAlbum = smart
                                isShowingSmartAlbum = true
                            }
                        }
                    })
                    .listRowBackground(Color.white)
                    .foregroundColor(.fancyBackground)
                }
            }
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
        .padding(.bottom, tabbarHeight)
        .listStyle(.insetGrouped)
        .listItemTint(.fancyBackground)
        .background(Color.fancyBackground)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("사진 관리")
        .onAppear(perform: {
            smartAlbum = nil
        })
        .navigationDestination(isPresented: $isShowingSmartAlbum,
                               destination: {
            if let smart = smartAlbum {
                if let mlAlbum = photoData.smartAlbums[smart.id] {
                    AllPhotosView(
                        albumType: .smartAlbum,
                        assetCollection: nil,
                        mlAlbum: mlAlbum,
                        smartAlbumType: smart.smartAlbumType,
                        isHiddenAsset: smart.isPrivacy,
                        settingDone: false,
                        isPhotosView: $isPhotosView,
                        nameSpace: nameSpace)
                } else {
                    RefreshPhotoView(task: {
                        phDataQueue.async {
                            let album = MLAlbum(
                                assetCollection: smart.phAssetCollection,
                                title: smart.title,
                                isPrivacy: smart.isPrivacy)
                            album.generateArray(isHiddenAsset: smart.isPrivacy) {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        let _ = photoData.smartAlbums
                                            .updateValue(album, forKey: album.id)
                                    }
                                }
                            }
                        }
                    })
                }
            }
        })
    }
}

extension SmartAlbumView {
    func listRow(smart: SmartAlbum, tapAction: @escaping () -> Void) -> some View {
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
                        .play(self.smartAlbum?.id == smart.id)
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
            .onTapGesture {
                tapAction()
            }
        }
    }
    
    func generateSmart(smart: SmartAlbum) {
        let smartAlbum = MLAlbum(assetCollection: smart.phAssetCollection,
                                 title: smart.title,
                                 isPrivacy: smart.isPrivacy)
        DispatchQueue.main.async {
            photoData.smartAlbums
                .updateValue(
                    smartAlbum,
                    forKey: smartAlbum.phAssetCollection?.localIdentifier ?? "\(smart.title)")
            isShowingSmartAlbum = true
        }
    }
}
    
struct SmarAlbumView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selection: .other, isOpen: true)
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

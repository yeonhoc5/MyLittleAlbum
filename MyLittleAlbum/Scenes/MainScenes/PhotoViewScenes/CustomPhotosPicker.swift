//
//  CustomPhotosPicker.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/31.
//

import SwiftUI
import Photos

struct CustomPhotosPicker: View {
    @Binding var isShowingPhotosPicker: Bool
    @EnvironmentObject var photoData: MLPhotoData
    @State var mlAlbum: MLAlbum?
    let albumToEdit: String
    let imageCachingManager: PHCachingImageManager

    @State var belongingType: BelongingType = .nonAlbum
    @State var filteringType: FilteringType = .all
    @State var reLoadingType: ReLoadingType = .none
    @State var edgeToScroll: EdgeToScroll = .none
    @State var selectedItems: [MLAsset] = []
    @Namespace private var nameSpace
    
    var body: some View {
        let assetArray = assetArray(mlAlbum: mlAlbum,
                                    albumType: .picker,
                                    belongingType: belongingType)
        GeometryReader(content: { geoProxy in
            let columnCount = columnCount(geoProxy: geoProxy)
            let cellWidth = (geoProxy.size.width - CGFloat(columnCount - 1))
                            / CGFloat(columnCount)
            VStack {
                HStack(spacing: 15) {
                    let width = geoProxy.size.width - 40 - 15
                    titleView(belongingType: belongingType, width: width)
                    subTitleView(assetArray: assetArray, width: width)
                        .frame(width: abs(width * 0.4))
                }
                .frame(height: 90)
                .clipped()
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                ZStack(alignment: .bottom) {
                    if let allPhotos = mlAlbum {
                        photosView(mlAlbum: allPhotos,
                                   assetArray: assetArray,
                                   geoProxy: geoProxy,
                                   cellWidth: cellWidth)
                        gridMenuView(mlAlbum: allPhotos,
                                     assetArray: assetArray,
                                     width: geoProxy.size.width)
                    } else {
                        lottieLoadingView(lottie: "photoLoading",
                                          size: CGSize(width: 100,
                                                       height: geoProxy.size.height / 2),
                                          leadingPadding: 0)
                        .onAppear {
                            if photoData.homeAlbum != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        self.mlAlbum = photoData.homeAlbum
                                    }
                                }
                            } else {
                                let homeAlbum = MLAlbum(isHome: true)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        photoData.homeAlbum = homeAlbum
                                        self.mlAlbum = homeAlbum
                                    }
                                }
                            }
                        }
                    }
                }
                .onReceive(NotificationCenter.default
                    .publisher(for: .outsideFetchChange), perform: { object in
                        if reLoadingType != .reFetchOutside {
                            if object.object as? String == "picker" {
                                print("Picker View outter fetch Recieved")
                                DispatchQueue.main.async {
                                    reLoadingType = .reFetchOutside
                                }
                            }
                        }
                    })
            }
            .padding(.top, 10)
        })
        .background { FancyBackground() }
    }
}

extension CustomPhotosPicker {
    func photosView(mlAlbum: MLAlbum, assetArray: [MLAsset], geoProxy: GeometryProxy, cellWidth: CGFloat) -> some View {
        NewPhotosCollectionView(
            albumType: .picker,
            mlAlbum: mlAlbum,
            assetArray: .constant(assetArray),
            filteringType: $filteringType,
            belongingType: belongingType,
            geoProxy: geoProxy,
            cellWidth: cellWidth,
            imageCachingManager: imageCachingManager,
            isSelectMode: .constant(true),
            selectedItems: $selectedItems,
            refreshItems: .constant([]),
            indexToView: .constant(0),
            isExpanded: .constant(false),
            edgeToScroll: $edgeToScroll,
            reLoadingType: $reLoadingType
        )
        .frame(width: geoProxy.size.width)
        .animation(.easeOut, value: mlAlbum.fetchResult.count == 0)
        .transition(.opacity)
    }
    
    func gridMenuView(mlAlbum: MLAlbum, assetArray: [MLAsset], width: CGFloat) -> some View {
        HStack {
//            if device == .pad {
//                let spacerWidth = device == .phone
//                            ? 0
//                            : ((width / 4) + (5 * tabbarTopPadding))
//                Rectangle()
//                    .fill(.clear)
//                    .frame(width: spacerWidth)
//            }
            PhotosGridMenu(
                albumType: .picker,
                smartAlbumType: .none,
                mlAlbum: mlAlbum,
                cachingimageManager: imageCachingManager,
                assetArray: assetArray,
                belongingType: $belongingType,
                filteringType: $filteringType,
                isSelectMode: .constant(true),
                selectedItems: $selectedItems,
                refreshItems: .constant([]),
                edgeToScroll: $edgeToScroll,
                isShowingShareSheet: .constant(false),
                isShowingPhotosPicker: $isShowingPhotosPicker,
                albumToEdit: albumToEdit,
                nameSpace: nameSpace,
                width: width,
                reloadingType: $reLoadingType,
                isReadyHiddenAsset: false)
            .frame(height: tabbarHeight)
            .padding(tabbarTopPadding) 
            .clipped()
            .shadow(color: Color.fancyBackground.opacity(0.5),
                    radius: 2, x: 0, y: 0)
        }    }
    func titleView(belongingType: BelongingType, width: CGFloat) -> some View {
        return ZStack {
            Picker("미디어", selection: .constant(self.belongingType), content: {
                Group {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(belongingType == .album ? .white : .clear)
                        Text("앨범 항목 모음")
                            .foregroundColor(belongingType == .album ? .fancyBackground : .white)
                    }
                    .tag(BelongingType.album)
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(belongingType == .all ? .white : .clear)
                        Text("모든 항목")
                            .foregroundColor(belongingType == .all ? .fancyBackground : .white)
                    }
                    .tag(BelongingType.all)
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(belongingType == .nonAlbum ? .white : .clear)
                        Text("앨범에 없는 항목 모음")
                            .foregroundColor(belongingType == .nonAlbum ? .fancyBackground : .white)
                    }
                    .tag(BelongingType.nonAlbum)
                }
                .font(Font.system(size: 20, weight: .semibold, design: .rounded))
            })
            .pickerStyle(.wheel)
            .disabled(true)
            .frame(width: abs(width * 0.6))
            .clipShape(
                RoundedRectangle(cornerRadius: 5)
            )
        }
        .frame(alignment: .center)
    }
    
    func subTitleView(assetArray: [MLAsset], width: CGFloat) -> some View {
        let imageCount = assetArray.filter { $0.mediaType == .image }.count
        let videoCount = assetArray.filter { $0.mediaType == .video }.count
        return HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 13) {
                    Text("사")
                    Text("진 :")
                }
                    .foregroundColor(filteringType == .image ? .blue : .gray)
                Text("비디오 :")
                    .foregroundColor(filteringType == .video ? .blue : .gray)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(mlAlbum != nil ? "\(imageCount)" : "--")
                    .foregroundColor(filteringType == .image ? .blue : .gray)
                Text(mlAlbum != nil ? "\(videoCount)" : "--")
                    .foregroundColor(filteringType == .video ? .blue : .gray)
            }
        }
        .font(.body)
        .frame(alignment: .leading)
        .contentTransition(.numericText())
        .foregroundColor(.gray)
    }
                
    func assetArray(mlAlbum: MLAlbum?, albumType: AlbumType, belongingType: BelongingType) -> [MLAsset] {
        guard let allPhotos = switch belongingType {
        case .all: mlAlbum?.photosArray
        case .nonAlbum: mlAlbum?
                .operatedArray(isHiddenAsset: false,
                               setOperation: .subtraction,
                               assets: Array(photoData.albumsPhotosSet()))
        case .album: mlAlbum?
                .operatedArray(isHiddenAsset: false,
                               setOperation: .intersection,
                               assets: Array(photoData.albumsPhotosSet()))
        }
        else { return [] }
        return allPhotos
            .sorted(by: { $0.creationDate < $1.creationDate })
    }
    
    func columnCount(geoProxy: GeometryProxy) -> Int {
        device == .phone ? cellCount(type: .small) : cellCount(type: .middel2)
    }
}

//struct CustomPhotosPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        CustomPhotosPicker(isShowingPhotosPicker: .constant(true),
//                           stateChangeObject: StateChangeObject(),
//                           album: nil,
//                           size: .zero,
//                           imageCachingManager: PHCachingImageManager(),
//                           title: "Not in any Album",
////                           albumToEdit: Album(assetArray: [], title: "sample"))
//                           albumToEdit: MLAlbum(filterSet: Set<PHAsset>()))
//        .environmentObject(MLPhotoData())
//    }
//}

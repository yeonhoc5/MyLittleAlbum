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
    let albumToEdit: MLAlbum
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
        NavigationView {
            GeometryReader(content: { geoProxy in
                let columnCount = columnCount(geoProxy: geoProxy)
                let cellWidth = (geoProxy.size.width - CGFloat(columnCount - 1))
                                / CGFloat(columnCount)
                VStack {
                    VStack(spacing: 15) {
                        titleView(belongingType: belongingType)
                        subTitleView(assetArray: assetArray, size: geoProxy.size)
                    }
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
                                if self.mlAlbum == nil {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation {
                                            self.mlAlbum = photoData.homeAlbum
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            })
            .background { FancyBackground() }
        }
    }           
}

extension CustomPhotosPicker {
    func photosView(mlAlbum: MLAlbum, assetArray: [MLAsset], geoProxy: GeometryProxy, cellWidth: CGFloat) -> some View {
        NewPhotosCollectionView(
            albumType: .picker,
            mlAlbum: mlAlbum,
            smartAlbumType: .none,
            assetArray: assetArray,
            filteringType: $filteringType,
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
    func titleView(belongingType: BelongingType) -> some View {
        Group {
            switch belongingType {
            case .nonAlbum:
                Text("앨범에 없는 항목 모음")
                    .animation(.easeInOut)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .all:
                Text("모든 항목")
                    .animation(.easeInOut)
                    .transition(
                        .move(edge: belongingType == .all ? .leading : .trailing)
                        .combined(with: .opacity))
            case .album:
                Text("앨범 항목 모음")
                    .animation(.easeInOut)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .font(Font.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundColor(.white)
        .padding(.top, 40)
    }
    
    func subTitleView(assetArray: [MLAsset], size: CGSize) -> some View {
        let imageCount = assetArray.filter { $0.mediaType == .image }.count
        let videoCount = assetArray.filter { $0.mediaType == .video }.count
        return HStack {
            Text("사진: \(mlAlbum != nil ? String(imageCount) : "--")")
                .foregroundColor(filteringType == .image ? .blue : .gray)
                .contentTransition(.numericText())
            Text(" / ")
            Text("비디오: \(mlAlbum != nil ? String(videoCount) : "--")")
                .foregroundColor(filteringType == .video ? .blue : .gray)
                .contentTransition(.numericText())
        }
        .font(.body)
        .contentTransition(.numericText())
        .foregroundColor(.gray)
        .frame(width: size.width)
        .padding(.bottom, 20)
    }
                
    func assetArray(mlAlbum: MLAlbum?, albumType: AlbumType, belongingType: BelongingType) -> [MLAsset] {
        guard let allPhotos = switch belongingType {
        case .all: mlAlbum?.photosArray
        case .nonAlbum: mlAlbum?.subtractingArray(
                        isHiddenAsset: false,
                        subtracting: Array(photoData.albumsPhotosSet())
                        )
                        .sorted(by: { $0.creationDate < $1.creationDate })
        case .album:
            Array(photoData.albumsPhotosSet())
                .sorted(by: { $0.creationDate < $1.creationDate })
        }
        else { return [] }
        return allPhotos
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

//
//  CellCoverView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/14/25.
//

import SwiftUI
import Photos

struct AlbumCoverView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @ObservedObject var album: MLAlbum
    var assetCollection: PHAssetCollection! = nil
    let uiMode: UIMode
    let cellType: CellType
    let size: CGSize
    let colorIndex: Int
    var albumCell: Namespace.ID
    let isEditingMode: Bool
    
    let spacing: CGFloat = 3
    let normalPadding: CGFloat = 7
    let miniPadding: CGFloat = 5
    let radius: CGFloat = 5
        
    @State var rprstImage1: UIImage!
    @State var rprstImage2: UIImage!
    
    var body: some View {
        Group {
            switch uiMode {
            case .classic: classicAlbumView
            case .modern: modernAlbumView
            case .fancy: fancyAlbumView
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: photoData.randomNum1) { newValue in
            // 교체 1 : randomNum change
            if assetCollection != nil {
//                dispatchAnimation {
//                    rprstImage1 = nil
//                    rprstImage2 = nil
//                }
//                phImageQueue.async {
//                    
//                }
            }
        }
        .onReceive(NotificationCenter.default
            .publisher(for: .changeRprstPhotos)) { output in
            if let output = output.object as? String {
                if assetCollection?.localIdentifier ?? "" == output {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        rprstImage1 = nil
                        rprstImage2 = nil
                    }
                }
            }
        }
//        .animation(.easeInOut, value: album != nil)
//        .onChange(of: photoData.uiMode) { newValue in
//                if album.fetchResult.count > 1 {
//                    reloadPhotos(size: size)
//                }
//            }
    }
}

extension AlbumCoverView {
    var classicAlbumView: some View {
        VStack(spacing: 5) {
            GeometryReader { geoProxy in
                let innerSize = geoProxy.size
                let count = (album.sampleCase == .none)
                            ? album.fetchResult.count
                            : (album.sampleCase.returnCount())
                Group {
                    if count > 0 {
                        animationImageView(uiMode: .classic,
                                           size: innerSize,
                                           count: count)
                        .matchedGeometryEffect(id: "photo1", in: albumCell)
                    } else {
                        ZStack(alignment: .bottomTrailing) {
                            RoundedRectangle(cornerRadius: radius)
                                .foregroundStyle(.clear)
                            emptyTextView(uiMode: .classic,
                                          width: innerSize.width,
                                          height: innerSize.height,
                                          bottomPadding: 0)
                            .padding(3)
                        }
                    }
                }
            }
            titleLabelView(uiMode: .classic, size: size, alignment: .center)
        }
        .cornerRadius(radius)
        .frame(width: size.width, height: size.height)
    }
    
    var modernAlbumView: some View {
        ZStack(alignment: .bottom) {
            let labelHeight = size.height * 0.35
            Group {
                let count = (album.sampleCase == .none)
                            ? album.fetchResult.count
                            : (album.sampleCase.returnCount())
                if count != 0 {
                    animationImageView(uiMode: .modern, size: size, count: count)
                        .matchedGeometryEffect(id: "photo1", in: albumCell)
                } else {
                    emptyTextView(uiMode: .modern,
                                  width: size.width,
                                  height: size.height,
                                  bottomPadding: labelHeight)
                }            }
             titleLabelView(uiMode: .modern,
                           size: CGSize(width: size.width, height: labelHeight),
                           alignment: .leading)
        }
        .cornerRadius(radius)
    }
    
    var fancyAlbumView: some View {
        VStack(alignment: .center, spacing: 5) {
            titleLabelView(uiMode: .fancy, size: size, alignment: .topLeading)
                .padding(.leading, isEditingMode ? 30 : 0)
            GeometryReader { geoProxy in
                let innerWidth = geoProxy.size.width
                let innerHeight = geoProxy.size.height
                let firstWidth = (innerWidth - spacing) * 0.65
                let secondWidth = (innerWidth - spacing) * 0.35
                let count = (album.sampleCase == .none)
                            ? album.fetchResult.count
                            : (album.sampleCase.returnCount())
                Group {
                    if count == 0 {
                        emptyTextView(uiMode: .fancy,
                                      width: innerWidth,
                                      height: innerHeight,
                                      bottomPadding: 0)
                    } else {
                        if count == 1 || cellType == .miniAlbum {
                            animationImageView(
                                uiMode: .fancy,
                                size: CGSize(width: innerWidth,
                                             height: innerHeight),
                                count: count)
                            .matchedGeometryEffect(id: "photo1", in: albumCell)
                        } else {
                            HStack(spacing: spacing) {
                                animationImageView(
                                    uiMode: .fancy,
                                    size: CGSize(width: firstWidth,
                                                 height: innerHeight),
                                    count: count)
                                .matchedGeometryEffect(id: "photo1", in: albumCell)
                                animationImageView(
                                    uiMode: .fancy,
                                    isSecond: true,
                                    size: CGSize(width: secondWidth,
                                                 height: innerHeight),
                                    count: count)
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(cellType == .album ? normalPadding : miniPadding)
    }
}


extension AlbumCoverView {
    @ViewBuilder
    func animationImageView(uiMode: UIMode, isSecond: Bool = false, size: CGSize, count: Int) -> some View {
        let checkRadius = uiMode == .fancy && cellType == .album && count > 1
        Group {
            if let image = isSecond ? rprstImage2 : rprstImage1 {
                imageScaledFill(
                    uiImage: image,
                    width: size.width,
                    height: size.height,
                    radius: 5,
                    cornerTopL: checkRadius ? (isSecond ? false : true) : true,
                    cornerBottomL: checkRadius ? (isSecond ? false : true) : true,
                    cornerBottomT: checkRadius ? (isSecond ? true : false) : true,
                    cornerTopT: checkRadius ? (isSecond ? true : false) : true
                )
            } else {
                tempView(width: size.width,
                         cornerTopL: checkRadius ? (isSecond ? false : true) : true,
                         cornerBottomL: checkRadius ? (isSecond ? false : true) : true,
                         cornerBottomT: checkRadius ? (isSecond ? true : false) : true,
                         cornerTopT: checkRadius ? (isSecond ? true : false) : true,
                         radius: radius) {
                    guard let album = photoData.albums[assetCollection.localIdentifier]
                    else { return }
                    if !isSecond {
                        phImageQueue.async {
                            fetchingImage(
                                imageNumber: isSecond ? 2 : 1,
                                asset: album.fetchResult[photoData.randomNum1 % count],
                                thumbNailSize: CGSize(width: size.width,
                                                      height: size.height)
                            )
                        }
                    } else {
                        phImageQueue.async {
                            let seconNum = photoData.randomNum2 % count == photoData.randomNum1 % count
                                        ? ((photoData.randomNum2 + 1) % count)
                                        : (photoData.randomNum2 % count)
                                fetchingImage(
                                    imageNumber: 2,
                                    asset: album.fetchResult[seconNum],
                                    thumbNailSize: CGSize(width: size.width,
                                                          height: size.height)
                                )
                        }
                    }
                }
            }
        }
        .transition(.opacity)
    }
    func tempView(width: CGFloat,
                  cornerTopL: Bool,
                  cornerBottomL: Bool,
                  cornerBottomT: Bool,
                  cornerTopT: Bool,
                  radius: CGFloat,
                  task: @escaping () -> Void) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: cornerTopL ? radius : 0,
            bottomLeadingRadius: cornerBottomL ? radius : 0,
            bottomTrailingRadius: cornerBottomT ? radius : 0,
            topTrailingRadius: cornerTopT ? radius : 0,
            style: .continuous)
        .foregroundStyle(Material.ultraThinMaterial)
        .frame(width: abs(width))
        .onAppear {
            dispatchAnimation {
                task()
            }
        }
    }
    func fetchingImage(imageNumber: Int, asset: PHAsset, thumbNailSize: CGSize) {
        let imageManager = PHImageManager()
        let size = CGSize(width: thumbNailSize.width * scale,
                          height: thumbNailSize.height * scale)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        imageManager.requestImage(for: asset,
                                  targetSize: size,
                                  contentMode: .aspectFill,
                                  options: options) { assetImage, _ in
            dispatchAnimation {
                if let image = assetImage {
                    if imageNumber == 1 {
                        self.rprstImage1 = image
                    } else {
                        self.rprstImage2 = image
                    }
                }
            }
        }
    }
    
    func loadImage(asset: PHAsset, thumbNailSize: CGSize) -> UIImage? {
        let imageManager = PHCachingImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isNetworkAccessAllowed = true
        var image: UIImage!
        let size = CGSize(width: thumbNailSize.width * scale,
                          height: thumbNailSize.height * scale)
        imageManager.requestImage(for: asset,
                                  targetSize: size,
                                  contentMode: .default,
                                  options: requestOptions) { assetImage, _ in
                if let assetImage = assetImage {
                    image = assetImage
                }
            }
        return image
    }
    
    func titleLabelView(uiMode: UIMode, size: CGSize, alignment: Alignment) -> some View {
        Group {
            switch uiMode {
            case .classic:
                titleText(album.title, font: .caption.bold(), color: .orange, inline: true)
                    .padding(.horizontal, spacing)
                    .matchedGeometryEffect(id: "title", in: albumCell)
                    .frame(width: size.width, alignment: alignment)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            case .modern:
                ZStack(alignment: .leading) {
                    Color.white.opacity(0.88)
                        .transition(.opacity)
                        .matchedGeometryEffect(id: "titleBack", in: albumCell)
                        .offset(y: uiMode == .modern ? 0 : size.height )
                    titleText(album.title,
                              font: Font.system(cellType == .album
                                          ? .subheadline : .caption,
                                          weight: .semibold),
                              color: .fancyBackground,
                              inline: cellType == .album ? false : true)
                        .padding(.horizontal, cellType == .album ? normalPadding : miniPadding)
                        .matchedGeometryEffect(id: "title", in: albumCell)
                        .frame(width: size.width, alignment: alignment)
                        .lineLimit(cellType == .album ? 2 : 1, reservesSpace: true)
                        .lineSpacing(0.1)
                        .kerning(0.4)
                        .multilineTextAlignment(.leading)
                        .contentTransition(.numericText())
                }
                .frame(height: size.height)
            case .fancy:
                titleText(album.title,
                          font: cellType == .album ? .footnote.bold() : .footnote,
                          color: .white,
                          inline: cellType == .album ? false : true)
                .matchedGeometryEffect(id: "title", in: albumCell, isSource: false)
                .lineLimit(cellType == .album ? 2 : 1, reservesSpace: true)
                .padding(.horizontal, cellType == .album ? normalPadding : miniPadding)
                .frame(width: size.width, alignment: alignment)
                .multilineTextAlignment(.leading)
                .contentTransition(.numericText())
            }
        }
        .truncationMode(.tail)
    }
    
    @ViewBuilder
    func emptyTextView(uiMode: UIMode, width: CGFloat, height: CGFloat, bottomPadding: CGFloat) -> some View {
        switch uiMode {
        case .classic:
            Text("빈 앨범")
                .font(.caption)
                .foregroundColor(.fancyBackground)
                .padding([.bottom, .trailing], 5)
        case .modern:
            Text("No Photos")
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, bottomPadding)
                .frame(width: width, height: height)
        case .fancy:
            Text(emptyLabel[colorIndex % emptyLabel.count])
                .foregroundColor(.white.opacity(0.5))
                .frame(width: width, height: height)
        }
    }
    
    func loadPhotos(size: CGSize) {
        guard album.fetchResult.count > 0
        else { return }
        let number1 = photoData.randomNum1 % album.fetchResult.count
        var number2 = photoData.randomNum2 % album.fetchResult.count
        if number2 == number1 {
            number2 = (photoData.randomNum2 + 1) % album.fetchResult.count
        }
//        dispatchAnimation {
            fetchingImage(imageNumber: 1, asset: album.fetchResult[number1],
                                         thumbNailSize: size)
            if album.fetchResult.count > 1 {
                fetchingImage(imageNumber: 2,
                              asset: album.fetchResult[number2],
                              thumbNailSize: size)
            }
//        }
    }
}

#Preview {
    AlbumCoverView(album: MLAlbum(isHome: true),
                   uiMode: .fancy,
                   cellType: .album,
                   size: CGSize(width: 100, height: 150),
                   colorIndex: 0,
                   albumCell: Namespace().wrappedValue,
                   isEditingMode: false)
        .environmentObject(MLPhotoData())
}

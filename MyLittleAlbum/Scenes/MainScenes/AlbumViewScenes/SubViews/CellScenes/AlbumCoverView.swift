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
    var sampleMLAlbum: MLAlbum! = nil
    var assetCollection: PHAssetCollection! = nil
    var uiMode: UIMode = .fancy
    let cellType: CellType
    let size: CGSize
    var colorIndex: Int = 0
    let spacing: CGFloat = 3
    var padding: CGFloat = 7
    let radius: CGFloat = 5
    var albumCell: Namespace.ID
        
    @State var rprstImage1: UIImage!
    @State var rprstImage2: UIImage!
    
    var body: some View {
        Group {
            switch assetCollection == nil ? uiMode : photoData.uiMode {
            case .classic: classicAlbumView { size in
                tempView(size: size) }
            case .modern: modernAlbumView { size in
                tempView(size: size) }
            case .fancy: fancyAlbumView { size in
                tempView(size: size) }
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
    func tempView(size: CGSize) -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .frame(width: size.width, height: size.height)
    }
    func classicAlbumView(tempView: @escaping (CGSize) -> some View) -> some View {
        VStack(spacing: 5) {
            GeometryReader { geoProxy in
                let innerSize = geoProxy.size
                if let album = (assetCollection == nil ? sampleMLAlbum : photoData
                    .albums[assetCollection?.localIdentifier ?? ""]) {
                    let count = !album.isSample
                                ? album.fetchResult.count
                                : (album.sampleCase.returnCount())
                    Group {
                        if count > 0 {
                            animationImageView(uiMode: .classic,
                                               size: innerSize,
                                               count: count)
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
                    .matchedGeometryEffect(id: "photo1", in: albumCell)
                } else {
                    tempView(innerSize)
                }
            }
            titleLabelView(uiMode: .classic, size: size, alignment: .center)
        }
        .cornerRadius(radius)
        .frame(width: size.width, height: size.height)
    }
    
    func modernAlbumView(tempView: @escaping (CGSize) -> some View) -> some View {
        ZStack(alignment: .bottom) {
            let labelHeight = size.height * 0.35
            Group {
                if let album = (assetCollection == nil ? sampleMLAlbum : photoData
                    .albums[assetCollection?.localIdentifier ?? ""]) {
                    let count = !album.isSample
                                ? album.fetchResult.count
                                : (album.sampleCase.returnCount())
                    if count != 0 {
                        animationImageView(uiMode: .modern, size: size, count: count)
                    } else {
                        emptyTextView(uiMode: .modern,
                                      width: size.width,
                                      height: size.height,
                                      bottomPadding: labelHeight)
                    }
                } else {
                    tempView(CGSize(width: size.width,
                                    height: size.height - labelHeight))
                        .padding(.bottom, labelHeight)
                }
            }
             titleLabelView(uiMode: .modern,
                           size: CGSize(width: size.width, height: labelHeight),
                           alignment: .leading)
        }
        .cornerRadius(radius)
    }
    
    func fancyAlbumView(tempView: @escaping (CGSize) -> some View) -> some View {
        VStack(alignment: .center, spacing: 5) {
            titleLabelView(uiMode: .fancy, size: size, alignment: .topLeading)
            GeometryReader { geoProxy in
                let innerWidth = geoProxy.size.width
                let innerHeight = geoProxy.size.height
                let firstWidth = (innerWidth - spacing) * 0.65
                let secondWidth = (innerWidth - spacing) * 0.35
                let album = assetCollection == nil ? sampleMLAlbum : photoData
                    .albums[assetCollection?.localIdentifier ?? ""]
                Group {
                    if let album = album {
                        let count = !album.isSample
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
                                } else {
                                    HStack(spacing: spacing) {
                                        animationImageView(
                                            uiMode: .fancy,
                                            size: CGSize(width: firstWidth,
                                                         height: innerHeight),
                                            count: count)
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
                    } else {
                        tempView(CGSize(width: innerWidth, height: innerHeight))
                    }
                }
                .animation(.easeOut, value: album != nil)
                .transition(.opacity)
            }
        }
        .padding(padding)
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
    //            .matchedGeometryEffect(id: isSecond ? "photo2" : "photo1", in: albumCell)
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
        let assetRatio = CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
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
        let album = sampleMLAlbum == nil ? photoData.albums[assetCollection?.localIdentifier ?? ""] : sampleMLAlbum
        let title = album?.title ?? "loading..."
        return Group {
            switch uiMode {
            case .classic:
                titleText(title, font: .caption, color: .orange, inline: true)
                    .bold()
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .padding(.horizontal, spacing)
                    .frame(width: size.width, alignment: alignment)
                    .matchedGeometryEffect(id: "title", in: albumCell)
            case .modern:
                ZStack(alignment: .leading) {
                    Color.white.opacity(0.88)
                        .transition(.opacity)
                        .matchedGeometryEffect(id: "titleBack", in: albumCell)
                        .offset(y: uiMode == .modern ? 0 : size.height )
                    titleText(title,
                              font: Font.system(cellType == .album
                                          ? .subheadline : .caption,
                                          weight: .semibold),
                              color: .fancyBackground,
                              inline: cellType == .album ? false : true)
                        .contentTransition(.numericText())
                        .lineLimit(cellType == .album ? 2 : 1,
                                   reservesSpace: true)
                        .lineSpacing(0.1)
                        .kerning(0.4)
                        .padding(.horizontal, padding)
                        .frame(width: size.width, alignment: alignment)
                        .matchedGeometryEffect(id: "title", in: albumCell)
                }
                .frame(height: size.height)
            case .fancy:
                titleText(title,
                          font: cellType == .album
                          ? .footnote.bold()
                          : .footnote,
                          color: .white,
                          inline: cellType == .album ? false : true)
                .contentTransition(.numericText())
                .lineLimit(cellType == .album ? 2 : 1, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, padding)
                .frame(width: size.width, alignment: alignment)
                .matchedGeometryEffect(id: "title", in: albumCell)
            }
        }
        .truncationMode(.tail)
        .opacity(album == nil ? 0.5 : 1)
        .animation(.easeInOut, value: album != nil)
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
        guard let album = photoData.albums[assetCollection.localIdentifier],
              album.fetchResult.count > 0
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
    AlbumCoverView(assetCollection: PHAssetCollection(),
                   cellType: .album,
                   size: CGSize(width: 100, height: 150),
                   albumCell: Namespace().wrappedValue)
        .environmentObject(MLPhotoData())
}

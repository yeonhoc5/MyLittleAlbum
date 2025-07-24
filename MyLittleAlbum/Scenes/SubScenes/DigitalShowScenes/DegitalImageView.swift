//
//  DegitalImageView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 8/30/24.
//

import SwiftUI
import Photos

struct DigitalImageView: View {
    let asset: MLAsset
    let animationDirection: [Edge]
    let showStatus: DigitalShowStatus
    let cachingManager: PHCachingImageManager
    let size: CGSize
    
    var body: some View {
        if let image  = fetchingImage(asset: asset.phAsset, size: size) {
            ZStack {
                backgroundView(image: image, size: size)
                Group {
                    if asset.mediaType == .image {
                        ImageDetailView(asset: asset,
                                        imageManager: cachingManager,
                                        size: size,
                                        enableZoom: false,
                                        variableScale: .constant(1),
                                        currentScale: .constant(1),
                                        offsetY: .constant(0))
                        .id(asset.id)
                    } else {
                        VideoDetailView(isDigitalShow: true,
                                        offsetIndex: 0,
                                        asset: asset,
                                        imageManager: cachingManager,
                                        size: size,
                                        play: .constant(.play),
                                        hideTools: .constant(true),
                                        userGesture: .constant(.none),
                                        offsetY: .constant(0),
                                        offsetX: .constant(0))
                        .id(asset.id)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: animationDirection[0]),
                    removal: .move(edge: animationDirection[1])
                ))
            }
        }
    }
    
    private func backgroundView(image: UIImage, size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .blur(radius: 30.0)
            .transition(.opacity)
            .id("backPoster")
    }
    
    func fetchingImage(asset: PHAsset, size: CGSize) -> UIImage? {
        let imageManager = PHCachingImageManager()
        let assetRatio = CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
        let screenRatio = size.height / size.width
        let widthIsCreteria = assetRatio <= screenRatio
        var returnImage: UIImage!
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        let creteriaSize = (widthIsCreteria
                     ? size.width : size.height) * scale
        let size = CGSize(
            width: widthIsCreteria ? creteriaSize : .infinity,
            height: widthIsCreteria ? .infinity : creteriaSize
        )
        
        imageManager.requestImage(for: asset,
                                  targetSize: size,
                                  contentMode: .aspectFit,
                                  options: options) { assetImage, _ in
            if let image = assetImage {
                returnImage = image
            }
        }
        return returnImage
    }
}
//#Preview {
//    DigitalShowView(nameSpace: Namespace().wrappedValue)
//}

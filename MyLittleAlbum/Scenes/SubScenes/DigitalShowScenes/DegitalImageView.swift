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
  let geometry: GeometryProxy
  
  var body: some View {
    if let image  = fetchingImage(asset: asset.phAsset, size: geometry.size) {
      ZStack {
        backgroundView(image: image, size: geometry.size)
        Group {
          if asset.mediaType == .image {
            ImageDetailView(asset: asset,
                            imageManager: cachingManager,
                            geometry: geometry,
                            tempView: {
              loadingView
            }, resutlMedia: { image in
              
            })
            .id(asset.id)
          } else {
            VideoDetailView(isDigitalShow: true,
                            offsetIndex: 0,
                            asset: asset,
                            imageManager: cachingManager,
                            geometry: geometry,
                            playStatus: .constant(.play),
                            videoMove: .constant(.none),
                            videoNeeds: .none,
                            play2x: false,
                            landscapeVideo: false,
                            hideTools: false,
                            userGesture: .constant(.none),
                            currentTime: .constant(0),
                            tempView: {
              loadingView
            })
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
  var loadingView: some View {
    ProgressView()
      .tint(.white)
      .controlSize(.large)
      .progressViewStyle(.circular)
      .scaleEffect(0.8)
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
    var returnImage: UIImage?
    let imageManager = PHCachingImageManager()
    let options = PHImageRequestOptions()
    options.deliveryMode = .opportunistic
    options.resizeMode = .exact
    options.isSynchronous = true
    options.isNetworkAccessAllowed = true

    let creteria = creteriaResult(
      screenSize: size,
      size: CGSize(width: asset.pixelWidth,
                   height: asset.pixelHeight)
    )
    let creteriaSize = (creteria == .width ? size.width : size.height) * scale
    let anotherSize: CGFloat = (
      creteria == .width
      ? (CGFloat(asset.pixelHeight) * size.width / CGFloat(asset.pixelWidth))
      : (CGFloat(asset.pixelWidth) * size.height / CGFloat(asset.pixelHeight))
    ) * scale
    let size = CGSize(width: creteria == .width
                      ? creteriaSize : anotherSize,
                      height: creteria == .height
                      ? creteriaSize : anotherSize)
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

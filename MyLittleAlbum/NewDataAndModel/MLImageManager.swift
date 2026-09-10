//
//  MLImageManager.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/2/25.
//

import SwiftUI
import Photos
import ImageIO

class MLImageManager {
  static let shared = MLImageManager()
  let manager = PHCachingImageManager()
  
  private init() {}
  
  func cachingImages(assets: [PHAsset], size: CGSize) {
    let options = PHImageRequestOptions()
    options.isSynchronous = false
    options.deliveryMode = .fastFormat
    options.resizeMode = .exact
    options.version = .current
    options.isNetworkAccessAllowed = true
    manager
      .startCachingImages(for: assets, targetSize: size, contentMode: .aspectFill, options: options)
  }
  
  func processImage(asset: PHAsset, pointSize: CGSize, scale: CGFloat) -> UIImage? {
    var result: UIImage!
    let options = PHImageRequestOptions()
    options.isSynchronous = false
    options.deliveryMode = .fastFormat
    options.resizeMode = .exact
    options.version = .current
    options.isNetworkAccessAllowed = true
    
    manager.requestImageDataAndOrientation(for: asset, options: options) { (imageData, dataUTI, orientation, info) in
      guard let imageData = imageData else {
        print("Could not get image data from PHAsset.")
        return
      }
      // downSampling or resizing
      guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return }
      let maxDimensionsInPixels = max(pointSize.width, pointSize.height) * scale
      let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionsInPixels
      ] as CFDictionary
      if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
        result = UIImage(cgImage: downsampledImage)
        print("image Sample Downed")
      } else {
        print("\(#function) -> downsampledImage exit")
        return
      }
    }
    return result
  }
}

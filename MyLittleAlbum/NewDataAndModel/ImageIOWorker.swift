//
//  ImageIOWorker.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/1/25.
//

import SwiftUI
import ImageIO

class ImageIOWorker {
    static let shared = ImageIOWorker()
    
    private init() {}
    
    func downsampling(data: Data, pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOption) else {
            print("\(#function) -> imageSource exit")
            return nil
        }

        let maxDimensionsInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionsInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            print("\(#function) -> downsampledImage exit")
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }

}

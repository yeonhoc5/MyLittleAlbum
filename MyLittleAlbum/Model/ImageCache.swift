//
//  ImageCache.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/19.
//

import Foundation
import UIKit
import Photos

public class ImageCache {
    public static let shared = ImageCache()
    private init() {}
    
    
    private var cachedImage = NSCache<String, UIImage>()
    
    func fetchAsset(asset: PHAsset) -> UIImage {
        if let fetchedImage = cachedImage.object(forKey: asset.localIdentifier) {
            return
        }
    }
    
}

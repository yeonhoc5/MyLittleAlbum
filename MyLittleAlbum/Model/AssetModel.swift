//
//  AssetModel.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/05.
//

import SwiftUI
import Photos

enum MediaSubType {
    case JPG, PNG, AVI, MP4, GIF
}

struct ImageStruct: Hashable {
    var id: UUID = UUID()
    var image: UIImage!
}

extension Asset: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(smallImage)
        hasher.combine(mediumImage)
        hasher.combine(largeImage)
    }
}

struct Asset: Identifiable {
    static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String
    var asset: PHAsset
    var mediaType: PHAssetMediaType
    var index: Int
    var subType: MediaSubType?
    
    @State var smallImage: ImageStruct!
    @State var mediumImage: ImageStruct!
    @State var largeImage: ImageStruct!
    
    init(asset: PHAsset, index: Int) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.mediaType = asset.mediaType
        self.index = index
    
//        self.subType = subType
        
//        let smallWidth = ((screenSize.width - 4.0) / 5) * scale
//        let mediumWidth = (screenSize.width - 40) * scale
//        self.smallImage = loadImage(asset: asset, thumbNailSize: CGSize(width: smallWidth, height: smallWidth))
//        self.mediumImage = loadImage(asset: asset, thumbNailSize: CGSize(width: mediumWidth, height: mediumWidth))
//        self.largeImage = loadImage(asset: asset, thumbNailSize: PHImageManagerMaximumSize)
    }

    
    func loadImage(size: ImageSize) {
        let imagesize: CGSize
        switch size {
        case .cellSize:
            let width = (screenSize.width - 4) / 5
            imagesize = CGSize(width: width, height: width)
        case .PreviewSize:
            let width = (screenSize.width - 40)
            imagesize = CGSize(width: width, height: width)
        case .DetailViewSize:
            let assetRatio = asset.pixelWidth / asset.pixelHeight
            let width = screenSize.width * 2
            let height = CGFloat(width) * CGFloat(assetRatio)
            imagesize = CGSize(width: width, height: height)
        }
        let imageManager = PHImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.version = .current
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .exact
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        imageManager.requestImage(for: asset, targetSize: imagesize, contentMode: .aspectFill, options: requestOptions) { image, _ in
            if let assetImage = image {
                switch size {
                case .cellSize: self.smallImage = ImageStruct(image: assetImage)
                case .PreviewSize: self.mediumImage = ImageStruct(image: assetImage)
                case .DetailViewSize: self.largeImage = ImageStruct(image: assetImage)
                }
            }
        }
    }
    
}

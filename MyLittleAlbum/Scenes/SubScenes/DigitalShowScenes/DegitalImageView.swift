//
//  DegitalImageView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 8/30/24.
//

import SwiftUI
import Photos

struct DigitalImageView: View {
    var asset: PHAsset
    var showStatus: DigitalShowStatus
    
    var body: some View {
        GeometryReader { proxy in
            let fetchedImage = self.fetchingImage(asset: asset,
                                                  size: proxy.size)
            if let image = fetchedImage {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width,
                               height: proxy.size.height)
                        .blur(radius: 30.0)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width,
                               height: proxy.size.height)
                        .transition(
                            .asymmetric(insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading))
                        )
                }
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
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
        let size = CGSize(width: widthIsCreteria ? creteriaSize : .infinity,
                          height: widthIsCreteria ? .infinity : creteriaSize)
        
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
#Preview {
    DigitalShowView(nameSpace: Namespace().wrappedValue)
}

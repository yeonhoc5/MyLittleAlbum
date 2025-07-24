//
//  PhotoThumbnailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/25/25.
//

import SwiftUI
import Photos

struct PhotoThumbnailView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @State var image: Image?
    private var asset: MLAsset
    let cachingManager: PHCachingImageManager
    let size: CGSize
    
    init(asset: MLAsset, cachingManager: PHCachingImageManager, size: CGSize) {
        self.asset = asset
        self.cachingManager = cachingManager
        self.size = size
    }
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Group {
                    if let preimage = preImage(asset: asset, size: size) {
                        Image(uiImage: preimage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                .task {
                    let targetSize = CGSize(width: size.width * scale,
                                            height: size.width * scale)
                    await loadImageAsset(targetSize: targetSize)
                }
            }
        }
        .frame(width: size.width, height: size.width)
        .clipped()
        .onDisappear {
            DispatchQueue.main.async {
                image = nil
            }
        }
    }
              
    func loadImageAsset(targetSize: CGSize) async {
        guard let uiImage = try? await fetchImage(
            asset: asset,
            targetSize: targetSize
            ) else {
                image = nil
                return
            }
        DispatchQueue.main.async {
            withAnimation {
                image = Image(uiImage: uiImage)
            }
        }
    }
    func fetchImage(
            asset: MLAsset,
            targetSize: CGSize = PHImageManagerMaximumSize,
            contentMode: PHImageContentMode = .aspectFill
    ) async throws -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
//        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        return try await withCheckedThrowingContinuation { continuation in
            /// Use the imageCachingManager to fetch the image
            self.cachingManager.requestImage(
                for: asset.phAsset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options,
                resultHandler: { image, info in
                    /// image is of type UIImage
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: image)
                }
            )
        }
    }
    
    func preImage(asset: MLAsset, size: CGSize) -> UIImage? {
        var uiimage: UIImage?
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .fastFormat
        requestOptions.resizeMode = .fast
//        requestOptions.deliveryMode = .opportunistic
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        cachingManager
            .requestImage(for: asset.phAsset,
                          targetSize: size,
                          contentMode: .aspectFill,
                          options: requestOptions,
                          resultHandler: { image, _ in
                if let returnImage = image {
                        uiimage = returnImage
                }
            })
        return uiimage
    }
    
}
//#Preview {
//    PhotoThumbnailView()
//}

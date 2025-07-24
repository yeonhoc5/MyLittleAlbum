//
//  NewDetailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/25/25.
//

import SwiftUI
import Photos

struct NewDetailView: View {
    let album: MLAlbum
    let imageCachingManager = PHCachingImageManager()
    
    var body: some View {
        GeometryReader { geometry in
            let rows = GridItem()
            LazyHGrid(rows: [rows]) {
                ForEach(album.frObject(isHiddenAsset: false)) { asset in
//                    Group {
//                        if let image = try? await fetchImage(asset: asset) {
//                            Image(uiImage: image)
//                        } else {
                            ProgressView()
                                .progressViewStyle(.circular)
//                        }
//                    }
                }
            }
        }
    }
    func fetchImage(
            asset: PHAsset,
            targetSize: CGSize = PHImageManagerMaximumSize,
            contentMode: PHImageContentMode = .aspectFill
    ) async throws -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        return try await withCheckedThrowingContinuation { continuation in
            /// Use the imageCachingManager to fetch the image
            self.imageCachingManager.requestImage(
                for: asset,
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
}

//#Preview {
//    NewDetailView()
//}

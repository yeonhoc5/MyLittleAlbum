//
//  PhotoLibraryService.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/25.
//

import Photos
import SwiftUI
import UIKit

class PhotoLibraryService: ObservableObject {
    
    var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var results = PHFetchResultCollection(fetchResult: .init())
    let imageCachingManager = PHCachingImageManager()
    
    func requestAuthorization() {
        if #available(iOS 14, *) {
            authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch authorizationStatus {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    switch status {
                    case .authorized, .limited:
                        self.fetchAllPhotos()
                    case .denied:
                        print("권한 요청이 거절되었습니다.")
                    default:
                        print("권한이 제한되었습니다.")
                    }
                }
            case .authorized:
                fetchAllPhotos()
            case .limited:
                print("limited1")
            case .restricted:
                print("restricted1")
            case .denied:
                print("denied1")
            @unknown default:
                fatalError()
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .notDetermined:
                print("notDetermined2")
            case .authorized:
                fetchAllPhotos()
            case .limited:
                print("limited2")
            case .restricted:
                print("restricted2")
            case .denied:
                print("denied2")
            @unknown default:
                fatalError()
            }
        }
    }
        
    private func fetchAllPhotos() {
            imageCachingManager.allowsCachingHighQualityImages = false
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = false
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            DispatchQueue.main.async {
                self.results.fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            }
        }

    
    func fetchImage(
            byLocalIdentifier localId: String,
            targetSize: CGSize = PHImageManagerMaximumSize,
            contentMode: PHImageContentMode = .default
        ) async throws -> UIImage? {
            let results = PHAsset.fetchAssets(
                withLocalIdentifiers: [localId],
                options: nil
            )
            guard let asset = results.firstObject else {
                return nil
            }
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true
            return try await withCheckedThrowingContinuation { continuation in
                self.imageCachingManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: contentMode,
                    options: options) { image, info in
                        if let error = info?[PHImageErrorKey] as? Error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: image)
                    }
            }
        }
}

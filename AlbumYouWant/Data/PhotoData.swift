//
//  PhotoData.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/27.
//

import Foundation
import Photos
import UIKit

class PhotoData: ObservableObject {
    
    @Published private var status: PHAuthorizationStatus!
    @Published var allPhotos = PHFetchResult<PHAsset>()
    @Published var topLevelCollection: PHFetchResult<PHCollection>!
    
    let imageCachingManager = PHCachingImageManager()
    
    init() {
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    switch status {
                    case .authorized, .limited:
                        self.fetchAllPhotos()
                        self.fetchTopLevelCollection()
                    case .denied:
                        print("권한 요청이 거절되었습니다.")
                    default:
                        print("권한이 제한되었습니다.")
                    }
                }
            case .authorized:
                fetchAllPhotos()
                fetchTopLevelCollection()
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
    
    func fetchAllPhotos() {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.includeHiddenAssets = true
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        DispatchQueue.main.async {
            self.allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        }
    }
    
    func fetchTopLevelCollection() {
        topLevelCollection = PHCollection.fetchTopLevelUserCollections(with: nil)
    }
    
}



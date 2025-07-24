//
//  MLAsset.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/4/25.
//

import SwiftUI
import Photos

extension PHAsset: @retroactive Identifiable { }

class MLAsset: NSObject, Identifiable, ObservableObject {
    var phAsset: PHAsset
    let id: String
    var creationDate: Date {
        get { phAsset.creationDate ?? Date() }
    }
    var mediaType: PHAssetMediaType {
        get { phAsset.mediaType }
    }
    var duration: TimeInterval {
        get { phAsset.duration }
    }
    var isHidden: Bool {
        get { phAsset.isHidden }
    }
    @Published var isFavorite: Bool
    
    var volume: CGFloat {
        get {
            return CGFloat(PHImageManager()
                .requestImageDataAndOrientation(for: phAsset, options: nil) { data, _, _, _ in
                    var imageSize = Float(data?.count ?? 0)
                    imageSize = imageSize/(1024*1024)
                })
        }
    }
    
    init(phAsset: PHAsset) {
        self.phAsset = phAsset
        self.id = phAsset.localIdentifier
        self.isFavorite = phAsset.isFavorite
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    override var hash: Int {
        return self.id.hashValue
    }
    override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? MLAsset {
            return self.id == rhs.id
        }
        return false
    }
    func favoriteAsset(bool: Bool, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: self.phAsset)
            request.isFavorite = bool
        } completionHandler: { bool, _ in
            if bool {
                let reNewAsset = PHAsset
                    .fetchAssets(withLocalIdentifiers: [self.id], options: nil)
                    .firstObject ?? self.phAsset
                DispatchQueue.main.async {
                    self.phAsset = reNewAsset
                    self.isFavorite = reNewAsset.isFavorite
                    completion(bool)
                }
            } else {
                completion(bool)
            }
        }
    }
}

extension MLAsset: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let change = changeInstance.changeDetails(for: self.phAsset) {
            if let after = change.objectAfterChanges {
                if self.isFavorite != after.isFavorite {
                    DispatchQueue.main.async {
                        self.phAsset = after
                        self.isFavorite = change.objectAfterChanges?.isFavorite ?? self.phAsset.isFavorite
//                        let object = ChangedItem(asset: [self], ass)
//                        NotificationCenter.default
//                            .post(name: .assetChanged, object: object)
                    }
                }
            }
        }
    }}

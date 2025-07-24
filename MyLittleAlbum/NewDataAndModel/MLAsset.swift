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
    let isAlbum: Bool
    var phAsset: PHAsset {
        didSet {
            DispatchQueue.main.async {
                withAnimation {
                    self.isFavorite = self.phAsset.isFavorite
                }
            }
        }
    }
    let id: String
    var mediaType: PHAssetMediaType {
        get { phAsset.mediaType }
    }
    var creationDate: Date {
        get { phAsset.creationDate ?? Date() }
    }
    var isHidden: Bool {
        get { phAsset.isHidden }
    }
    var duration: TimeInterval {
        get { phAsset.duration }
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
    
    init(phAsset: PHAsset, isAlbum: Bool) {
        self.phAsset = phAsset
        self.id = phAsset.localIdentifier
        self.isFavorite = phAsset.isFavorite
        self.isAlbum = isAlbum
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
    func favoriteAsset(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: self.phAsset)
            request.isFavorite = !self.isFavorite
        } completionHandler: { bool, _ in
            if bool {
                let reNewAsset = PHAsset
                    .fetchAssets(withLocalIdentifiers: [self.id], options: nil)
                    .firstObject ?? self.phAsset
                self.phAsset = reNewAsset
            }
            completion(bool)
        }
    }
}

extension MLAsset: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let change = changeInstance.changeDetails(for: self.phAsset) {
            if isAlbum {
                print("album detected change")
            }
            if let after = change.objectAfterChanges {
                if after.isFavorite != self.isFavorite {
                    print("detected at \(self.isAlbum ? "album" : "not album")")
                    DispatchQueue.main.async {
                        self.phAsset = after
                        self.isFavorite = change.objectAfterChanges?.isFavorite ?? self.phAsset.isFavorite
                        let object = ItemChangedView(id: "elsewhere", items: [self.id])
                        NotificationCenter.default
                            .post(name: .itemChanged, object: object)
                    }
                }
//                else {
//                    print("detected but favorite same")
//                }
            }
        }
    }}

//
//  MLAsset.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/4/25.
//

import SwiftUI
import Photos

extension PHAsset: @retroactive Identifiable { }

class MLAsset: NSObject, Identifiable, ObservableObject, @unchecked Sendable {
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
  var isFavorite: Bool {
    get { phAsset.isFavorite }
  }
  var isGif: Bool = false
  
  @Published var volume: Int64 = 0
  var albumsContains: [String] = []
  
  init(phAsset: PHAsset) {
    self.phAsset = phAsset
    self.id = phAsset.localIdentifier
    super.init()
    PHPhotoLibrary.shared().register(self)
  }
  init(id: String) {
    self.phAsset = PHAsset
      .fetchAssets(withLocalIdentifiers: [id], options: nil)
      .object(at: 0)
    self.id = id
    super.init()
    PHPhotoLibrary.shared().register(self)
  }
  
  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }
  func getFileSize(completion: @escaping (Bool) -> Void) {
    DispatchQueue.global(qos: .background).async {
      let resources = PHAssetResource.assetResources(for: self.phAsset)
      var sizeOnDisk: Int64 = 0
      if let resource = resources.first {
        let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
        sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
        //                let formatter:ByteCountFormatter = ByteCountFormatter()
        //                formatter.countStyle = .file
        //                formatter.allowedUnits = [.useMB]
        //                return Self.bcf.string(fromByteCount: sizeOnDisk)
        self.volume = sizeOnDisk
        completion(true)
      } else {
        self.volume = 0
        completion(false)
      }
    }
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
}

extension MLAsset {
  func favoriteAsset(toFavorite: Bool, completion: @escaping (Bool) -> Void) {
    PHPhotoLibrary.shared().performChanges {
      let request = PHAssetChangeRequest(for: self.phAsset)
      request.isFavorite = toFavorite
    } completionHandler: { bool, _ in
      if bool {
        let reNewAsset = PHAsset
          .fetchAssets(withLocalIdentifiers: [self.id], options: nil)
          .firstObject ?? self.phAsset
        DispatchQueue.main.async {
          self.phAsset = reNewAsset
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
    if let change = changeInstance.changeDetails(for: self.phAsset),
       let after = change.objectAfterChanges {
      if self.isFavorite != after.isFavorite {
        DispatchQueue.main.async {
          self.phAsset = after
          //                        self.isFavorite = after.isFavorite
          //                        let object = ChangedItem(asset: [self], ass)
          //                        NotificationCenter.default
          //                            .post(name: .assetChanged, object: object)
        }
      }
    }
  }
}

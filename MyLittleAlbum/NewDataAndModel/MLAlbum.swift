//
//  MLAlbum.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/3/25.
//

import SwiftUI
import Photos

extension PHAssetCollection: @retroactive Identifiable {}

struct RprstImage {
    let width: CGFloat
    let image: Image
}

class MLAlbum: NSObject, Identifiable, ObservableObject, Observable {
//    let isTop: Bool
    // 1. 로딩
    var isSample: Bool = false
    var sampleCase: SampleCase = .none
    let id: String
    @Published var phAssetCollection: PHAssetCollection!
    var smartType: PHAssetCollectionSubtype!
    @Published var isPrivacy: Bool = false
    @Published var title: String
    // 2. 미디어
    @Published var fetchResult: PHFetchResult<PHAsset>
    @Published var hiddenFetchResult: PHFetchResult<PHAsset>!
    @Published var photosArray: [MLAsset] = []
    @Published var hiddenArray: [MLAsset] = []
    
    // 유저 앨범용 init
    init(assetCollection: PHAssetCollection) {
        self.id = assetCollection.localIdentifier
        self.phAssetCollection = assetCollection
        self.title = assetCollection.localizedTitle ?? ""
        self.fetchResult = PHAsset
            .fetchAssets(in: assetCollection, options: nil)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    // smart 앨범용 init
    init(assetCollection: PHAssetCollection, title: String, isPrivacy: Bool = false) {
        self.id = assetCollection.localIdentifier
        self.phAssetCollection = assetCollection
        self.title = title
        self.isPrivacy = isPrivacy
        if !isPrivacy {
            fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        } else {
            fetchResult = PHFetchResult()
            hiddenFetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        }
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    // Photos용 init
    init(isHome: Bool) {
        self.id = "myPhotos"
        self.title = "나의 사진"
        self.fetchResult = PHAsset.fetchAssets(with: nil)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    // sample용
    init(sampleID: Int, sampleCase: SampleCase) {
        self.isSample = true
        self.sampleCase = sampleCase
        self.id = "album\(sampleID)"
        self.title = "앨범\(sampleID)"
        self.fetchResult = PHFetchResult()
        super.init()
    }
    deinit {
        if !isSample {
            print("deinited Album : \(self.title)")
        }
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func generateArray(isHiddenAsset: Bool, completion: @escaping () -> Void) {
        if !isHiddenAsset {
            DispatchQueue.main.async { [unowned self] in
                withAnimation {
                    self.photosArray = self.fetchResult
                        .objects(at: IndexSet(integersIn: 0..<self.fetchResult.count))
                        .sorted(by: { $0.creationDate ?? Date() < $1.creationDate ?? Date() })
                        .map { MLAsset(phAsset: $0, isAlbum: self.phAssetCollection != nil) }
                    print("photos generated")
                    completion()
                }
            }
        } else {
            DispatchQueue.main.async { [unowned self] in
                withAnimation {
                    self.hiddenArray = self.hiddenFetchResult
                        .objects(at: IndexSet(integersIn: 0..<self.hiddenFetchResult.count))
                        .filter { $0.isHidden }
                        .sorted(by: { $0.creationDate ?? Date() < $1.creationDate ?? Date() })
                        .map { MLAsset(phAsset: $0, isAlbum: self.phAssetCollection != nil) }
                    print("hidden photos generated")
                    completion()
                }
            }
        }
    }
    func mlAsset() -> [MLAsset] {
        return self.fetchResult
            .objects(at: IndexSet(integersIn: 0..<self.fetchResult.count))
            .map { MLAsset(phAsset: $0, isAlbum: self.phAssetCollection != nil) }
    }
}
// MARK: - 1. setting Album
extension MLAlbum {
    func setHiddenAsset(completion: @escaping (Int) -> Void) {
        let options = PHFetchOptions()
        options.includeHiddenAssets = true
        options.wantsIncrementalChangeDetails = true
        let reFetchResult = PHAsset
            .fetchAssets(in: self.phAssetCollection, options: options)
        DispatchQueue.main.async {
            self.hiddenFetchResult = reFetchResult
        }
        let result = reFetchResult
            .objects(at: IndexSet(integersIn: 0..<reFetchResult.count))
            .filter { $0.isHidden == true }
        completion(result.count)
    }
    func unSetHiddenAssets(result: @escaping () -> Void) {
        DispatchQueue.main.async { [unowned self] in
//            self.hiddenArray = []
            self.hiddenFetchResult = nil
            result()
        }
    }
}

// MARK: - 2. 미디어 처리 함수
extension MLAlbum {
    // 앨범 타이블 수정
    func modifyAlbumTitle(newName: String, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: self.phAssetCollection) else { return }
            request.title = newName
        } completionHandler: { [unowned self] bool, _ in
            if bool {
                DispatchQueue.main.async {
                    withAnimation {
                        self.title = newName
                    }
                }
                print("album [\(self.title)] Name is Changed")
            }
            completion(bool)
        }
    }
    // user 앨범에서만 사용
    func addAsset(assets: [MLAsset],
                  completion: (@escaping (Bool) -> Void)) {
        guard let assetCollection = self.phAssetCollection else { return }
        PHPhotoLibrary.shared()
            .performChanges {
                PHAssetCollectionChangeRequest(
                    for: assetCollection,
                    assets: self.fetchResult)?
                    .addAssets(assets.compactMap { $0.phAsset } as NSFastEnumeration)
            } completionHandler: { [unowned self] bool, _ in
                if bool {
                    DispatchQueue.main.async {
                        self.fetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: nil)
                        self.photosArray = Array(
                            Set(self.photosArray).union(Set(assets))
                        )
                        .sorted(by: { $0.creationDate < $1.creationDate })
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default
                                .post(name: .innerFetchChange, object: self.id)
                            NotificationCenter.default
                                .post(name: .changeRprstPhotos, object: self.id)
                        }
                    }
                }
                completion(bool)
            }
    }
    // user 앨범에서만 사용
    func removeAssetFromAlbum(assets: [MLAsset],
                              isHidden: Bool = false,
                              filteringType: FilteringType = .all,
                              completion: @escaping (Bool) -> Void) {
        let options = PHFetchOptions()
        options.includeHiddenAssets = isHidden
        let checkFetchResult = !isHidden ? self.fetchResult : PHAsset
            .fetchAssets(in: self.phAssetCollection,
                         options: options)
        PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest(for: self.phAssetCollection,
                                           assets: checkFetchResult)?
                .removeAssets(assets.compactMap { $0.phAsset } as NSFastEnumeration)
        } completionHandler: { [unowned self] bool, _ in
            if bool {
                DispatchQueue.main.async {
                    if !isHidden {
                        self.fetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: nil)
                        self.photosArray = Array(
                            Set(self.photosArray).subtracting(Set(assets))
                        )
                        .sorted(by: { $0.creationDate < $1.creationDate })
                        NotificationCenter.default
                            .post(name: .changeRprstPhotos, object: self.id)
                    } else {
                        self.hiddenFetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: options)
                        self.hiddenArray = Array(
                            Set(self.hiddenArray).subtracting(Set(assets))
                        )
                        .sorted(by: { $0.creationDate < $1.creationDate })
                    }
                }
                completion(bool)
            } else {
                completion(bool)
            }
        }
    }
    // 기기에서 삭제하기
    func deleteAssetFromDevice(albumType: AlbumType = .album,
                               assets: [MLAsset],
                               isHiddenAsset: Bool = false,
                               isDetailView: Bool = false,
                               completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest
                .deleteAssets(assets.compactMap { $0.phAsset } as NSFastEnumeration)
        } completionHandler: { [unowned self] bool, _ in
            if bool {
                DispatchQueue.main.async {
                    if !isHiddenAsset {
                        if let assetCollection = self.phAssetCollection {
                            self.fetchResult = PHAsset
                                .fetchAssets(in: assetCollection, options: nil)
                        } else {
                            self.fetchResult = PHAsset.fetchAssets(with: nil)
                        }
                        self.photosArray = Array(
                            Set(self.photosArray).subtracting(Set(assets))
                        )
                        .sorted(by: { $0.creationDate < $1.creationDate })
                        NotificationCenter.default
                            .post(name: .changeRprstPhotos, object: self.id)
                    } else {
                        let options = PHFetchOptions()
                        options.includeHiddenAssets = true
                        self.hiddenFetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: options)
                        self.hiddenArray = Array(Set(self.hiddenArray)
                            .subtracting(Set(assets)))
                        .sorted(by: { $0.creationDate < $1.creationDate })
                    }
                    completion(bool)
                }
            } else {
                completion(bool)
            }
        }
    }
    // 가리기 & 해제하기 {
    func hideOrUnhideAsset(assets: [MLAsset],
                           toHide: Bool,
                           isDetailView: Bool = false,
                           completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            assets.forEach { asset in
                let request = PHAssetChangeRequest(for: asset.phAsset)
                request.isHidden = toHide
            }
        } completionHandler: { [unowned self] bool, _ in
            if bool {
                DispatchQueue.main.async {
                    if let assetCollection = self.phAssetCollection {
                        self.fetchResult = PHAsset
                            .fetchAssets(in: assetCollection, options: nil)
                    } else {
                        self.fetchResult = PHAsset.fetchAssets(with: nil)
                    }
                    self.generateArray(isHiddenAsset: false) {
                        NotificationCenter.default
                            .post(name: .changeRprstPhotos, object: self.id)
                    }
                    if !toHide {
                        let options = PHFetchOptions()
                        options.includeHiddenAssets = true
                        self.hiddenFetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: options)
                        self.hiddenArray = Array(
                            Set(self.hiddenArray).subtracting(Set(assets))
                        )
                        .sorted(by: { $0.creationDate < $1.creationDate })
                    }
                }
            }
            completion(bool)
        }
    }
    
    func favoriteAsset(toFavorite: Bool,
                       assets: [MLAsset],
                       isHiddenAsset: Bool,
                       completion: @escaping (Bool) -> Void) {
        var count = 0
        assets.forEach { asset in
            asset.favoriteAsset { bool in
                count += 1
                if count == assets.count {
                    completion(true)
                }
            }
        }
    }
}

extension MLAlbum {
    
    func frObject(isHiddenAsset: Bool) -> [MLAsset] {
        let object = !isHiddenAsset ? self.fetchResult : self.hiddenFetchResult
        let result = (object ?? PHFetchResult<PHAsset>())
            .objects(at: IndexSet(integersIn: 0..<(object ?? self.fetchResult).count))
            .map({ MLAsset(phAsset: $0, isAlbum: self.phAssetCollection != nil)})
            .filter {
                isHiddenAsset ? $0.isHidden : true
            }
            .sorted(by: { $0.creationDate < $1.creationDate })
        return result
    }
    func frCount(fr1: PHFetchResult<PHAsset>, fr2: PHFetchResult<PHAsset>! = nil) -> Int {
        if fr2 == nil {
            return fr1.objects(at: IndexSet(integersIn: 0..<fr1.count)).count
        } else {
            return Set(fr1.objects(at: IndexSet(integersIn: 0..<fr1.count)))
                .subtracting(Set(fr2.objects(at: IndexSet(integersIn: 0..<fr2.count))))
                .count
        }
    }
    func subtractingArray(isHiddenAsset: Bool,
                          subtracting: [MLAsset]) -> [MLAsset] {
        let assets = frObject(isHiddenAsset: isHiddenAsset)
        let set = Set(assets).subtracting(Set(subtracting))
        return Array(set)
    }
    func intersectingArray(isHiddenAsset: Bool,
                           intersecting: [MLAsset]) -> [MLAsset] {
        let assets = frObject(isHiddenAsset: isHiddenAsset)
        let set = Set(assets).intersection(Set(intersecting))
        return Array(set)
    }
}

// MARK: - 3. album Change Observer
extension MLAlbum: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if self.phAssetCollection != nil {
            if let album = changeInstance.changeDetails(for: self.phAssetCollection) {
                if album.objectAfterChanges?.localizedTitle != self.title {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.title = album.objectAfterChanges?.localizedTitle ?? self.title
                        }
                    }
                }
            }
        }
        if let newFetch = changeInstance.changeDetails(for: self.fetchResult) {
            if self.fetchResult != newFetch.fetchResultAfterChanges {
                print("fetch changed [\(title)]")
                DispatchQueue.main.async {
                    self.fetchResult = newFetch.fetchResultAfterChanges
                }
                if self.photosArray.count != newFetch.fetchResultAfterChanges.count {
                    print("outside fetch \(self.title)")
                    DispatchQueue.main.async { [unowned self] in
                        self.generateArray(isHiddenAsset: false,
                                           completion: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [unowned self] in
                                NotificationCenter.default
                                    .post(name: .outsideFetchChange, object: self.id)
                                NotificationCenter.default
                                    .post(name: .changeRprstPhotos, object: self.id)
                            }
                        })
                    }
                } else {
                    for asset in newFetch.changedObjects {
//                        if let index = self.photosArray
//                            .compactMap ({ $0.phAsset })
//                            .firstIndex(of: asset) {
//                            DispatchQueue.main.async { [unowned self] in
//                                withAnimation {
//                                    self.photosArray
//                                        .replace([self.photosArray[index]],
//                                                 with: [MLAsset(phAsset: asset, isAlbum: self.phAssetCollection != nil )])
//                                    self.photosArray.remove(at: index)
//                                    self.photosArray.insert(MLAsset(phAsset: asset, isAlbum: self.phAssetCollection != nil),
//                                                            at: index)
//                                }
//                            }
//                        }
                    }

                }
            }
        }
        
        if let hiddenFetch = self.hiddenFetchResult,
           let newFetch = changeInstance.changeDetails(for: hiddenFetch) {
            if hiddenFetch != newFetch.fetchResultAfterChanges {
                if hiddenFetch.count != newFetch.fetchResultAfterChanges.count {
                    DispatchQueue.main.async { [unowned self] in
                        self.hiddenFetchResult = newFetch.fetchResultAfterChanges
                        self.generateArray(isHiddenAsset: true, completion: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default
                                    .post(name: .outsideFetchChange, object: self.id)
                            }
                        })
                    }
                }
            }
        }
    }
}

struct NewFetchObject {
    let identifier: String
    let inserted: [PHAsset]
    let removed: [PHAsset]
}

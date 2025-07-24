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
    // 1. 로딩
    let sampleCase: SampleCase
    let id: String
    @Published var phAssetCollection: PHAssetCollection!
    var smartType: PHAssetCollectionSubtype!
    @Published var isPrivacy: Bool = false
    @Published var title: String
    // 2. 미디어
    @Published var fetchResult: PHFetchResult<PHAsset>
    @Published var photosArray: [MLAsset] = []
    @Published var hiddenFetchResult = PHFetchResult<PHAsset>()
    @Published var hiddenArray: [MLAsset] = []
    @Published var innerProcessing: Bool = false
    
    // 유저 앨범용 init
    init(assetCollection: PHAssetCollection) {
        self.sampleCase = .none
        self.id = assetCollection.localIdentifier
        self.phAssetCollection = assetCollection
        self.title = assetCollection.localizedTitle ?? ""
        let option = PHFetchOptions()
        option.wantsIncrementalChangeDetails = true
        self.fetchResult = PHAsset
            .fetchAssets(in: assetCollection, options: option)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    // smart 앨범용 init
    init(assetCollection: PHAssetCollection, title: String, isPrivacy: Bool = false) {
        self.sampleCase = .none
        self.id = assetCollection.localIdentifier
        self.phAssetCollection = assetCollection
        self.title = title
        self.isPrivacy = isPrivacy
        let option = PHFetchOptions()
        option.wantsIncrementalChangeDetails = true
        if !isPrivacy {
            fetchResult = PHAsset.fetchAssets(in: assetCollection, options: option)
        } else {
            fetchResult = PHFetchResult()
            hiddenFetchResult = PHAsset.fetchAssets(in: assetCollection, options: option)
        }
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    // Photos용 init
    init(isHome: Bool) {
        self.sampleCase = .none
        self.id = "myPhotos"
        self.title = "나의 사진"
        let option = PHFetchOptions()
        option.wantsIncrementalChangeDetails = true
        self.fetchResult = PHAsset.fetchAssets(with: option)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    // sample용
    init(sampleID: Int, sampleCase: SampleCase) {
        self.sampleCase = sampleCase
        self.id = "album\(sampleID)"
        self.title = "앨범\(sampleID)"
        self.fetchResult = PHFetchResult()
        super.init()
    }
    deinit {
        if sampleCase != .none {
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
                        .map { MLAsset(phAsset: $0) }
                    print("[\(title)] photos generated")
                    completion()
                }
            }
        } else {
            DispatchQueue.main.async { [unowned self] in
                withAnimation {
                    self.hiddenArray = self.hiddenFetchResult
                        .objects(at: IndexSet(integersIn: 0..<self.hiddenFetchResult.count))
                        .filter { $0.isHidden }
                        .map { MLAsset(phAsset: $0) }
                    print("[\(title)] hidden photos generated")
                    completion()
                }
            }
        }
    }
    func mlAsset() -> [MLAsset] {
        return self.fetchResult
            .objects(at: IndexSet(integersIn: 0..<self.fetchResult.count))
            .map { MLAsset(phAsset: $0) }
    }
    func processingChange(bool: Bool) {
        DispatchQueue.main.async {
            withAnimation {
                self.innerProcessing = bool
            }
        }
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
            self.hiddenArray = []
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
        // 선작업
        DispatchQueue.main.async {
            withAnimation {
                self.photosArray = self.operatedArray(
                                    isHiddenAsset: false,
                                    setOperation: .union,
                                    assets: assets
                                )
            }
        }
        // 후 처리
        PHPhotoLibrary.shared()
            .performChanges {
                PHAssetCollectionChangeRequest(for: assetCollection,
                                                             assets: self.fetchResult)?
                    .addAssets(assets.compactMap { $0.phAsset } as NSFastEnumeration)
            } completionHandler: { [unowned self] bool, _ in
                if bool {
                    let option = PHFetchOptions()
                    option.wantsIncrementalChangeDetails = true
                    DispatchQueue.main.async {
                        withAnimation {
                            self.fetchResult = PHAsset
                                .fetchAssets(in: self.phAssetCollection, options: option)
                        }
                        completion(bool)
                    }
                } else {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.photosArray = self.operatedArray(
                                                isHiddenAsset: false,
                                                setOperation: .subtraction,
                                                assets: assets)
                        }
                        completion(bool)
                    }
                }
            }
    }
    // user 앨범에서만 사용
    func removeAssetFromAlbum(assets: [MLAsset],
                              isHidden: Bool = false,
                              filteringType: FilteringType = .all,
                              completion: @escaping (Bool) -> Void) {
        // 선 작업
        DispatchQueue.main.async {
            if !isHidden {
                self.photosArray = self.operatedArray(
                                    isHiddenAsset: false,
                                    setOperation: .subtraction,
                                    assets: assets)
            } else {
                self.hiddenArray = self.operatedArray(
                                    isHiddenAsset: true,
                                    setOperation: .subtraction,
                                    assets: assets)
            }
        }
        // 후 처리
        let checkFetchResult = !isHidden ? self.fetchResult : hiddenFetchResult
        PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest(for: self.phAssetCollection,
                                           assets: checkFetchResult)?
                .removeAssets(assets.compactMap { $0.phAsset } as NSFastEnumeration)
        } completionHandler: { [unowned self] bool, _ in
            if bool {
                let option = PHFetchOptions()
                option.wantsIncrementalChangeDetails = true
                option.includeHiddenAssets = isHidden
                DispatchQueue.main.async {
                    if !isHidden {
                        self.fetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: option)
                    } else {
                        self.hiddenFetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: option)
                    }
                }
            } else {
                if !isHidden {
                    self.photosArray = self.operatedArray(
                                        isHiddenAsset: false,
                                        setOperation: .union,
                                        assets: assets)
                } else {
                    self.hiddenArray = self.operatedArray(
                                        isHiddenAsset: true,
                                        setOperation: .union,
                                        assets: assets)
                }
            }
            completion(bool)
        }
    }
    // 기기에서 삭제하기
    func deleteAssetFromDevice(albumType: AlbumType = .album,
                               assets: [MLAsset],
                               isHiddenAsset: Bool = false,
                               isDetailView: Bool = false,
                               completion: @escaping (Bool) -> Void) {
        // 선 작업
        DispatchQueue.main.async {
            if !isHiddenAsset {
                self.photosArray = self.operatedArray(
                                    isHiddenAsset: false,
                                    setOperation: .subtraction,
                                    assets: assets)
            } else {
                self.hiddenArray = self.operatedArray(
                                    isHiddenAsset: true,
                                    setOperation: .subtraction,
                                    assets: assets)
            }
        }
        // 후 처리
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest
                .deleteAssets(assets.compactMap { $0.phAsset } as NSFastEnumeration)
        } completionHandler: { [unowned self] bool, _ in
            if bool {
                let option = PHFetchOptions()
                option.wantsIncrementalChangeDetails = true
                option.includeHiddenAssets = isHiddenAsset
                DispatchQueue.main.async {
                    if !isHiddenAsset {
                        if let assetCollection = self.phAssetCollection {
                            self.fetchResult = PHAsset
                                .fetchAssets(in: assetCollection, options: option)
                        } else {
                            self.fetchResult = PHAsset.fetchAssets(with: option)
                        }
                        NotificationCenter.default
                            .post(name: .changeRprstPhotos, object: self.id)
                    } else {
                        self.hiddenFetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: option)
                    }
                    completion(bool)
                }
            } else {
                DispatchQueue.main.async {
                    if !isHiddenAsset {
                        self.photosArray = self.operatedArray(
                                            isHiddenAsset: false,
                                            setOperation: .union,
                                            assets: assets)
                    } else {
                        self.hiddenArray = self.operatedArray(
                                            isHiddenAsset: true,
                                            setOperation: .union,
                                            assets: assets)
                    }
                }
                completion(bool)
            }
        }
    }
    // 가리기 & 해제하기 {
    func hideOrUnhideAsset(assets: [MLAsset],
                           toHide: Bool,
                           isDetailView: Bool = false,
                           completion: @escaping (Bool) -> Void) {
        // 선 작업
        DispatchQueue.main.async {
            if toHide {
                self.photosArray = self.operatedArray(
                    isHiddenAsset: false,
                    setOperation: .subtraction,
                    assets: assets)
            } else {
                self.hiddenArray = self.operatedArray(
                    isHiddenAsset: true,
                    setOperation: .subtraction,
                    assets: assets)
            }
        }
        // 후 처리
        PHPhotoLibrary.shared().performChanges {
            assets.forEach { asset in
                let request = PHAssetChangeRequest(for: asset.phAsset)
                request.isHidden = toHide
            }
        } completionHandler: { [unowned self] bool, _ in
            if bool {
                let option = PHFetchOptions()
                option.wantsIncrementalChangeDetails = true
                DispatchQueue.main.async {
                    option.includeHiddenAssets = false
                    if let assetCollection = self.phAssetCollection {
                        self.fetchResult = PHAsset
                            .fetchAssets(in: assetCollection, options: option)
                    } else {
                        self.fetchResult = PHAsset.fetchAssets(with: option)
                    }
                    if !toHide {
                        option.includeHiddenAssets = true
                        self.hiddenFetchResult = PHAsset
                            .fetchAssets(in: self.phAssetCollection, options: option)
                    }
                    completion(bool)
                }
            } else {
                if toHide {
                    self.photosArray = self.operatedArray(
                        isHiddenAsset: false,
                        setOperation: .union,
                        assets: assets)
                } else {
                    self.hiddenArray = self.operatedArray(
                        isHiddenAsset: true,
                        setOperation: .union,
                        assets: assets)
                }
                completion(bool)
            }
        }
    }
    
    func favoriteAsset(toFavorite: Bool,
                       assets: [MLAsset],
                       isHiddenAsset: Bool,
                       completion: @escaping (Bool) -> Void) {
        var count = 0
        assets.forEach { asset in
            asset.favoriteAsset(bool: toFavorite) { bool in
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
        let result = object
            .objects(at: IndexSet(integersIn: 0..<object.count))
            .map({ MLAsset(phAsset: $0)})
            .filter {
                isHiddenAsset ? $0.isHidden : true
            }
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
    
    func operatedArray(isHiddenAsset: Bool,
                       setOperation: SetOpertation,
                       assets: [MLAsset]) -> [MLAsset] {
        var set = Set(isHiddenAsset ? self.hiddenArray : self.photosArray)
        switch setOperation {
        case .union:
            set = set.union(Set(assets))
        case .intersection:
            set = set.intersection(Set(assets))
        case .subtraction:
            set = set.subtracting(Set(assets))
        }
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
                print("album Observer [\(title)] : fetch changed")
                if !innerProcessing {
                    DispatchQueue.main.async {
                        self.fetchResult = newFetch.fetchResultAfterChanges
                    }
                    if newFetch.hasIncrementalChanges {
                        if newFetch.fetchResultAfterChanges.count != self.photosArray.count {
                            self.generateArray(isHiddenAsset: false) {
                                NotificationCenter.default
                                    .post(name: .outsideFetchChange, object: self.id)
                                NotificationCenter.default
                                    .post(name: .changeRprstPhotos, object: self.id)
                                if self.phAssetCollection == nil {
                                    NotificationCenter.default
                                        .post(name: .outsideFetchChange, object: "picker")
                                }
                            }
                        }
//                        } else {
//                            if newFetch.changedObjects.count > 0 {
//                                let items = newFetch.changedObjects.map({ MLAsset(phAsset: $0) })
//                                let object = ChangedItem(assets: items,
//                                                         albumType: self.phAssetCollection == nil ? .home : (self.smartType == nil ? .album : .smartAlbum))
//                                DispatchQueue.main.async {
//                                    NotificationCenter.default
//                                        .post(name: .assetChanged, object: object)
//                                }
//                            }
//                        }
                    }
                    
                    
//                        print("album Observer [\(title)]: has inscrementalChanges")
//                        if !newFetch.insertedObjects.isEmpty {
//                            print("album Observer [\(title)]: [inserted] \(newFetch.insertedObjects.count)")
//                            let array = self.photosArray.compactMap({ $0.phAsset })
//                            for asset in newFetch.insertedObjects {
//                                if !array.contains(asset) {
//                                    let newAsset = MLAsset(phAsset: asset)
//                                    DispatchQueue.main.async {
//                                        withAnimation {
//                                            self.photosArray.append(newAsset)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                        if !newFetch.removedObjects.isEmpty {
//                            print("album Observer [\(title)]: [removed] \(newFetch.removedObjects.count)")
//                            let array = self.photosArray.compactMap({ $0.phAsset })
//                            var indexs: [Int] = []
//                            for asset in newFetch.removedObjects {
//                                if let index = array.firstIndex(of: asset) {
//                                    indexs.append(index)
//                                }
//                            }
//                            indexs = indexs.sorted(by: { $0 > $1 })
//                            for index in indexs {
//                                DispatchQueue.main.async {
//                                    withAnimation {
//                                        let _ = self.photosArray.remove(at: index)
//                                    }
//                                }
//                            }
//                        }
//                    }
                }
            }
            
        }
        if let newFetch = changeInstance.changeDetails(for: hiddenFetchResult) {
            if self.hiddenFetchResult != newFetch.fetchResultAfterChanges {
                if newFetch.hasIncrementalChanges {
                    if !innerProcessing {
                        DispatchQueue.main.async { [unowned self] in
                            self.hiddenFetchResult = newFetch.fetchResultAfterChanges
                            self.generateArray(isHiddenAsset: true) {
                                NotificationCenter.default
                                    .post(name: .outsideFetchChange, object: self.id)
                                NotificationCenter.default
                                    .post(name: .changeRprstPhotos, object: self.id)
                            }
                        }
                    }
                }
            }
        }
    }
}

// homeAlbum 작업
extension MLAlbum {
    // 1. 앨범에 넣음
    func subtractingAssets(assets: [MLAsset]) {
        DispatchQueue.main.async {
            self.photosArray = Array(
                Set(self.photosArray).subtracting(Set(assets))
            )
        }
    }
}

struct NewFetchObject {
    let identifier: String
    let inserted: [PHAsset]
    let removed: [PHAsset]
}

enum SetOpertation {
    case union, intersection, subtraction
}

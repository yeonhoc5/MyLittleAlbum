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

enum AssetHandeling {
  case deleteOnDevice, hide, unHide, addtoAlbum, removeFromAlbum, moveToOtherAlbum, favorite, unFavorite
}

class MLAlbum: NSObject, Identifiable, ObservableObject, Observable {
  // 1. 로딩
  let sampleCase: SampleCase
  let id: String
  @Published var phAssetCollection: PHAssetCollection!
  let albumType: AlbumType
  let smartAlbumType: SmartType
  let isPrivacy: Bool
  @Published var title: String
  // 2. 미디어
  @Published var fetchResult: PHFetchResult<PHAsset>
  @Published var photosArray: [MLAsset] = []
  @Published var hiddenFetchResult = PHFetchResult<PHAsset>()
  @Published var hiddenArray: [MLAsset] = []
  @Published var innerProcessing: Bool = false
  @Published var fetChanged: Bool = false
  
  @Published var rprstPhotos1: UIImage!
  @Published var rprstPhotos2: UIImage!
  
  // 유저 앨범용 init
  init(assetCollection: PHAssetCollection,
       albumType: AlbumType = .album) {
    self.sampleCase = .none
    self.id = assetCollection.localIdentifier
    self.phAssetCollection = assetCollection
    self.albumType = albumType
    self.smartAlbumType = .none
    self.isPrivacy = false
    self.title = assetCollection.localizedTitle ?? ""
    let option = PHFetchOptions()
    option.wantsIncrementalChangeDetails = true
    self.fetchResult = PHAsset
      .fetchAssets(in: assetCollection, options: option)
    super.init()
    PHPhotoLibrary.shared().register(self)
    self.generateArray(isHidden: false) {
      
    }
  }
  // smart 앨범용 init
  init(assetCollection: PHAssetCollection,
       smartAlbumType: SmartType,
       title: String,
       isPrivacy: Bool = false) {
    self.sampleCase = .none
    self.id = assetCollection.localIdentifier
    self.phAssetCollection = assetCollection
    self.albumType = .share
    self.smartAlbumType = smartAlbumType
    self.isPrivacy = isPrivacy
    self.title = title
    let option = PHFetchOptions()
    option.wantsIncrementalChangeDetails = true
    if !isPrivacy {
      fetchResult = PHAsset
        .fetchAssets(in: assetCollection, options: option)
    } else {
      fetchResult = PHFetchResult<PHAsset>()
      hiddenFetchResult = PHAsset
        .fetchAssets(in: assetCollection, options: option)
    }
    super.init()
    PHPhotoLibrary.shared().register(self)
  }
  // Photos용 init
  init(isHome: Bool) {
    // [사진 전체]와 [가려진 사진] 공동 처리
    // - PHAssetCollection + id는 [가려진 사진]으로 등록
    let hiddenAssetCollection = PHAssetCollection
      .fetchAssetCollections(with: .smartAlbum,
                             subtype: .smartAlbumAllHidden,
                             options: nil)
      .firstObject!
    self.phAssetCollection = hiddenAssetCollection
    self.sampleCase = .none
    self.id = hiddenAssetCollection.localIdentifier
    self.title = "나의 사진"
    self.albumType = .home
    self.smartAlbumType = .none
    self.isPrivacy = false
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
    self.albumType = .home
    self.smartAlbumType = .none
    self.isPrivacy = false
    self.title = "앨범\(sampleID)"
    self.fetchResult = PHFetchResult<PHAsset>()
    super.init()
  }
  deinit {
    if sampleCase != .none {
      print("deinited Album : \(self.title)")
    }
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
  }
  func settingSmart() {
    let option = PHFetchOptions()
    option.wantsIncrementalChangeDetails = true
    if !isPrivacy {
      fetchResult = PHAsset
        .fetchAssets(in: phAssetCollection, options: option)
    } else {
      hiddenFetchResult = PHAsset
        .fetchAssets(in: phAssetCollection, options: option)
    }
    PHPhotoLibrary.shared().register(self)
  }
  
  func generateArray(isHidden: Bool, completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .utility).async {
      let array = isHidden ? self.hiddenFetchResult : self.fetchResult
      let result = array
        .objects(at: IndexSet(integersIn: 0..<array.count))
        .filter { isHidden ? $0.isHidden : true }
        .map { MLAsset(phAsset: $0) }
      DispatchQueue.main.async { 
        withAnimation {
          switch isHidden {
          case false: self.photosArray = result
          case true: self.hiddenArray = result
          }
        }
        completion()
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
      self.hiddenFetchResult = PHFetchResult<PHAsset>()
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
                isHiddenAsset: Bool = false,
                completion: (@escaping (Bool) -> Void)) {
    guard let assetCollection = self.phAssetCollection else { return }
    // 선작업
    if !isHiddenAsset { processingChange(bool: true)
      let array = self.operatedArray(isHiddenAsset: false,
                                     setOperation: .union,
                                     assets: assets)
      DispatchQueue.main.async {
        withAnimation {
          self.photosArray = array
        }
      }
    }
    // 후 처리
    PHPhotoLibrary.shared()
      .performChanges {
        PHAssetCollectionChangeRequest(
          for: assetCollection, assets: self.fetchResult)?
          .addAssets(assets.compactMap { $0.phAsset } as NSFastEnumeration)
      } completionHandler: { [unowned self] bool, _ in
        if !isHiddenAsset {
          if bool {
            let option = PHFetchOptions()
            option.wantsIncrementalChangeDetails = true
            let changedFetchResult = PHAsset
              .fetchAssets(in: self.phAssetCollection,
                           options: option)
            DispatchQueue.main.async {
              withAnimation {
                self.fetchResult = changedFetchResult
              }
              self.processingChange(bool: false)
              completion(bool)
            }
          } else {
            // 실패시 원래 배열로 돌려놓기
            let oriArray = self.operatedArray(isHiddenAsset: false,
                                              setOperation: .subtraction,
                                              assets: assets)
            DispatchQueue.main.async {
              withAnimation {
                self.photosArray = oriArray
              }
              self.processingChange(bool: false)
              completion(bool)
            }
          }
        } else {
          completion(bool)
        }
      }
  }
  // user 앨범에서만 사용
  func removeAssetFromAlbum(assets: [MLAsset],
                            isHidden: Bool = false,
                            filteringType: FilteringType = .all,
                            completion: @escaping (Bool) -> Void) {
    processingChange(bool: true)
    // 선 작업
    let oriArray = !isHidden ? photosArray : hiddenArray
    let array = self.operatedArray(
      isHiddenAsset: isHidden,
      setOperation: .subtraction,
      assets: assets)
    DispatchQueue.main.async {
      if !isHidden {
        self.photosArray = array
      } else {
        self.hiddenArray = array
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
//          self.processingChange(bool: false)
          completion(bool)
        }
      } else {
        DispatchQueue.main.async {
          if !isHidden {
            self.photosArray = oriArray
          } else {
            self.hiddenArray = oriArray
          }
//          self.processingChange(bool: false)
          completion(bool)
        }
      }
    }
  }
  // 기기에서 삭제하기
  func deleteAssetFromDevice(albumType: AlbumType = .album,
                             assets: [MLAsset],
                             isHiddenAsset: Bool = false,
                             isDetailView: Bool = false,
                             completion: @escaping (Bool) -> Void) {
    processingChange(bool: true)
    // 선 작업
    let array = self.operatedArray(
      isHiddenAsset: isHiddenAsset,
      setOperation: .subtraction,
      assets: assets)
    DispatchQueue.main.async {
      if !isHiddenAsset {
        self.photosArray = array
      } else {
        self.hiddenArray = array
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
          self.processingChange(bool: false)
          completion(bool)
        }
      } else {
        let oriArray = self.operatedArray(isHiddenAsset: isHiddenAsset,
                                          setOperation: .union,
                                          assets: assets)
        DispatchQueue.main.async {
          if !isHiddenAsset {
            self.photosArray = oriArray
          } else {
            self.hiddenArray = oriArray
          }
          self.processingChange(bool: false)
          completion(bool)
        }
      }
    }
  }
  // 가리기 & 해제하기 {
  func hideOrUnhideAsset(assets: [MLAsset],
                         toHide: Bool,
                         completion: @escaping (Bool) -> Void) {
    processingChange(bool: true)
    // 선 작업
    let array = self.operatedArray(
      isHiddenAsset: !toHide,
      setOperation: .subtraction,
      assets: assets)
    DispatchQueue.main.async {
      withAnimation {
        if toHide {
          self.photosArray = array
        } else {
          self.hiddenArray = array
        }
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
          self.processingChange(bool: false)
          completion(bool)
        }
      } else {
        let oriArray = self.operatedArray(
          isHiddenAsset: !toHide,
          setOperation: .union,
          assets: assets)
        DispatchQueue.main.async {
          withAnimation {
            if toHide {
              self.photosArray = oriArray
            } else {
              self.hiddenArray = oriArray
            }
          }
          self.processingChange(bool: false)
          completion(bool)
        }
      }
    }
  }
  
  func favoriteAsset(toFavorite: Bool,
                     assets: [MLAsset],
                     isHiddenAsset: Bool,
                     completion: @escaping (Bool) -> Void) {
    self.processingChange(bool: true)
    var count = 0
    let filteredAssets = assets
      .filter {
        $0.isFavorite != toFavorite
      }
    filteredAssets
      .forEach {
        $0.favoriteAsset(toFavorite: toFavorite) { bool in
          count += 1
          if count == filteredAssets.count {
            completion(true)
          }
        }
      }
  }
}

extension MLAlbum {
  func fetchChecker(isHidden: Bool, completion: @escaping (Bool) -> Void) {
    if isHidden {
      completion(false)
    } else {
      let compare = self.fetchResult.count == self.photosArray.count
      completion(compare)
    }
  }
  func frObject(isHidden: Bool) -> [MLAsset] {
    let object = !isHidden ? self.fetchResult : self.hiddenFetchResult
    let result = object
      .objects(at: IndexSet(integersIn: 0..<object.count))
      .map({ MLAsset(phAsset: $0)})
      .filter {
        isHidden ? $0.isHidden : true
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
    case .union: set = set.union(Set(assets))
    case .intersection: set = set.intersection(Set(assets))
    case .subtraction: set = set.subtracting(Set(assets))
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
            if newFetch.hasIncrementalChanges {
              if newFetch.fetchResultAfterChanges.count != self.photosArray.count {
                self.generateArray(isHidden: false) {
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
            }
          }
        }
      }
    }
    if let newFetch = changeInstance.changeDetails(for: hiddenFetchResult) {
      if self.hiddenFetchResult != newFetch.fetchResultAfterChanges {
        if newFetch.hasIncrementalChanges {
          if !innerProcessing {
            DispatchQueue.main.async { [unowned self] in
              self.hiddenFetchResult = newFetch.fetchResultAfterChanges
            }
            if newFetch.hasIncrementalChanges {
              if frObject(isHidden: true).count != self.hiddenArray.count {
                self.generateArray(isHidden: true) {
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

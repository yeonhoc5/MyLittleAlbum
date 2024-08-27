//
//  PhotoData.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/27.
//

import Foundation
import Photos
import UIKit
import SwiftUI

// MARK: - photoData
class PhotoData: NSObject, ObservableObject, Identifiable {
    
    // 사용자 기기 사진 접근 권한
    @Published var status: PHAuthorizationStatus!
    
    // (1) 전체 사진   ->  Array/Set
    var allPhotos = PHFetchResult<PHAsset>() {
        didSet { self.updateAllPhotos() }
    }
    // (2-1) 전체 앨범   -  step 1: [앨범] -> [앨범fetchresult]
    var albumsInAllLevels = PHFetchResult<PHAssetCollection>() {
        didSet { updateAllAlbumsFetchResult() }
    }
    // (2-2) 전체 앨범   -  step 2: [앨범fetchresult] -> Set<사진>
    var albumFetchResultArray = [PHFetchResult<PHAsset>]() {
        didSet { updateAllAlbumsSet() }
    }
    // (3) 앨범 있는 사진 Set   ->  (1)-(2)   ->  앨범 있는/없는 사진 Array
    var setPhotosInAllAlbums = Set<PHAsset>() {
        didSet {
            updateNotInAnyAlbumPhotos()
            updateAllAlbumPhotos()
        }
    }
    // (4) result Array
    var setAllPhotos = Set<PHAsset>() {
        didSet { updateNotInAnyAlbumPhotos() }
    }
    
    // MARK: - TAB 1용 배열
    // 모든 사진용 배열
    @Published var allPhotosArray = [PHAsset]()
    // 앨범 있는 사진용 배열
    @Published var allPhotosArrayInAllAlbum = [PHAsset]()
    // 앨범 없는 사진용 배열
    @Published var photosArrayNotInAnyAlbum = [PHAsset]() {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.allPhotosChanged = true
                print("---->> Not in any Album Photos changed by Some Albums")
            }
        }
    }
    
    @Published var insertedIndexPath: [IndexPath] = []
    @Published var removedIndexPath: [IndexPath] = []
    @Published var changedIndexPath: [IndexPath] = []
    
    
    // MARK: - ui 체인지용 프라퍼티
    
    // 앨범 커버용 Random 숫자
    @Published var randomNum1: Int = 0
    @Published var randomNum2: Int = 0
    
    // ui 체인지
    @Published var uiMode: UIMode = .fancy
    @Published var useOpeningAni: Bool = true
    @Published var useKnock: Bool = true
    @Published var userReadDone: Bool = false
    @Published var backgroundColor: Color = .fancyBackground
    @Published var uiModeChanged: Bool = false
    
    @Published var albumAdded: Bool = false
    @Published var folderAdded: Bool = false
    
    @Published var allPhotosChanged: Bool = false
    @Published var isShowingDetailView: Bool = false
    
    @Published var scrollToTop: Bool = false
    
    // MARK: - 디지털 액자용 프라퍼티
    @Published var isShowingDigitalShow: Bool = false
    var digitalShowRandom: Bool = true
    var transitionIndex: Int = 2
    var digitalPhotoAlbums: [Album] = []
    var isHiddenAsset: Bool = false
    @Namespace var digitalView
    
    // MARK: - init
    override init() {
        super.init()
        // 1. load UImode (from UserDefault)
        loadUserSetting()
        // 2. 디스플레이용 랜덤 넘버
        getRandomNum()
        // 3. Photo Library 권한 확인 및 설정 -> 초기 데이터 로드
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        configPHLibraryStatus(status: status)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // get 저장된 uimode (없으면 default로 fancy 버전)
    func loadUserSetting() {
        print("[stpe 1. Load User Setting]")
        let userDefaults = UserDefaults.standard
        // 1. uiMode
        let rawValue = userDefaults
            .string(forKey: UserDefaultsKey.uimode.rawValue)
        uiMode = UIMode(rawValue: rawValue ?? "") ?? .fancy
        // 2. 오프닝 애니메이션
        let openingAni = userDefaults
            .bool(forKey: UserDefaultsKey.useOpeningAni.rawValue)
        useOpeningAni = openingAni
        // 3. 노트 기능
        let knock = userDefaults
            .bool(forKey: UserDefaultsKey.useKnock.rawValue)
        // 4. 디지털 액자 랜덤 or 순서대로
        let isRandom = userDefaults
            .bool(forKey: UserDefaultsKey.digitalShowRandom.rawValue)
        digitalShowRandom = isRandom
        // 5. 디지털 액자 사진 전환 주기
        useKnock = knock
        let transition = userDefaults
            .integer(forKey: UserDefaultsKey.transitionIndex.rawValue)
        transitionIndex = transition
        // 6. 최신 공지 확인 여부
        let readDone = userDefaults
            .bool(forKey: UserDefaultsKey.userReadDone.rawValue)
        userReadDone = readDone
        print("-- 1. UImode - \(uiMode.rawValue)")
        print("-- 2. use Opening Animation - \(useOpeningAni)")
        print("-- 3. use Konck - \(useKnock)")
        print("-- 4. digitalShow Random - \(digitalShowRandom)")
        print("-- 5. digitalShow Transition Time - \(transitionRange[transitionIndex])sec")
        print("-- 6. user Read recent notice? - \(userReadDone)")
        print("[Load User Setting Done]")
    }
    
    // 앨범 이미지용 랜덤 수 2개
    func getRandomNum() {
        self.randomNum1 = Int.random(in: 0..<Int.max)
        self.randomNum2 = Int.random(in: 0..<Int.max)
        while randomNum2 == randomNum1 {
            self.randomNum2 = Int.random(in: 0..<Int.max)
        }
        print("[step 2: random numbers generated]")
    }
    
    func configPHLibraryStatus(status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newValue in
                switch newValue {
                case .authorized:
                    DispatchQueue.main.async {
                        self.status = newValue
                        self.fetchAllPhotos()
                        self.fetchAllAlbums()
                    }
                    PHPhotoLibrary.shared().register(self)
                default:
                    print("권한이 없습니다.")
                }
            }
        case .authorized:
            DispatchQueue.main.async {
                self.fetchAllPhotos()
                self.fetchAllAlbums()
            }
            PHPhotoLibrary.shared().register(self)
        default:
            print("권한이 없습니다.")
        }
    }
    
    // 앨범없는 사진용 포토
    func fetchAllPhotos() {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.includeHiddenAssets = false
        allPhotosOptions.wantsIncrementalChangeDetails = true
        allPhotosOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        self.allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        print("[step 3: All Photos Fetched]")
    }
    
    // 전체 앨범
    func fetchAllAlbums() {
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = true
        options.includeHiddenAssets = false
        self.albumsInAllLevels = PHAssetCollection
            .fetchAssetCollections(with: .album,
                                   subtype: .albumRegular,
                                   options: options)
        print("[step 4: All Albums Fetched]")
    }
    
    
    func setUIMode(uimode: UIMode) {
        self.uiMode = uimode
        let userDefaults = UserDefaults.standard
        userDefaults.set(uiMode.rawValue, forKey: "uimode")
    }
}

// 앨범이 없는 사진
extension PhotoData {
    private func updateAllPhotos() {
        self.allPhotosArray = self.allPhotos
            .objects(at: IndexSet(integersIn: 0..<self.allPhotos.count))
        self.setAllPhotos = Set(self.allPhotosArray)
    }
    private func updateAllAlbumsFetchResult() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let array = Array(self.albumsInAllLevels
                .objects(at: IndexSet(integersIn: 0..<self.albumsInAllLevels.count)))
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = false
            fetchOptions.wantsIncrementalChangeDetails = true
            self.albumFetchResultArray = array
                .map{ PHAsset.fetchAssets(in: $0, options: fetchOptions) }
        }
    }
    private func updateAllAlbumsSet() {
        DispatchQueue.main.async {
            var resultSet = Set<PHAsset>()
            self.albumFetchResultArray.forEach {
                resultSet = resultSet
                    .union(Set($0.objects(at: IndexSet(integersIn: 0..<$0.count))))
            }
            self.setPhotosInAllAlbums = resultSet
        }
    }
    private func updateAllAlbumPhotos() {
        DispatchQueue.main.async {
            self.allPhotosArrayInAllAlbum = Array(self.setPhotosInAllAlbums)
                .sorted{ $0.creationDate! < $1.creationDate!}
        }
    }
    private func updateNotInAnyAlbumPhotos() {
        DispatchQueue.main.async {
            self.photosArrayNotInAnyAlbum = Array(
                self.setAllPhotos.subtracting(self.setPhotosInAllAlbums)
            ).sorted{ $0.creationDate! < $1.creationDate! }
        }
    }
}

extension PhotoData: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.interactiveSpring(response: 0.35,
                                             dampingFraction: 0.5,
                                             blendDuration: 0.5)) {
                if let changeDetail = changeInstance.changeDetails(for: self.allPhotos) {
                    if changeDetail.hasIncrementalChanges {
                        self.allPhotos = changeDetail.fetchResultAfterChanges
                        if let inserted = changeDetail.insertedIndexes, inserted.count > 0 {
                            self.insertedIndexPath = inserted
                                .map { IndexPath(item: $0, section:0) }
                        }
                        if let removed = changeDetail.removedIndexes, removed.count > 0 {
                            self.removedIndexPath = removed
                                .map { IndexPath(item: $0, section: 0) }
                        }
                        
                        if let changed = changeDetail.changedIndexes, changed.count > 0 {
                            self.changedIndexPath = changed
                                .map { IndexPath(item: $0, section: 0) }
                        }
//                        self.allPhotosChanged = true
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.interactiveSpring(response: 0.35,
                                             dampingFraction: 0.5,
                                             blendDuration: 0.5)) {
                if let changeDetail = changeInstance.changeDetails(for: self.albumsInAllLevels) {
                    if changeDetail.insertedIndexes?.count ?? 0 > 0 {
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.includeHiddenAssets = false
                        fetchOptions.wantsIncrementalChangeDetails = true
                        self.albumFetchResultArray.append(PHAsset.fetchAssets(in: changeDetail.insertedObjects.first!, options: fetchOptions))
                    }
                    if changeDetail.removedIndexes?.count ?? 0 > 0 {
                        let index = self.albumsInAllLevels.index(of: changeDetail.removedObjects.first!)
                        self.albumFetchResultArray.remove(at: index)
//                        let fetchResult = PHAsset.fetchAssets(in: changeDetail.removedObjects.first!, options: nil)
//                        let index = self.albumFetchResultArray.firstIndex(of: fetchResult)!
//                        self.albumFetchResultArray.remove(at: index)
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
                for i in 0..<self.albumFetchResultArray.count {
                    if let changeDetail = changeInstance.changeDetails(for: self.albumFetchResultArray[i]) {
                        if changeDetail.hasIncrementalChanges {
                            self.albumFetchResultArray[i] = changeDetail.fetchResultAfterChanges
                        }
                    }
                }
            }
        }
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            if let changeDetail = changeInstance.changeDetails(for: self.albumsInAllLevels) {
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
                    if self.albumsInAllLevels.count != changeDetail.fetchResultAfterChanges.count {
                        self.albumsInAllLevels = changeDetail.fetchResultAfterChanges
//                        let arrayAssetCollection = Array(self.albumsInAllLevels.objects(at: IndexSet(integersIn: 0..<self.albumsInAllLevels.count)))
//                        self.arrayFetchResultOfAllAlbums = Array(arrayAssetCollection.map({PHAsset.fetchAssets(in: $0, options: nil)}))
//                        self.generatingBackgroundPhotos()
                    }
                }
            }
        }
    }
}

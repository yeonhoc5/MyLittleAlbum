//
//  AlbumModel.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/26.
//

import SwiftUI
import Photos

class Album: NSObject, Identifiable, ObservableObject {
    
// MARK: - 프라퍼티 1. 일반 앨범용
    var album: PHAssetCollection!
    let id: UUID = UUID()
    @Published var identifier: String = ""
    @Published var title: String = "" {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var colorIndex: Int = 0
    @Published var rprsttivePhoto1: PHAsset!
    @Published var rprsttivePhoto2: PHAsset!
    @Published var albumFetchResult = PHFetchResult<PHAsset>()
    
    @Published var rprstBigPhoto0: UIImage!
    @Published var rprstBigPhoto1: UIImage!
    @Published var rprstBigPhoto2: UIImage!
    @Published var rprstSmallPhoto: UIImage!
    
// MARK: - 프라퍼티 2. 전체 사진 / 앨범없는 사진 / 앨범 있는 사진용
    @Published var belongingType: BelongingType = .all
    
    var allPhotos: PHFetchResult<PHAsset>!
    var albumsInAllLevels: PHFetchResult<PHAssetCollection>!
    var arrayFetchResultOfAllAlbums: [PHFetchResult<PHAsset>]!
    var setAllAlbumsPhotos: Set<PHAsset>!
    
    // init에서 체인지 옵저버 작동하지 않도록
    var settingDone: Bool = false
    
// MARK: - 프라퍼티 3. 공용 -> asset collectionView 구성 요소
    @Published var photosArray = [PHAsset]() 
    @Published var hiddenAssetsArray = [PHAsset]()
    @Published var count: Int = 0 {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var countOfImage: Int = 0 {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var countOfVidoe: Int = 0 {
        willSet {
            objectWillChange.send()
        }
    }

    @Published var filteringType: FilteringType = .all
    @Published var isHiddenAsset: Bool = false
    // 공통 프라퍼티 - 체인지 옵저버
    @Published var insertedIndexPath: [IndexPath] = []
    @Published var removedIndexPath: [IndexPath] = []
    @Published var changedIndexPath: [IndexPath] = []
    
    
// MARK: - init 2가지
    
    // 1. [TAB : 나의 앨범] 유저 앨범용
    init(album: PHAssetCollection, title: String! = nil, colorIndex: Int! = 0, randomNum1: Int! = 0, randomNum2: Int! = 0, isHidden: Bool! = false) {
        super.init()
        PHPhotoLibrary.shared().register(self)
        // 패치 전 앨범 정보re
        self.album = album
        self.identifier = album.localIdentifier
        self.title = title == nil ? album.localizedTitle ?? "" : title
        self.colorIndex = colorIndex
        self.isHiddenAsset = isHidden
        
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = true
        self.albumFetchResult = PHAsset.fetchAssets(in: album, options: options)
        self.count = albumFetchResult.count
        if !isHidden {
            self.photosArray = Array(albumFetchResult.objects(at: IndexSet(integersIn: 0..<count)))
        } else {
            self.hiddenAssetsArray = Array(albumFetchResult.objects(at: IndexSet(integersIn: 0..<count)))
        }
        
        self.countOfImage = (!isHidden ? photosArray : hiddenAssetsArray)
                            .filter{$0.mediaType == .image}.count
        self.countOfVidoe = (!isHidden ? photosArray : hiddenAssetsArray)
                            .filter{$0.mediaType == .video}.count
        if count == 1 {
            self.rprsttivePhoto1 = albumFetchResult[randomNum1 % count]
        } else if count > 1 {
            self.rprsttivePhoto1 = albumFetchResult[randomNum1 % count]
            self.rprsttivePhoto2 = albumFetchResult[randomNum2 % count]
            if rprsttivePhoto2 == rprsttivePhoto1 {
                rprsttivePhoto2 = albumFetchResult[(randomNum2 + 1) % count]
            }
        }
    }
    
    // 2. [TAB : 나의 포토] 앨범있는 사진용 / 앨범없는 사진용
    init(albumType: AlbumType! = .album, assetArray: [PHAsset], title: String, belongingType: BelongingType! = .all, // 필수
         allPhotos: PHFetchResult<PHAsset>! = nil,                  // 올포토, 논앨범용
         albumsInAllLevels: PHFetchResult<PHAssetCollection>! = nil,
         arrayAllAlbumFetchResutl: [PHFetchResult<PHAsset>]! = nil) { //올앨범, 논앨범용
        // 필수
        super.init()
        self.photosArray = assetArray
        PHPhotoLibrary.shared().register(self)
        self.title = title
        self.count = photosArray.count
        self.countOfImage = photosArray.filter{$0.mediaType == .image}.count
        self.countOfVidoe = photosArray.filter{$0.mediaType == .video}.count
        // 체인지 옵저버용
        self.belongingType = belongingType
        
        if albumType != .picker {
            if belongingType != .album {
                self.allPhotos = allPhotos
            }
            if belongingType != .all {
                self.albumsInAllLevels = albumsInAllLevels
                self.arrayFetchResultOfAllAlbums = arrayAllAlbumFetchResutl
                self.setAllAlbumsPhotos = self.generateAllAlbumPhotos(allAlbumPhotosArray: arrayAllAlbumFetchResutl)
            }
            self.settingDone = true
        }
    }
    
    deinit {
        print("deinited Album : \(self.title)")
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}


// MARK: - 익스텐션 1. 앨범 처리 함수
extension Album {
    func fetchOnlyHiddenAssets(_ reFetchResult: PHFetchResult<PHAsset>! = nil, result: @escaping (Int) -> Void) {
        var allArray = [PHAsset]()
        if reFetchResult == nil {
            let options = PHFetchOptions()
            options.wantsIncrementalChangeDetails = true
            options.includeHiddenAssets = true
            let allAssets = PHAsset.fetchAssets(in: album, options: options)
            allArray = Array(allAssets.objects(at: IndexSet(integersIn: 0..<allAssets.count)))
        } else {
            allArray = Array(reFetchResult.objects(at: IndexSet(integersIn: 0..<reFetchResult.count)))
        }
                
        let hiddenArray = allArray.filter{ $0.isHidden == true }
        DispatchQueue.main.async {
            withAnimation {
                self.hiddenAssetsArray = hiddenArray
            }
        }
        result(hiddenArray.count)
    }
    
    func generateAllAlbumPhotos(allAlbumPhotosArray: [PHFetchResult<PHAsset>]) -> Set<PHAsset> {
        var resultSet = Set<PHAsset>()
        let resultArrayOfSets = allAlbumPhotosArray.map{Set($0.objects(at: IndexSet(integersIn: 0..<$0.count)))}
        resultSet = Set(resultArrayOfSets.reduce(Set<PHAsset>()) { $0.union($1)})
        self.setAllAlbumsPhotos = resultSet
        return resultSet
    }
    
    func generateNonAlbumPhotos(allPhotos: PHFetchResult<PHAsset>,
                                setAllAlbumsPhotos: Set<PHAsset>){
        let setAllPhotos = Set(allPhotos.objects(at: IndexSet(integersIn: 0..<allPhotos.count)))
        let resultSet = setAllPhotos.subtracting(setAllAlbumsPhotos)
        self.photosArray = Array(resultSet).sorted(by: {$0.creationDate! < $1.creationDate!})
        self.count = self.photosArray.count
        self.countOfImage = self.photosArray.filter{$0.mediaType == .image}.count
        self.countOfVidoe = self.photosArray.filter{$0.mediaType == .video}.count
    }
    
    func refreshAlbumModel(_ newFetchResutl: PHFetchResult<PHAsset>) {
        DispatchQueue.main.async {
            self.albumFetchResult = newFetchResutl
            self.count = self.albumFetchResult.count
            self.photosArray = Array(self.albumFetchResult.objects(at: IndexSet(integersIn: 0..<self.count)))
            self.countOfImage = self.photosArray.filter{$0.mediaType == .image}.count
            self.countOfVidoe = self.photosArray.filter{$0.mediaType == .video}.count
            print("album [\(self.title)] Step 10. album is REFRESHED by RefreshFunction")
        }
    }
    
    func changeFiltering(type: FilteringType) {
        withAnimation {
            self.filteringType = type
        }
        
    }
    
    
    // 앨범에 asset 넣기
    func addAsset(assets: [PHAsset],
                  stateObject: StateChangeObject,
                  completion: (@escaping (Bool) -> Void)) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest(
                for: self.album,
                assets: self.albumFetchResult)?
                .addAssets(assets as NSFastEnumeration)
        } completionHandler: { bool, _ in
            if bool {
                DispatchQueue.main.async {
                    withAnimation {
                        stateObject.assetChanged = .changed
                    }
                }
                print("album [\(self.title)] Step 2. assets are INSERTED")
            }
            completion(bool)
        }
    }
    
    // 앨범에서 asset 빼기
    func removeAssetFromAlbum(indexSet: [Int],
                              isHidden: Bool = false,
                              completion: @escaping (Bool) -> Void) {
        var assetArray: [PHAsset] = isHidden ? self.hiddenAssetsArray : self.photosArray
        switch self.filteringType {
        case .image: assetArray = assetArray.filter{ $0.mediaType == .image }
        case .video: assetArray = assetArray.filter{ $0.mediaType == .video }
        default: break
        }
        let assets: [PHAsset] = indexSet.map({assetArray[$0]})
        
        var checkFetchResult = PHFetchResult<PHAsset>()
        
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges {
                let options = PHFetchOptions()
                options.includeHiddenAssets = isHidden
                checkFetchResult = PHAsset.fetchAssets(in: self.album, options: options)
                PHAssetCollectionChangeRequest(for: self.album, assets: checkFetchResult)?.removeAssets(assets as NSFastEnumeration)
            } completionHandler: { [unowned self] bool, _ in
//                guard let self = self else { return }
                if bool {
                    if isHidden {
                        self.fetchOnlyHiddenAssets { _ in
                        }
                        print("hidden asset array refetched")
                    }
                    print("album [\(self.title)] Step 3. assets are REMOVED")
                }
                completion(bool)
            }
        }
    }
    
    // 기기에서 삭제하기
    func deleteAssetFromDevice(indexSet: [Int],
                               stateObject: StateChangeObject,
                               isHidden: Bool = false,
                               isDetailView: Bool = false) {
        var assetArray: [PHAsset] = isHidden ? self.hiddenAssetsArray : self.photosArray
        switch self.filteringType {
        case .image: assetArray = assetArray.filter{ $0.mediaType == .image }
        case .video: assetArray = assetArray.filter{ $0.mediaType == .video }
        default: break
        }
        let assets: [PHAsset] = indexSet.map({ assetArray[$0] })
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
            } completionHandler: { [unowned self] bool, _ in
                if !isDetailView && bool {
                    DispatchQueue.main.async {
                        NotificationCenter.default
                            .post(name: .showProgressingView, object: nil)
                    }
                }
//                guard let self = self else { return }
                if bool {
                    if isHidden {
                        self.fetchOnlyHiddenAssets { _ in
                        }
                    }
                }
            }
        }
    }

    // 가리기 {
    func hideAsset(indexSet: [Int],
                   stateObject: StateChangeObject,
                   isSeperated: Bool! = false,
                   isDetailView: Bool = false) {
        var assetArray: [PHAsset] = []
        switch self.filteringType {
        case .all: assetArray = self.photosArray
        case .image: assetArray = self.photosArray.filter({$0.mediaType == .image})
        case .video: assetArray = self.photosArray.filter({$0.mediaType == .video})
        case .favorite: assetArray = self.photosArray.filter({ $0.isFavorite })
        }
        let assets: [PHAsset] = indexSet.map({assetArray[$0]})
        
        PHPhotoLibrary.shared().performChanges {
            for i in assets {
                let request = PHAssetChangeRequest(for: i)
                    request.isHidden = true
            }
        } completionHandler: { bool, _ in
            if !isDetailView && bool {
                DispatchQueue.main.async {
                    NotificationCenter.default
                        .post(name: .showProgressingView, object: nil)
                }
            }
//            guard let _ = self else { return }
            if !isSeperated {
                if bool {
                    DispatchQueue.main.async {
                        stateObject.assetChanged = .changed
                    }
                }
            }
        }
    }
    
    // 가리기 해제
    func unHideAsset(indexSet: [Int],
                     stateObject: StateChangeObject,
                     isAlbum: Bool = false) {
        var assetArray = isAlbum ? self.hiddenAssetsArray : self.photosArray
        switch self.filteringType {
        case .image: assetArray = assetArray.filter{ $0.mediaType == .image }
        case .video: assetArray = assetArray.filter{ $0.mediaType == .video }
        default: break
        }
        let assets = indexSet.map{ assetArray[$0] }
        PHPhotoLibrary.shared().performChanges {
            for i in assets {
                if i.isHidden {
                    let request = PHAssetChangeRequest(for: i)
                        request.isHidden = false
                }
            }
        } completionHandler: { [unowned self] bool, _ in
//            guard let self = self else { return }
            if bool {
                if isAlbum {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.hiddenAssetsArray.remove(atOffsets: IndexSet(indexSet))
                        }
                    }
                }
                DispatchQueue.main.async {
                    stateObject.assetChanged = .changed
                }
                print("album [\(self.title)] Step 6. assets are CANCEL HIDDEN")
            }
            
        }
    }
    func unHideAsset(indexSet: [Int],
                     isHidden: Bool = false,
                     completion: @escaping (Bool) -> Void) {
        var assetArray = isHidden ? self.hiddenAssetsArray : self.photosArray
        switch self.filteringType {
        case .image: assetArray = assetArray.filter{ $0.mediaType == .image }
        case .video: assetArray = assetArray.filter{ $0.mediaType == .video }
        default: break
        }
        PHPhotoLibrary.shared().performChanges {
            let _ = indexSet
                .map { assetArray[$0] }
                .map { PHAssetChangeRequest(for: $0).isHidden = false }
        } completionHandler: { [unowned self] bool, _ in
//            guard let self = self else { return }
            if bool {
                if isHidden {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.fetchOnlyHiddenAssets { _ in
                                completion(bool)
                            }
                        }
                    }
                } else {
                    completion(bool)
                }
                print("album [\(self.title)] Step 6. assets are CANCEL HIDDEN")
            }
            
        }
    }
    
    
    // 앨범 지우기
    func deleteAlbum(completion: @escaping (Bool?) -> Void) {
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges ({
                PHAssetCollectionChangeRequest.deleteAssetCollections([self.album] as! NSFastEnumeration)
            }) { [unowned self] (success, error) in
//                guard let self = self else { return }
                print("Finished removing the album [\(self.title)]. \(success ? "Success" : String(describing: error))")
                completion(success)
            }
        }
    }
    
    // 앨범에 있는 asset hidden 처리하기 (올 앨범은 따로 처리)
    
    
    // 앨범명 수정하기
    func modifyAlbumTitle(newName: String) {
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges {
                guard let request = PHAssetCollectionChangeRequest(for: self.album) else { return }
                request.title = newName
            } completionHandler: { [unowned self] bool, _ in
//                guard let self = self else { return }
                if bool {
                    DispatchQueue.main.async {
                        self.title = newName
                    }
                    print("album [\(self.title)] Name is Changed")
                }
                
            }
        }
    }
    
    func generatingBackgroundPhotos() {
        let set = self.generateAllAlbumPhotos(allAlbumPhotosArray: self.arrayFetchResultOfAllAlbums)
        if self.belongingType == .album {
            self.photosArray = Array(set).sorted(by: {$0.creationDate! < $1.creationDate!})
            self.count = self.photosArray.count
            self.countOfImage = self.photosArray.filter{$0.mediaType == .image}.count
            self.countOfVidoe = self.photosArray.filter{$0.mediaType == .video}.count
        }
        if self.allPhotos != nil {
            self.generateNonAlbumPhotos(allPhotos: self.allPhotos, setAllAlbumsPhotos: set)
        }
    }
    
    
}

// MARK: - 익스텐션 2. 체인지 옵저버
extension Album: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Oserver 1. album self / album title Changer (fetchResult가 바뀌어도 감지함)
        if let _ = self.album {
            withAnimation(.interactiveSpring()) {
                if let albumChanges = changeInstance.changeDetails(for: self.album) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.album = albumChanges.objectAfterChanges
                        if self.title != albumChanges.objectAfterChanges?.localizedTitle {
                            self.title = self.album?.localizedTitle ?? ""
                            print("album [\(self.title)] Step 40. album Change Detected by observer1 Tittle Changer -> [\(albumChanges.objectAfterChanges?.localizedTitle ?? "")]")
                        }
                    }
                }
            }
        }
         
        
        if let changes = changeInstance.changeDetails(for: self.albumFetchResult) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                self.albumFetchResult = changes.fetchResultAfterChanges
                if self.album != nil {
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.includeHiddenAssets = false
                    fetchOptions.wantsIncrementalChangeDetails = true
                    if self.albumFetchResult != changes.fetchResultAfterChanges {
                        print("album [\(self.title)] Step 50. album Change Detected by observer2 album FetchResult")
                        let newFetchResult = PHAsset
                            .fetchAssets(in: self.album, options: fetchOptions)
                        self.albumFetchResult = newFetchResult
                        self.refreshAlbumModel(self.albumFetchResult)
                        if self.isHiddenAsset {
                            self.fetchOnlyHiddenAssets { _ in
                            }
                        }
                    }
                }
                if changes.hasIncrementalChanges {
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        self.insertedIndexPath = inserted.map { IndexPath(item: $0, section:0) }
                    }
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        self.removedIndexPath = removed.map { IndexPath(item: $0, section: 0) }
                    }
                    
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        self.changedIndexPath = changed.map { IndexPath(item: $0, section: 0) }
                    }
//                    print("\(self.insertedIndexPath.count) // \(self.removedIndexPath.count) // \(self.changedIndexPath.count)")
                }
            }
        }

        
        if allPhotos != nil && settingDone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
                    if let changeDetail = changeInstance.changeDetails(for: self.allPhotos) {
                        print("album [\(self.title)] Step 60. album Change Detected by observer3 Allphotos")
                        if changeDetail.hasIncrementalChanges {
                            self.allPhotos = changeDetail.fetchResultAfterChanges
                            if self.belongingType == .all {
                                self.refreshAlbumModel(self.allPhotos)
                            } else if self.belongingType == .nonAlbum {
                                self.generateNonAlbumPhotos(allPhotos: self.allPhotos, setAllAlbumsPhotos: self.setAllAlbumsPhotos)
                            }
                        }
                    }
                }
            }
        }
        
        if albumsInAllLevels != nil && settingDone {
            if let changeDetail = changeInstance.changeDetails(for: self.albumsInAllLevels) {
                print("album [\(self.title)] Step 70. album Change Detected by observer4 albumsInAllLevels")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
                        if self.albumsInAllLevels.count != changeDetail.fetchResultAfterChanges.count {
                            self.albumsInAllLevels = changeDetail.fetchResultAfterChanges
                            let arrayAssetCollection = Array(self.albumsInAllLevels.objects(at: IndexSet(integersIn: 0..<self.albumsInAllLevels.count)))
                            let fetchOptions = PHFetchOptions()
                            fetchOptions.includeHiddenAssets = false
                            fetchOptions.wantsIncrementalChangeDetails = true
                            self.arrayFetchResultOfAllAlbums = Array(arrayAssetCollection.map({PHAsset.fetchAssets(in: $0, options: fetchOptions)}))
                            self.generatingBackgroundPhotos()
                        }
                    }
                }
            }
        }
        
        if arrayFetchResultOfAllAlbums != nil && settingDone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
                    var isChanged = false
                    for i in 0..<self.arrayFetchResultOfAllAlbums.count {
                        if let changeDetail = changeInstance.changeDetails(for: self.arrayFetchResultOfAllAlbums[i]) {
                            if changeDetail.hasIncrementalChanges {
                                isChanged = true
                                self.arrayFetchResultOfAllAlbums[i] = changeDetail.fetchResultAfterChanges
                            }
                        }
                    }
                    if isChanged {
                        self.generatingBackgroundPhotos()
                        print("album [\(self.title)] Step 80. album Change Detected by observer5 All albums Fetch Results")
                    }
                }
            }
        }
        
//         앨범을 추가/삭제할 때는 각 Album 모델의 옵저버가 작동 / 여기서는 사진 추가/삭제가 이뤄질때만 작동

        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            if let changeDetails = changeInstance.changeDetails(for: self.albumsInAllLevels) {
//                if changeDetails.hasIncrementalChanges {
//
//                    var resultSet = Set<PHAsset>()
//                    for i in 0..<self.albumsInAllLevels.count {
//                        let fetchResutlAsset = PHAsset.fetchAssets(in: self.albumsInAllLevels[i], options: nil)
//                        let set = Set(fetchResutlAsset.objects(at: IndexSet(integersIn: 0..<fetchResutlAsset.count)))
//                        resultSet = resultSet.union(set)
//                    }
//                    if self.setPhotosInAllAlbums.count != resultSet.count {
//                        self.setPhotosInAllAlbums = resultSet
//                        print("체인지 옵저버: 앨범들 changend")
//                    }
//                }
//            }
//        }
//
    }
}

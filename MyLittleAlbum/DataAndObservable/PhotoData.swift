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


var screenSize: CGSize {
    get {
        guard let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.bounds.size else { return .zero }
        return size
    }
}

var scale: CGFloat {
    guard let scale = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.scale else { return .zero }
    return scale
}
let colorSet: [Color] = [.color1, .color2, .color3, .color4, .color5, .color6, .color7, .color8, .color9, .color10,
                         .color11, .color12, .color13, .color14, .color15, .color16, .color17, .color18, .color19, .color20,
                         .color21, .color22, .color23, .color24, .color25, .color26, .color27, .color28]
let emptyLabel: [String] = ["텅", "휘이잉~", "Zero", "조용...", "비움", "깨끗", "nothing", "또르르", "empty", "없을 무", "free", "공허", "blank", "0"]

let refreshPhotos: [String] = ["refreshPhoto01", "refreshPhoto02", "refreshPhoto03", "refreshPhoto05", "refreshPhoto06", "refreshPhoto07"]

// MARK: - photoData
class PhotoData: NSObject, ObservableObject, Identifiable {
    
    // 사용자 기기 사진 접근 권한
    @Published var status: PHAuthorizationStatus!
    
    // (1) 전체 사진   ->  Array/Set
    var allPhotos = PHFetchResult<PHAsset>() {
        didSet {
            self.allPhotosArray = self.allPhotos.objects(at: IndexSet(integersIn: 0..<self.allPhotos.count))
            self.setAllPhotos = Set(self.allPhotosArray)
//                allPhotosChanged = true
        }
    }
    
    // (2-1) 전체 앨범   -  step 1: [앨범] -> [앨범fetchresult]
    var albumsInAllLevels = PHFetchResult<PHAssetCollection>() {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let array = Array(self.albumsInAllLevels.objects(at: IndexSet(integersIn: 0..<self.albumsInAllLevels.count)))
                let fetchOptions = PHFetchOptions()
                fetchOptions.includeHiddenAssets = false
                fetchOptions.wantsIncrementalChangeDetails = true
                self.albumFetchResultArray = array.map{ PHAsset.fetchAssets(in: $0, options: fetchOptions) }
            }
        }
        
    }
    // (2-2) 전체 앨범   -  step 2: [앨범fetchresult] -> Set<사진>
    var albumFetchResultArray = [PHFetchResult<PHAsset>]() {
        didSet {
            DispatchQueue.main.async {
                var resultSet = Set<PHAsset>()
                self.albumFetchResultArray.forEach {
                    resultSet = resultSet.union(Set($0.objects(at: IndexSet(integersIn: 0..<$0.count))))
                }
                self.setPhotosInAllAlbums = resultSet
            }
        }
        
    }
    
    // (3) 앨범 있는 사진 Set   ->  (1)-(2)   ->  앨범 있는/없는 사진 Array
    var setPhotosInAllAlbums = Set<PHAsset>() {
        didSet {
            DispatchQueue.main.async {
                self.allPhotosArrayInAllAlbum = Array(self.setPhotosInAllAlbums).sorted{ $0.creationDate! < $1.creationDate!}
                self.photosArrayNotInAnyAlbum = Array(self.setAllPhotos.subtracting(self.setPhotosInAllAlbums)).sorted{ $0.creationDate! < $1.creationDate! }
            }
        }
    }
    
    var setAllPhotos = Set<PHAsset>() {
        didSet {
            DispatchQueue.main.async {
                self.photosArrayNotInAnyAlbum = Array(self.setAllPhotos.subtracting(self.setPhotosInAllAlbums)).sorted{ $0.creationDate! < $1.creationDate! }
            }
        }
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
    @Published var backgroundColor: Color = .fancyBackground
    
    @Published var albumAdded: Bool = false
    @Published var folderAdded: Bool = false
    
    @Published var allPhotosChanged: Bool = false
    @Published var isShowingDetailView: Bool = false
    
    
// MARK: - init
    override init() {
        super.init()
        // 1. load UImode (from UserDefault)
        loadUISetting()
        // 2. Photo Library 권한 확인 및 설정 -> 초기 데이터 로드
        status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        configPHLibraryStatus(status: status)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // get 저장된 uimode (없으면 default로 fancy 버전)
    func loadUISetting() {
        print("stpe 1. Load UI mode")
        let userDefaults = UserDefaults.standard
        let rawValue = userDefaults.string(forKey: "uimode")
        uiMode = UIMode(rawValue: rawValue ?? "") ?? .fancy
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
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        self.allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        print("step 2: All Photos Fetched")
        getRandomNum()
    }
    
    // 앨범 이미지용 랜덤 수 2개
    func getRandomNum() {
        let randomNum = Int.random(in: 0..<Int.max)
        self.randomNum1 = randomNum
        self.randomNum2 = randomNum + Int.random(in: 1..<randomNum)
        print("step 3: random numbers generated")
    }
    
    // 전체 앨범
    func fetchAllAlbums() {
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = true
        options.includeHiddenAssets = false
        self.albumsInAllLevels = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
        print("step 4: All Albums Fetched")
    }
    
    
    func setUIMode(uimode: UIMode) {
        self.uiMode = uimode
        let userDefaults = UserDefaults.standard
        userDefaults.set(uiMode.rawValue, forKey: "uimode")
    }
    
}

extension PhotoData: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
                if let changeDetail = changeInstance.changeDetails(for: self.allPhotos) {
                    if changeDetail.hasIncrementalChanges {
                        self.allPhotos = changeDetail.fetchResultAfterChanges
                        if let inserted = changeDetail.insertedIndexes, inserted.count > 0 {
                            self.insertedIndexPath = inserted.map { IndexPath(item: $0, section:0) }
                        }
                        if let removed = changeDetail.removedIndexes, removed.count > 0 {
                            self.removedIndexPath = removed.map { IndexPath(item: $0, section: 0) }
                        }
                        
                        if let changed = changeDetail.changedIndexes, changed.count > 0 {
                            self.changedIndexPath = changed.map { IndexPath(item: $0, section: 0) }
                        }
//                        self.allPhotosChanged = true
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
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

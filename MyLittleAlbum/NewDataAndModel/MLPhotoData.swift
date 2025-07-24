//
//  MLPhotoData.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/4/24.
//

import Foundation
import Photos
import SwiftUI

class MLPhotoData: NSObject, ObservableObject {
    @Published var phAuthorization: PHAuthorizationStatus
    // 사진 데이터
    var FRAlbums = PHFetchResult<PHAssetCollection>()
    @Published var folders: [String: MLFolder] = [:]
    @Published var albums: [String: MLAlbum] = [:]
    @Published var smartAlbums: [String: MLAlbum] = [:]
    @Published var homeAlbum: MLAlbum?
    // userData
    @Published var startView: Tabs = .album
    @Published var uiMode: UIMode = .fancy
    @Published var useOpeningAni: Bool = true
    @Published var useKnock: Bool = true
    @Published var userReadDone: Bool = false
    @Published var digitalShowRandom: Bool = true
    @Published var transitionIndex: Int = 2
    // 앨범 커버용 Random 숫자
    @Published var randomNum1: Int = 0
    @Published var randomNum2: Int = 0
    // 최근 작업 폴더 / 앨범
    @Published var recentWorkFolder: [String] = []
    @Published var recentWorkAlbum: [String] = []
    @Published var shareAlbums: [MLAlbum] = []
    var checkCount: Int = 0
    
    override init() {
        self.phAuthorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        super.init()
        loadUserSetting()
        getRandomNum()
        configPHLibraryStatus(status: phAuthorization)
    }
    deinit {
        print("photoData deinited")
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func albumsPhotosSet() -> Set<MLAsset> {
        let all = self.albums.values
            .flatMap { album in
                album.mlAsset()
            }
        return Set(all)
    }
}

//MARK: - 1. Folder & Albums 로드
extension MLPhotoData {
    // 1-1. 앨범 정보
    func setAlbums() {
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = true
        self.FRAlbums = PHAssetCollection
            .fetchAssetCollections(with: .album,
                                   subtype: .albumRegular,
                                   options: options)
        self.FRAlbums.enumerateObjects { assetCollection, _, _ in
            self.setAlbum(album: assetCollection)
        }
    }
    // 1-2. 폴더(카테고리) 정보
    func setFolders(folder: PHCollectionList! = nil, isNew: Bool = false) {
        if self.folders[folder?.localIdentifier ?? "topFolder"] == nil {
            let nextFolder = MLFolder(collectionList: folder)
            DispatchQueue.main.async {
                self.folders.updateValue(nextFolder, forKey: nextFolder.id)
                
            }
            if !isNew {
                nextFolder.fetchResult.enumerateObjects { collection, _, _ in
                    if collection.isKind(of: PHCollectionList.self) {
                        self.setFolders(folder: collection as? PHCollectionList)
                    }
                }
            }
        }
    }
    
    func setAlbum(album: PHAssetCollection!) {
        if self.albums[album.localIdentifier] == nil {
            DispatchQueue.main.async {
                self.albums.updateValue(MLAlbum(assetCollection: album),
                                        forKey: album.localIdentifier)
                    
            }
        }
    }
}

//MARK: - 3. changeObserver for FRAlbums: FetchResult<PHAssetCollection>
extension MLPhotoData: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let inserteds = changeInstance.changeDetails(for: FRAlbums)?.insertedObjects {
            for album in inserteds {
                if self.albums[album.localIdentifier] == nil {
                    DispatchQueue.main.async {
                        self.albums.updateValue(MLAlbum(assetCollection: album),
                                                forKey: album.localIdentifier)
                    }
                }
            }
        }
        if let removeds = changeInstance.changeDetails(for: FRAlbums)?.removedObjects {
            for album in removeds {
                if self.albums[album.localIdentifier] != nil {
                    DispatchQueue.main.async {
                        self.albums.removeValue(forKey: album.localIdentifier)
                    }
                }
            }
        }
    }
    func addRecentWorkSpace(id: String, isAlbum: Bool) {
        let userDefaults = UserDefaults.standard
        let encorder = JSONEncoder()
        
        
        
        var current = isAlbum ? self.recentWorkAlbum : self.recentWorkFolder
        if let index = current.firstIndex(of: id) {
            current.move(fromOffsets: [index], toOffset: 0)
        } else {
            current.insert(id, at: 0)
            if current.count > 10 {
                current.removeLast()
            }
        }
        let recent = current
            .enumerated()
            .map { (index, string) in
                RecentItem(order: index, identifider: string)
            }
        if let encoded = try? encorder.encode(recent) {
            userDefaults.set(encoded, forKey: (isAlbum
                                      ? UserDefaultsKey.recentAlbums
                                      : UserDefaultsKey.recentFolders).rawValue)
            print("ok recent saved")
            DispatchQueue.main.async {
                withAnimation {
                    if isAlbum {
                        self.recentWorkAlbum = current
                    } else {
                        self.recentWorkFolder = current
                    }
                }
            }
        } else {
            print("there is some error to save recent")
        }
    }
    func removeRecentWork(isFolder: Bool, id: String) {
        DispatchQueue.main.async { [unowned self] in
            if isFolder {
                if let index = self.recentWorkFolder.firstIndex(of: id) {
                    self.recentWorkFolder.remove(at: index)
                }
            } else {
                if let index = self.recentWorkAlbum.firstIndex(of: id) {
                    self.recentWorkAlbum.remove(at: index)
                }
            }
        }
    }
    func checkRemoveCollection(type: CollectionType,
                               folder: String? = nil,
                               album: String? = nil,
                               completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let folder = folder {
                if let _ = PHCollectionList
                    .fetchCollectionLists(withLocalIdentifiers: [folder], options: nil)
                    .firstObject {
                    completion(false)
                } else {
                    for seconFolder in self.folders[folder]?.foldersArray ?? [] {
                        self.checkRemoveCollection(type: type,
                            folder: seconFolder.localIdentifier) { bool in
                                DispatchQueue.main.async {
                                    withAnimation {
                                        let _ = self.folders
                                            .removeValue(forKey: seconFolder.localIdentifier)
                                    }
                                }
                            }
                    }
                    for seconAlbum in self.folders[folder]?.albumsArray ?? [] {
                        self.checkRemoveCollection(type: type,
                            album: seconAlbum.localIdentifier) { bool in
                                DispatchQueue.main.async {
                                    withAnimation {
                                        let _ = self.albums
                                            .removeValue(forKey: seconAlbum.localIdentifier)
                                    }
                                }
                            }
                    }
                    DispatchQueue.main.async {
                        withAnimation {
                            let _ = self.folders.removeValue(forKey: folder)
                        }
                    }
                    DispatchQueue.global().async {
                        if let _ = self.recentWorkFolder.firstIndex(of: folder) {
                            self.removeRecentWork(isFolder: true, id: folder)
                        }
                    }
                    completion(true)
                }
            } else {
                if let album = album {
                    if let _ = PHAssetCollection
                        .fetchAssetCollections(withLocalIdentifiers: [album], options: nil)
                        .firstObject {
                        completion(false)
                    } else {
                        DispatchQueue.main.async {
                            withAnimation {
                                let _ = self.albums.removeValue(forKey: album)
                                NotificationCenter.default
                                    .post(name: .outsideFetchChange, object: "myPhotos")
                            }
                        }
                        DispatchQueue.global().async {
                            if let _ = self.recentWorkAlbum.firstIndex(of: album) {
                                self.removeRecentWork(isFolder: false, id: album)
                            }
                        }
                        completion(true)
                    }
                }
            }
        }
    }
}


//MARK: - 4. 초기 로딩
extension MLPhotoData {
    // 3-1. user Setting Data
    func loadUserSetting() {
        let userDefaults = UserDefaults.standard
        print("[stpe 1. Load User Setting]")
            // 0. starView:
        let startView = userDefaults
            .string(forKey: UserDefaultsKey.startView.rawValue)
        // 1. uiMode: String
        let uimode = userDefaults
            .string(forKey: UserDefaultsKey.uimode.rawValue)
        // 2. 오프닝 애니메이션: Bool
        let openingAni = userDefaults
            .bool(forKey: UserDefaultsKey.useOpeningAni.rawValue)
        // 3. 노트 기능: Bool
        let knock = userDefaults
            .bool(forKey: UserDefaultsKey.useKnock.rawValue)
        // 4. 디지털 액자 랜덤 or 순서대로: Bool
        let isRandom = userDefaults
            .bool(forKey: UserDefaultsKey.digitalShowRandom.rawValue)
        // 5. 디지털 액자 사진 전환 주기: Int
        let transition = userDefaults
            .integer(forKey: UserDefaultsKey.transitionIndex.rawValue)
        // 6. 최신 공지 확인 여부
        let readDone = userDefaults
            .bool(forKey: UserDefaultsKey.userReadDone.rawValue)
        self.startView = Tabs(rawValue: startView ?? "") ?? .album
        self.uiMode = UIMode(rawValue: uimode ?? "") ?? .fancy
        self.useOpeningAni = openingAni
        self.useKnock = knock
        self.digitalShowRandom = isRandom
        self.transitionIndex = transition
        self.userReadDone = readDone
        // 7. 최근 작업 앨범/폴더
        let decoder = JSONDecoder()
        for i in [UserDefaultsKey.recentAlbums, UserDefaultsKey.recentFolders] {
            guard let recent = userDefaults.data(forKey: i.rawValue),
                  let decoded = try? decoder.decode([RecentItem].self, from: recent)
            else {
                print("\(i.rawValue) is empty")
                continue }
            print("ok go \(i.rawValue) \(decoded.count)")
            let result = decoded
                .sorted(by: { $0.order < $1.order })
                .compactMap( { $0.identifider })
            if i == .recentAlbums {
                self.recentWorkAlbum = result
            } else {
                self.recentWorkFolder = result
            }
        }
        print("-- 1. [\(uiMode.rawValue)] UImode")
        print("-- 2. [\(useOpeningAni)] use Opening Animation")
        print("-- 3. [\(useKnock)] use Konck")
        print("-- 4. [\(digitalShowRandom)] digitalShow Random")
        print("-- 5. [\(transitionRange[transitionIndex])sec] digitalShow Transition Time")
        print("-- 6. [\(userReadDone)] user Read recent notice?")
        print("-- 7. [recentAlbums: \(recentWorkAlbum.count)]")
        print("-- 8. [recentFolders: \(recentWorkFolder.count)]")
        print("[Load User Setting Done]")
    }
    // 1-2. 앨범 커버용 랜덤 넘버
    func getRandomNum() {
        DispatchQueue.global(qos: .userInitiated).sync {
            let number1 = Int.random(in: 0..<Int.max)
            var number2 = Int.random(in: 0..<Int.max)
            while number2 == number1 {
                number2 = Int.random(in: 0..<Int.max)
            }
            DispatchQueue.main.async {
                self.randomNum1 = number1
                self.randomNum2 = number2
                print("[step 2: random numbers generated]")
            }
        }
    }
    // 1-3. 포토 라이브러리 Authorization
    func configPHLibraryStatus(status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined, .denied, .limited:
            PHPhotoLibrary
                .requestAuthorization(for: .readWrite) { newValue in
                    switch newValue {
                    case .authorized:
                        DispatchQueue.main.async {
                            self.phAuthorization = newValue
                        }
                        self.loadPhotoData()
//                        self.loadShareAlbums()
                        PHPhotoLibrary.shared().register(self)
                    default:
                        print("권한이 없습니다.")
                    }
                }
        case .authorized:
            loadPhotoData()
//            self.loadShareAlbums()
            PHPhotoLibrary.shared().register(self)
        default:
            print("권한이 없습니다.")
        }
    }
    
    func loadPhotoData() {
        DispatchQueue.main.async {
            let topFolder = MLFolder(collectionList: nil)
            let _ = self.folders
                .updateValue(topFolder, forKey: "topFolder")
            phDataQueue.async {
                self.setAlbums()
                topFolder.foldersArray.forEach { folder in
                    self.setFolders(folder: folder)
                }
            }
            self.homeAlbum = MLAlbum(isHome: true)
            self.homeAlbum?.generateArray(isHiddenAsset: false) { }
        }
    }
    func loadShareAlbums() {
        let albums = PHAssetCollection
            .fetchAssetCollections(with: .smartAlbum,
                                   subtype: .albumCloudShared,
                                   options: nil)
        DispatchQueue.main.async {
            albums.enumerateObjects { assetCollection, index, _ in
                withAnimation {
                    self.shareAlbums
                        .append(MLAlbum(assetCollection: assetCollection))
                }
            }
        }
    }
}


struct RecentItem: Codable {
    let order: Int
    let identifider: String
}

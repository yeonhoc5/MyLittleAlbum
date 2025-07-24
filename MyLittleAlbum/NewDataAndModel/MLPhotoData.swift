//
//  MLPhotoData.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/4/24.
//

import Foundation
import Photos
import SwiftUI
enum LoadingStep {
    case ready
    case loadTopFolder
    case doneTopFolder
    case loadSecondaryLines
    case doneSecondaryLines
    case loadAllAlbums
    case doneAllAlbums
    case loadRemainFolders
    case doneRemainfolders
    case loadHomeAlbum
    case doneHomeAlbum
    case loadingComplete
}

class MLPhotoData: NSObject, ObservableObject {
    // 0.photo Library 접근 권한
    @Published var phAuthorization: PHAuthorizationStatus
    // 1.User Setting 데이타
    @Published var startView: Tabs = .album
    @Published var uiMode: UIMode = .fancy
    @Published var useOpeningAni: Bool = true
    @Published var useKnock: Bool = true
    @Published var userReadDone: Bool = false
    @Published var digitalShowRandom: Bool = true
    @Published var transitionIndex: Int = 2
    // 2.photo 데이타
    var FRAlbums = PHFetchResult<PHAssetCollection>()
    var FRFolders = PHFetchResult<PHCollectionList>()
    @Published var homeAlbum: MLAlbum?
    @Published var folders: [String: MLFolder] = [:]
    @Published var albums: [String: MLAlbum] = [:]
    @Published var smartAlbums: [String: MLAlbum] = [:]
    @Published var shareAlbums: [MLAlbum] = []
    // 3.앨범 커버용 Random 숫자
    @Published var randomNum1: Int = 0
    @Published var randomNum2: Int = 0
    // 4.최근 작업 폴더 / 앨범
    @Published var recentWorkFolder: [String] = []
    @Published var recentWorkAlbum: [String] = []
    @Published var loadingState: LoadingStep = .ready
    
    override init() {
        self.phAuthorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        super.init()
        loadUserSetting()
        getRandomNum()
        configPHLibraryStatus(status: phAuthorization)
    }
    deinit {
        print("photoData is deinited")
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

//MARK: - 1. Folder & Albums 로드
extension MLPhotoData {
    // 1-1. 앨범 정보
    func setEntireAlbums(async completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            let options = PHFetchOptions()
            options.wantsIncrementalChangeDetails = true
            self.FRAlbums = PHAssetCollection
                .fetchAssetCollections(with: .album,
                                       subtype: .albumRegular,
                                       options: options)
            self.FRAlbums.enumerateObjects { assetCollection, _, _ in
                if self.albums[assetCollection.localIdentifier] == nil {
                    self.setAlbum(album: assetCollection)
                }
            }
            completion()
        }
    }
    // 1-2. 폴더 정보
    func setEntireFolders(async completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            let options = PHFetchOptions()
            options.wantsIncrementalChangeDetails = true
            self.FRFolders = PHCollectionList
                .fetchCollectionLists(with: .folder,
                                      subtype: .regularFolder,
                                      options: options)
            self.FRFolders.enumerateObjects { collectionList, _, _ in
                if self.folders[collectionList.localIdentifier] == nil {
                    self.setFolders(folder: collectionList, loadSecondary: false)
                }
            }
            completion()
        }
    }
    // 1-2. 폴더(카테고리) 정보
    func setFolders(folder: PHCollectionList! = nil, loadSecondary: Bool = false) {
        let nextFolder = MLFolder(collectionList: folder)
        DispatchQueue.main.async {
            withAnimation {
                let _ = self.folders.updateValue(nextFolder, forKey: nextFolder.id)
            }
        }
        nextFolder.makeArray { bool in
            if loadSecondary {
                print("ok load secondary")
                nextFolder.foldersArray.forEach { folder in
                    self.setFolders(folder: folder, loadSecondary: true)
                }
                nextFolder.albumsArray.forEach { album in
                    self.setAlbum(album: album)
                }
            }
        }
    }
    
    func setAlbum(album: PHAssetCollection!) {
        if self.albums[album.localIdentifier] == nil {
            DispatchQueue.main.async {
                withAnimation {
                    let _ = self.albums
                        .updateValue(MLAlbum(assetCollection: album),
                                     forKey: album.localIdentifier)
                }
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
        if let inserteds = changeInstance.changeDetails(for: FRFolders)?.insertedObjects {
            for folder in inserteds {
                if self.folders[folder.localIdentifier] == nil {
                    DispatchQueue.main.async {
                        self.folders.updateValue(MLFolder(collectionList: folder),
                                                forKey: folder.localIdentifier)
                    }
                }
            }
        }
        if let removeds = changeInstance.changeDetails(for: FRFolders)?.removedObjects {
            for folder in removeds {
                if self.folders[folder.localIdentifier] != nil {
                    DispatchQueue.main.async {
                        self.folders.removeValue(forKey: folder.localIdentifier)
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
        if isFolder {
            if let index = self.recentWorkFolder.firstIndex(of: id) {
                DispatchQueue.main.async { [unowned self] in
                    self.recentWorkFolder.remove(at: index)
                }
            }
        } else {
            if let index = self.recentWorkAlbum.firstIndex(of: id) {
                DispatchQueue.main.async { [unowned self] in
                    self.recentWorkAlbum.remove(at: index)
                }
            }
        }
    }
    func albumsPhotosSet() -> Set<MLAsset> {
        let all = self.albums.values
            .flatMap { album in
                album.mlAsset()
            }
        return Set(all)
    }
}

//MARK: - 4. 초기 로딩
extension MLPhotoData {
    // 3-1. user Setting Data
    func loadUserSetting() {
        let userDefaults = UserDefaults.standard
        print("[stpe 1. Load User Setting]")
            // 0. starView:
        let startview = userDefaults
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
        self.startView = Tabs(rawValue: startview ?? "") ?? .album
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
            else { continue }
            let result = decoded
                .sorted(by: { $0.order < $1.order })
                .compactMap( { $0.identifider })
            if i == .recentAlbums {
                self.recentWorkAlbum = result
            } else {
                self.recentWorkFolder = result
            }
        }
        print("-- 0. [\(startView.rawValue)] satrtTabs")
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
                print("[step 3: random numbers generated]")
            }
        }
    }
    // 1-3. 포토 라이브러리 Authorization
    func configPHLibraryStatus(status: PHAuthorizationStatus) {
        switch status {
        case .authorized: loadAlbumData(step: .loadTopFolder)
            PHPhotoLibrary.shared().register(self)
        default:
            PHPhotoLibrary
                .requestAuthorization(for: .readWrite) { newValue in
                    switch newValue {
                    case .authorized:
                        DispatchQueue.main.async {
                            self.phAuthorization = newValue
                        }
                        self.loadAlbumData(step: .loadTopFolder)
                        PHPhotoLibrary.shared().register(self)
                    default:
                        print("권한이 없습니다.")
                    }
                }
        }
    }
    func loadAlbumData(step: LoadingStep) {
        switch step {
        case .loadTopFolder:
            let topFolder = MLFolder(collectionList: nil)
            topFolder.makeArray { _ in
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.folders.updateValue(topFolder, forKey: "topFolder")
                    })
                    self.loadingState = .doneTopFolder
                }
            }
        case .loadSecondaryLines:
            self.folders["topFolder"]?.foldersArray.forEach { folder in
                setFolders(folder: folder, loadSecondary: false)
            }
            DispatchQueue.main.async {
                self.loadingState = .doneSecondaryLines
            }
        case .loadAllAlbums:
            self.setEntireAlbums {
                DispatchQueue.main.async {
                    self.loadingState = .doneAllAlbums
                }
            }
        case .loadRemainFolders:
            self.setEntireFolders {
                DispatchQueue.main.async {
                    self.loadingState = .doneRemainfolders
                }
            }
        case .loadHomeAlbum:
            self.loadHomeAlbumView {
                DispatchQueue.main.async {
                    self.loadingState = .loadingComplete
                }
            }
        default: break
        }
    }
    
    func loadHomeAlbumView(completion: @escaping () -> Void) {
        let homeAlbum = MLAlbum(isHome: true)
        homeAlbum.generateArray(isHiddenAsset: false) {
            DispatchQueue.main.async {
                self.homeAlbum = homeAlbum
            }
            completion()
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
    func removeAlbumValue(album: PHAssetCollection,
                          async completion: @escaping () -> Void) {
        if let _ = self.albums[album.localIdentifier] {
            withAnimation {
                let _ = self.albums.removeValue(forKey: album.localIdentifier)
            }
            DispatchQueue.global().async {
                if let _ = self.recentWorkAlbum.firstIndex(of: album.localIdentifier) {
                    self.removeRecentWork(isFolder: false, id: album.localIdentifier)
                }
            }
            completion()
        }
    }
    func removeFolderValue(folder: PHCollectionList,
                           async completion: @escaping () -> Void) {
        if let mlFolder = self.folders[folder.localIdentifier] {
            if !mlFolder.albumsArray.isEmpty {
                for littleAlbum in mlFolder.albumsArray {
                    self.removeAlbumValue(album: littleAlbum) { } }
            }
            if !mlFolder.foldersArray.isEmpty {
                for littleFolder in mlFolder.foldersArray {
                    self.removeFolderValue(folder: littleFolder) { }
                }
            }
            withAnimation {
                let _ = self.folders.removeValue(forKey: folder.localIdentifier)
            }
            completion()
            DispatchQueue.global().async {
                if let _ = self.recentWorkFolder.firstIndex(of: folder.localIdentifier) {
                    self.removeRecentWork(isFolder: true, id: folder.localIdentifier)
                }
            }
        }
    }
}


struct RecentItem: Codable {
    let order: Int
    let identifider: String
}

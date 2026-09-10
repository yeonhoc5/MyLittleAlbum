//
//  MLPhotoData.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/4/24.
//

import Photos
import SwiftUI

enum LoadingStep {
  case ready
  case videoDone
  case loadTopFolder
  case doneTopFolder
  case loadSecondaryLines
  case doneSecondaryLines
  case loadAllAlbums
  case doneAllAlbums
  case loadHomeAlbum
  case doneHomeAlbum
  case loadingComplete
  
  // case 0_ready
  // case 1_loadTopFolder
  // csse 2_registTopsFolders
  // case 3_registTopsAlbums
  // case 4_regist
  // case 4_registHomAlbums
  // case 5_registAll
  //
}

class MLPhotoData: NSObject, ObservableObject {
  // 0.photo Library 접근 권한
  @Published var phAuthorization: PHAuthorizationStatus
  // 1.User Setting 데이타
  @Published var existingUser: Bool = false
  @Published var premiumUser: Bool = true
  @Published var startView: Tabs = .album
  @Published var uiMode: UIMode = .fancy
  @Published var useOpeningAni: Bool = true
  @Published var useKnock: Bool = true
  @Published var userReadDone: Bool = false
  @Published var digitalShowRandom: Bool = true
  @Published var transitionIndex: Int = 2
  // 2.photo 데이타
  var frAlbums = PHFetchResult<PHAssetCollection>()
  var frFolders = PHFetchResult<PHCollectionList>()
  var frShares = PHFetchResult<PHAssetCollection>()
  @Published var homeAlbum: MLAlbum?
  @Published var folders: [String: MLFolder] = [:]
  @Published var albums: [String: MLAlbum] = [:]
  @Published var smartAlbums: [String: MLAlbum] = [:]
  var shareCategories: [String: ShareCategory] = [:]
  @Published var shareFolders: [String: MLFolder] = [:]
  @Published var shareAlbums: [String: MLAlbum] = [:]
  @Published var photosVolume: [String: Int64] = [:]
  // 3.앨범 커버용 Random 숫자
  @Published var randomNum1: Int = 0
  @Published var randomNum2: Int = 0
  // 4.최근 작업 폴더 / 앨범
  @Published var recentWorkFolder: [String] = []
  @Published var recentWorkAlbum: [String] = []
  @Published var recentWorkCategory: [String] = []
  @Published var isReadyHomeView: Bool = false
  @Published var loadingState: LoadingStep = .ready
  
  let cachingManager = PHCachingImageManager()
  
  override init() {
    self.phAuthorization = PHPhotoLibrary
                          .authorizationStatus(for: .readWrite)
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
  func mlFolder(type: FolderType, _ id: String) -> MLFolder? {
    if type == .userFolder {
      return self.folders[id]
    } else {
      return self.shareFolders[id]
    }
  }
  func mlAlbum(type: FolderType, _ id: String) -> MLAlbum? {
    if type == .userFolder {
      return self.albums[id]
    } else {
      return self.shareAlbums[id]
    }
  }
  // 1-1. 앨범 정보
  func setEntireAlbums(async completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).async {
      let options = PHFetchOptions()
      options.wantsIncrementalChangeDetails = true
      self.frAlbums = PHAssetCollection
        .fetchAssetCollections(with: .album,
                               subtype: .albumRegular,
                               options: options)
      self.frAlbums.enumerateObjects { assetCollection, _, _ in
        if self.albums[assetCollection.localIdentifier] == nil {
          self.setAlbum(album: assetCollection,
                        folderType: .userFolder)
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
      self.frFolders = PHCollectionList
        .fetchCollectionLists(with: .folder,
                              subtype: .regularFolder,
                              options: options)
      self.frFolders.enumerateObjects { collectionList, _, _ in
        if self.folders[collectionList.localIdentifier] == nil {
          self.setFolders(folder: collectionList,
                          loadSecondary: false) { }
        }
      }
      completion()
    }
  }
  // 1-2. 폴더(카테고리) 정보
  func setFolders(folderType: FolderType = .userFolder,
                  folder: PHCollectionList! = nil,
                  shareCategory: ShareCategory! = nil,
                  loadSecondary: Bool = false,
                  async completion: @escaping () -> Void) {
    if folderType != .shareCategory {
      let nextFolder = MLFolder(collectionList: folder)
      DispatchQueue.main.async {
        withAnimation {
          let _ = self.folders
            .updateValue(nextFolder, forKey: nextFolder.id)
        }
        if !loadSecondary {
          completion()
        }
      }
      nextFolder.makeArray { bool in
        if loadSecondary {
          nextFolder.foldersArray.forEach { folder in
            if let folder = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [folder.id], options: nil).firstObject {
              self.setFolders(folder: folder, loadSecondary: true) { }
            }
          }
          nextFolder.albumsArray.forEach { album in
            if let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [album.id], options: nil).firstObject {
              self.setAlbum(album: album, folderType: .userFolder)
            }
          }
          completion()
        }
      }
    } else {
      let folder = MLFolder(folderType: .shareCategory,
                            shareCategory: shareCategory,
                            subCollections: [])
      DispatchQueue.main.async {
        withAnimation {
          let _ = self.shareFolders
            .updateValue(folder, forKey: folder.id)
        }
        completion()
      }
    }
  }
  
  func setAlbum(album: PHAssetCollection!, folderType: FolderType) {
    if folderType != .shareCategory {
      if self.albums[album.localIdentifier] == nil {
        DispatchQueue.main.async {
          withAnimation {
            let _ = self.albums
              .updateValue(
                MLAlbum(assetCollection: album, albumType: .album),
                forKey: album.localIdentifier)
          }
        }
      }
    } else {
      if self.shareAlbums[album.localIdentifier] == nil {
        DispatchQueue.main.async {
          withAnimation {
            let _ = self.shareAlbums
              .updateValue(MLAlbum(assetCollection: album,
                                   albumType: .share),
                           forKey: album.localIdentifier)
          }
        }
      }
    }
  }
}

//MARK: - 3. changeObserver for FRAlbums: FetchResult<PHAssetCollection>
extension MLPhotoData: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    // 전체 앨범
    if let inserteds = changeInstance
      .changeDetails(for: frAlbums)?.insertedObjects {
      for album in inserteds {
        if self.albums[album.localIdentifier] == nil {
          DispatchQueue.main.async {
            self.albums.updateValue(MLAlbum(assetCollection: album),
                                    forKey: album.localIdentifier)
          }
        }
      }
    }
    if let removeds = changeInstance
      .changeDetails(for: frAlbums)?.removedObjects {
      for album in removeds {
        if self.albums[album.localIdentifier] != nil {
          DispatchQueue.main.async {
            self.albums
              .removeValue(forKey: album.localIdentifier)
          }
        }
      }
    }
    // 전체 폴더
    if let inserteds = changeInstance
      .changeDetails(for: frFolders)?.insertedObjects {
      for folder in inserteds {
        if self.folders[folder.localIdentifier] == nil {
          DispatchQueue.main.async {
            self.folders
              .updateValue(MLFolder(collectionList: folder),
                           forKey: folder.localIdentifier)
          }
        }
      }
    }
    if let removeds = changeInstance
      .changeDetails(for: frFolders)?.removedObjects {
      for folder in removeds {
        if self.folders[folder.localIdentifier] != nil {
          DispatchQueue.main.async {
            self.folders
              .removeValue(forKey: folder.localIdentifier)
          }
        }
      }
    }
    // 공유 앨범
    if let inserteds = changeInstance
      .changeDetails(for: frShares)?.insertedObjects {
        guard let shareFolder = self.folders["shareTop"]
        else { return }
        if !inserteds.isEmpty {
          for album in inserteds {
            if self.shareAlbums[album.localIdentifier] == nil {
              shareFolder.appendAlbumInArray(album: album) {
                self.shareAlbums
                  .updateValue(MLAlbum(assetCollection: album),
                               forKey: album.localIdentifier)
              }
            }
          }
        }
    }
    if let removeds = changeInstance
      .changeDetails(for: frShares)?.removedObjects {
        guard let shareFolder = self.folders["shareTop"]
        else { return }
        if !removeds.isEmpty {
          for album in removeds {
            if let toRemove = self.shareAlbums[album.localIdentifier]  {
              DispatchQueue.main.async {
                let _ = withAnimation {
                  self.shareAlbums
                    .removeValue(forKey: toRemove.id)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                  shareFolder.removeAlbumInArray(album: album)
                }
              }
            }
          }
        }
    }
  }
  func addRecentWorkSpace(id: String, recentType: RecentType) {
    let userDefaults = UserDefaults.standard
    let encorder = JSONEncoder()
    
    var current = switch recentType {
    case .folder: self.recentWorkFolder
    case .category: self.recentWorkCategory
    case .album: self.recentWorkAlbum
    }
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
      userDefaults
        .set(encoded, forKey: RecentType.key(type: recentType)
                                        .rawValue)
      print("ok recent saved")
      DispatchQueue.main.async {
        withAnimation {
          switch recentType {
          case .folder:
            self.recentWorkFolder = current
          case .category:
            self.recentWorkCategory = current
          case .album:
            self.recentWorkAlbum = current
          }
        }
      }
    } else {
      print("there is some error to save recent")
    }
  }
  func removeRecentWork(type: RecentType, id: String) {
    switch type {
    case .folder:
      if let index = self.recentWorkFolder.firstIndex(of: id) {
        DispatchQueue.main.async { [unowned self] in
          self.recentWorkFolder.remove(at: index)
        }
      }
    case .category:
      if let index = self.recentWorkCategory.firstIndex(of: id) {
        DispatchQueue.main.async { [unowned self] in
          self.recentWorkCategory.remove(at: index)
        }
      }
    case .album:
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
    let existingUser = userDefaults
      .bool(forKey: UserDefaultsKey.existingUser.rawValue)
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
//    self.existingUser = existingUser
    self.startView = Tabs(rawValue: startview ?? "") ?? .album
    self.uiMode = UIMode(rawValue: uimode ?? "") ?? .fancy
    self.useOpeningAni = openingAni
    self.useKnock = knock
    self.digitalShowRandom = isRandom
    self.transitionIndex = transition
    self.userReadDone = readDone
    // 7. 최근 작업 앨범/폴더
    let decoder = JSONDecoder()
    for i in RecentType.allCases {
      guard let recent = userDefaults
        .data(forKey: RecentType.key(type: i).rawValue),
            let decoded = try? decoder
                          .decode([RecentItem].self, from: recent)
      else { continue }
      let result = decoded
        .sorted(by: { $0.order < $1.order })
        .compactMap( { $0.identifider })
      switch i {
      case .folder: self.recentWorkFolder = result
      case .category: self.recentWorkCategory = result
      case .album: self.recentWorkAlbum = result
      }
    }
    print("-- 0. [\(existingUser)] existingUser")
    print("-- 1. [\(startView.rawValue)] satrtTabs")
    print("-- 2. [\(uiMode.rawValue)] UImode")
    print("-- 3. [\(useOpeningAni)] use Opening Animation")
    print("-- 4. [\(useKnock)] use Konck")
    print("-- 5. [\(digitalShowRandom)] digitalShow Random")
    print("-- 6. [\(transitionRange[transitionIndex])sec] digitalShow Transition Time")
    print("-- 7. [\(userReadDone)] user Read recent notice?")
    print("-- 8. [recentAlbums: \(recentWorkAlbum.count)]")
    print("-- 9. [recentFolders: \(recentWorkFolder.count)]")
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
    case .authorized:
      if !useOpeningAni {
        loadAlbumData(step: .loadTopFolder)
      }
      PHPhotoLibrary.shared().register(self)
    default:
      PHPhotoLibrary
        .requestAuthorization(for: .readWrite) { newValue in
          switch newValue {
          case .authorized:
            DispatchQueue.main.async {
              withAnimation {
                self.phAuthorization = newValue
              }
            }
            if !self.useOpeningAni {
              self.loadAlbumData(step: .loadTopFolder)
            }
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
      let topFolder = MLFolder(folderType: .userFolder)
      topFolder.makeArray { _ in
        DispatchQueue.main.async {
          self.folders
            .updateValue(topFolder, forKey: "topFolder")
          self.loadingState = .doneTopFolder
        }
        self.loadHomeAlbumView {
          self.setEntireAlbums {
            DispatchQueue.main.async {
              withAnimation {
                self.isReadyHomeView = true
              }
            }
            self.loadShareCategories()
          }
        }
      }
    case .loadSecondaryLines:
      self.folders["topFolder"]?.foldersArray.forEach { folder in
        if let folder = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [folder.id], options: nil).firstObject {
          setFolders(folder: folder, loadSecondary: false) {
            DispatchQueue.main.async {
              self.loadingState = .doneSecondaryLines
            }
            DispatchQueue.global(qos: .background)
              .asyncAfter(deadline: .now() + 4) {
                self.setEntireFolders {}
              }
          }
        }
      }
//    case .loadAllAlbums:
//      self.setEntireAlbums {
//        
//      }
//    case .loadHomeAlbum:
//      self.loadHomeAlbumView {
//        DispatchQueue.main.async {
//          self.loadingState = .loadingComplete
//        }
//      }
    default: break
    }
  }
}
// load value
extension MLPhotoData {
  func loadHomeAlbumView(completion: @escaping () -> Void) {
    let homeAlbum = MLAlbum(isHome: true)
    homeAlbum.generateArray(isHidden: false) {
      DispatchQueue.main.async {
        withAnimation {
          self.homeAlbum = homeAlbum
        }
        completion()
      }
    }
  }
}
// shareAlbums
extension MLPhotoData {
  func saveCategoriData() {
    DispatchQueue.global(qos: .utility).async {
      let categories = self.shareCategories
                              .compactMap({ $0.value })
      let data = try! JSONEncoder().encode(categories)
      UserDefaults.standard
        .set(data, forKey: "shareCategories")
    }
  }
  func loadSharePHASsetCollection(completion: @escaping (PHFetchResult<PHAssetCollection>) -> Void) {
    let option = PHFetchOptions()
    option.wantsIncrementalChangeDetails = true
    let fetchResult = PHAssetCollection
      .fetchAssetCollections(with: .album,
                             subtype: .albumCloudShared,
                             options: option)
    completion(fetchResult)
  }
  func loadShareData() -> [ShareCategory] {
    if let loadedData = UserDefaults.standard
                        .data(forKey: "shareCategories") {
      let decoder = JSONDecoder()
      do {
        let shareCategories = try decoder
                    .decode([ShareCategory].self, from: loadedData)
        print("[공유앨범] 디코딩 완료")
        return shareCategories
      } catch {
        print("[공유앨범] 디코딩 실패 - ", String(describing: error))
        return []
      }
    } else {
      return []
    }
  }
  func loadShareCategories() {
    print("start Loading Shares")
    // Step0. 공유 앨범(PHAssetCollection) 패치
    DispatchQueue.global(qos: .utility).async {
      self.loadSharePHASsetCollection { fetchResult in
        DispatchQueue.main.async {
          self.frShares = fetchResult
        }
        // Step1. ShareCategory at UserDefaults 로드
        let loadedCategories: [ShareCategory] = self.loadShareData()
        print("category Count: \(loadedCategories.count)")
        // Step2. ShareCategory 메모리 등록
        if loadedCategories.isEmpty {
          // 비어있을 시 shareTop 생성
          let subAlbums = fetchResult
            .objects(at: IndexSet(integersIn: 0..<fetchResult.count))
            .compactMap { $0.localIdentifier }
          let shareTop = ShareCategory(id: "shareTop",
                                       title: "공유 앨범",
                                       subFolder: [],
                                       subAlbums: subAlbums)
          self.registCategory(shareTop) {
            self.registFolder()
            self.saveCategoriData()
          }
        } else {
//          self.resetCategory()
          var count = 0
          for shared in loadedCategories {
            self.registCategory(shared) {
              count += 1
              if count == loadedCategories.count {
                self.registFolder()
              }
            }
          }
        }
      }
    }
  }
  func updateCategory( _ shares: [ShareCategory],
                       completion: @escaping () -> Void) {
    for shared in shares {
      self.shareCategories
        .updateValue(shared, forKey: shared.id)
      if shared.id == shares.last?.id {
        completion()
      }
    }
    
  }
  
  func removeCategory(_ id: String,
                      completion: @escaping () -> Void) {
    DispatchQueue.main.async {
      withAnimation {
        self.shareFolders.removeValue(forKey: id)
        self.shareCategories.removeValue(forKey: id)
      }
      completion()
    }
  }
  func registCategory(_ category: ShareCategory,
                      completion: @escaping () -> Void) {
    DispatchQueue.main.async {
      self.shareCategories
        .updateValue(category, forKey: category.id)
      completion()
    }
  }
  func registFolder() {
    var tempCollection: [String: SubCollection] = [:]
    // Step3. make Subcollections
    // 3-1. folders
    for category in shareCategories.values {
      let sub = SubCollection(
        id: category.id,
        title: category.title,
        type: .folder)
      tempCollection.updateValue(sub, forKey: sub.id)
    }
    // 3-2. albums
    self.frShares.enumerateObjects { album, int, _ in
      let sub = SubCollection(
        id: album.localIdentifier,
        title: album.localizedTitle ?? "",
        type: .album)
      tempCollection.updateValue(sub, forKey: sub.id)
    }
    //Step4. shareFolders 등록
    for shared in self.shareCategories.values {
      var subCollection: [SubCollection] = shared.subFolder
        .compactMap({ tempCollection[$0] })
      let subAlbum: [SubCollection] = shared.subAlbums
        .compactMap({ tempCollection[$0]! })
      subCollection.append(contentsOf: subAlbum)
      let shFolder = MLFolder(folderType: .shareCategory,
                              shareCategory: shared,
                              subCollections: subCollection)
      DispatchQueue.main.async {
        self.shareFolders
          .updateValue(shFolder, forKey: shFolder.id)
      }
    }
  }
  func registShareAlbums() {
    DispatchQueue.global(qos: .userInitiated).async {
      let shareCategory = self.shareCategories.values
        .flatMap({ $0.subAlbums })
      self.frShares.enumerateObjects { assetCollection, _, _ in
        let album = MLAlbum(assetCollection: assetCollection,
                            albumType: .share)
        DispatchQueue.main.async {
          let _ = withAnimation {
            self.shareAlbums
              .updateValue(album, forKey: album.id)
          }
          if !shareCategory.contains(album.id) {
            self.shareCategories["shareTop"]?.subAlbums
                .append(album.id)
            let collection = SubCollection(
              id: album.id,
              title: assetCollection.localizedTitle ?? "",
              type: .album)
            withAnimation {
              self.shareFolders["shareTop"]?.albumsArray
                  .append(collection)
            }
            self.saveCategoriData()
          }
        }
      }
    }
  }
  func reOrderCategory(id: String,
                       type: CollectionType,
                       fromID: String,
                       toID: String) {
    if var category = self.shareCategories[id] {
      if type == .album {
        if let fromIndex = category.subAlbums
                      .firstIndex(where: { $0 == fromID }),
           let toIndex = category.subAlbums
                      .firstIndex(where: { $0 == toID }) {
          let desti = toIndex > fromIndex ? toIndex + 1 : toIndex
          category.subAlbums
            .move(fromOffsets: [fromIndex], toOffset: desti)
        }
      } else {
        if let
            fromIndex = category.subFolder
                      .firstIndex(where: { $0 == fromID }),
           let toIndex = category.subFolder
                      .firstIndex(where: { $0 == toID }) {
          let desti = toIndex > fromIndex ? toIndex + 1 : toIndex
          category.subFolder
            .move(fromOffsets: [fromIndex], toOffset: desti)
        }
      }
      self.shareCategories
        .updateValue(category, forKey: category.id)
      self.saveCategoriData()
    }
  }
  func removeShFolders(id: String,
                      completion: @escaping () -> Void) {
    if let _ = self.shareFolders[id] {
      DispatchQueue.main.async {
        self.shareFolders.removeValue(forKey: id)
        completion()
      }
    }
  }
  func resetCategory() {
    UserDefaults.standard
      .removeObject(forKey: "shareCategories")
  }
  func changeCategoryTitle(categoryID: String,
                           newName: String,
                           completion: @escaping () -> Void) {
    if let folder = self.mlFolder(type: .shareCategory,
                                  categoryID) {
      folder.changeCategoryTitle(newName) { newName in
        if var category = self.shareCategories[categoryID] {
          category.title = newName
          self.shareCategories
            .updateValue(category, forKey: categoryID)
          DispatchQueue.global().async {
            self.saveCategoriData()
          }
          completion()
        }
      }
    }
  }
}
// remove Value
extension MLPhotoData {
  func removeAlbumValue(album: PHAssetCollection,
                        async completion: @escaping () -> Void) {
    if let _ = self.albums[album.localIdentifier] {
      withAnimation {
        let _ = self.albums.removeValue(forKey: album.localIdentifier)
      }
      DispatchQueue.global().async {
        if let _ = self.recentWorkAlbum.firstIndex(of: album.localIdentifier) {
          self.removeRecentWork(type: .album,
                                id: album.localIdentifier)
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
          if let album = self.albums[littleAlbum.id] {
            self.removeAlbumValue(album: album.phAssetCollection) { } }
          }
      }
      if !mlFolder.foldersArray.isEmpty {
        for littleFolder in mlFolder.foldersArray {
          if let folder = self.folders[littleFolder.id] {
            self.removeFolderValue(folder: folder.phCollectionList) { }
          }
        }
      }
      withAnimation {
        let _ = self.folders.removeValue(forKey: folder.localIdentifier)
      }
      completion()
      DispatchQueue.global().async {
        if let _ = self.recentWorkFolder.firstIndex(of: folder.localIdentifier) {
          self.removeRecentWork(type: .folder,
                                id: folder.localIdentifier)
        }
      }
    }
  }
}

struct RecentItem: Codable {
  let order: Int
  let identifider: String
}

struct ShareCategory: Codable {
  let id: String
  var title: String
  var subFolder: [String]
  var subAlbums: [String]
}

struct SubCollection: Identifiable, Equatable, Hashable, Observable {
  let id : String
  let title: String
  let type: CollectionType
}

enum RecentType: CaseIterable {
  case folder, category, album
  static func key(type: Self) -> UserDefaultsKey {
    switch type {
    case .folder: return .recentFolders
    case .category: return .recentCategoris
    case .album: return .recentAlbums
    }
  }
}

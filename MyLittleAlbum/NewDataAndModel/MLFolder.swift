//
//  MLFolder.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/3/25.
//

import SwiftUI
import Photos

extension PHCollectionList: @retroactive Identifiable {}

enum FolderType {
  case userFolder, shareCategory
}

class MLFolder: NSObject, ObservableObject, Observable {
  let isSample: Bool
  let id: String
  let folderType: FolderType
  @Published var inited: Bool = false // fetch 완료 후
  @Published var title: String
  @Published var phCollectionList: PHCollectionList!
  // A: 일반 폴더용, B: 공율 앨범즈용
  var fetchResultA = PHFetchResult<PHCollection>()
  @Published var albumsArray: [SubCollection] = []
  @Published var foldersArray: [SubCollection] = []
  @State var innerProcessing: Bool = false
  
  init(folderType: FolderType = .userFolder,
       collectionList: PHCollectionList! = nil,
       shareCategory: ShareCategory! = nil,
       subCollections: [SubCollection] = []) {
    self.isSample = false
    self.folderType = folderType
    switch folderType {
    case .userFolder:
      self.id = collectionList?.localIdentifier ?? "topFolder"
      self.phCollectionList = collectionList
      self.title = collectionList?.localizedTitle ?? "마이 리틀 앨범"
      super.init()
      PHPhotoLibrary.shared().register(self)
    case .shareCategory:
      self.id = shareCategory.id
      self.title = shareCategory?.title ?? "공유 앨범"
      super.init()
    }
    fetchCollection(folderType: folderType,
                    subCollections: subCollections)
  }
  init(sampleID: Int) {
    self.isSample = true
    self.id = "folder\(sampleID)"
    self.title = "폴더\(sampleID)"
    self.folderType = .userFolder
    super.init()
  }
  deinit {
    if !isSample {
      print("deinited Folder : \(self.title)")
      PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
  }
  func fetchCollection(folderType: FolderType,
                       subCollections: [SubCollection] = []) {
    if folderType == .userFolder {
      let options = PHFetchOptions()
      options.wantsIncrementalChangeDetails = true
      if let folder = self.phCollectionList {
        self.fetchResultA = PHCollection
          .fetchCollections(in: folder, options: options)
      } else {
        self.fetchResultA = PHCollection
          .fetchTopLevelUserCollections(with: options)
      }
    } else {
      self.foldersArray = subCollections
                          .filter({ $0.type == .folder })
      self.albumsArray = subCollections
                          .filter({ $0.type == .album })
    }
    DispatchQueue.main.async {
      withAnimation {
        self.inited = true
      }
    }
  }
}
// MARK: - 1. folder Set Functions
extension MLFolder {
  func makeArray(completion: @escaping (Bool) -> Void) {
    DispatchQueue.global().async {
      var count = 0
      self.fetchResultA.enumerateObjects { collection, _, _ in
        if collection.isKind(of: PHCollectionList.self) {
          let subCollection = SubCollection(
            id: collection.localIdentifier,
            title: collection.localizedTitle ?? "unknown",
            type: .folder)
          DispatchQueue.main.async {
            withAnimation {
              self.foldersArray.append(subCollection)
            }
          }
        } else {
          let subFolder = SubCollection(
            id: collection.localIdentifier,
            title: collection.localizedTitle ?? "unknown",
            type: .album)
          DispatchQueue.main.async {
            withAnimation {
              self.albumsArray.append(subFolder)
            }
          }
        }
        count += 1
        if count == self.fetchResultA.count {
          completion(true)
        }
      }
    }
  }
  func makeArrayOutside(fetch: PHFetchResult<PHAssetCollection>,
                        completion: @escaping (Bool) -> Void) {
    DispatchQueue.global().async {
      var count = 0
      fetch.enumerateObjects { album, _, _ in
        let subAlbum = SubCollection(
          id: album.localIdentifier,
          title: album.localizedTitle ?? "",
          type: .album)
        DispatchQueue.main.async {
          self.albumsArray.append(subAlbum)
          count += 1
          if count == fetch.count {
            completion(true)
          }
        }
      }
    }
  }
}

// MARK: - 2. folder Edit Functions
extension MLFolder {
  // 타이틀 변경
  func modifyFolderTitle(_ newName: String, completion: @escaping (Bool) -> Void) {
    self.innerProcessing = true
    PHPhotoLibrary.shared().performChanges {
      guard let request = PHCollectionListChangeRequest(for: self.phCollectionList) else { return }
      request.title = newName
    } completionHandler: { [unowned self] bool, _ in
      if bool {
        DispatchQueue.main.async {
          withAnimation {
            self.title = newName
          }
        }
      }
      self.innerProcessing = false
      completion(bool)
    }
  }
  // 하위에 폴더 생성
  func createFolder(folderToAdd: PHCollectionList!,
                    _ name: String,
                    completion: @escaping (PHCollectionList?) -> Void) {
    self.innerProcessing = true
    var placeholder: PHObjectPlaceholder?
    var changeRequest: PHCollectionListChangeRequest?
    PHPhotoLibrary.shared().performChanges {
      let createFolderRequest = PHCollectionListChangeRequest
        .creationRequestForCollectionList(withTitle: name == "" ? "무제" : name)
      placeholder = createFolderRequest
        .placeholderForCreatedCollectionList
      if folderToAdd == nil {
        // TopFolder
        guard let addCollectionList = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: self.fetchResultA) else { return }
        changeRequest = addCollectionList
        print("folder is Added at Top Folder")
      } else {
        // 지정 폴더
        guard let addCollectionList = PHCollectionListChangeRequest(
          for: self.phCollectionList,
          childCollections: self.fetchResultA)
        else { return }
        changeRequest = addCollectionList
        print("folder is Added at Current Depth")
      }
      guard let addRequest = changeRequest else { return }
      addRequest.addChildCollections(
        [placeholder] as NSFastEnumeration
      )
    } completionHandler: { [unowned self] (success, error) in
      print("Finished Adding the folder. \(success ? "Success" : String(describing: error))")
      if success {
        self.fetchCollection(folderType: .userFolder)
        guard let placeholder = placeholder else { return }
        let fetchResult = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
        guard let folder = fetchResult.firstObject else { return }
        let subFolder = SubCollection(
          id: folder.localIdentifier,
          title: folder.localizedTitle ?? "unknown",
          type: .folder)
        DispatchQueue.main.async {
          withAnimation {
            let _ = self.foldersArray.append(subFolder)
          }
        }
        completion(folder)
      } else {
        completion(nil)
      }
      self.innerProcessing = false
    }
  }
  
  // 하위에 앨범 추가
  func createAlbum(folderToAdd: PHCollectionList!,
                   _ name: String,
                   completion: @escaping (PHAssetCollection?) -> Void) {
    self.innerProcessing = true
    var placeholder: PHObjectPlaceholder?
    var changeRequest: PHCollectionListChangeRequest?
    PHPhotoLibrary.shared().performChanges {
      let createAlbumRequest = PHAssetCollectionChangeRequest
        .creationRequestForAssetCollection(
          withTitle: name == "" ? "무제" : name)
      placeholder = createAlbumRequest
        .placeholderForCreatedAssetCollection
      if folderToAdd == nil {
        // Top Folder
        guard let addAssetCollection = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: self.fetchResultA) else { return }
        changeRequest = addAssetCollection
        print("Request Adding an Album at Top Folder")
      } else {
        // 지정 Folder
        guard let addAssetCollection = PHCollectionListChangeRequest(
          for: self.phCollectionList,
          childCollections: self.fetchResultA) else { return }
        changeRequest = addAssetCollection
        print("Request Adding an Album at Current Depth")
      }
      guard let addRequest = changeRequest else { return }
      addRequest.addChildCollections([placeholder] as NSFastEnumeration)
    } completionHandler: { [unowned self] (success, error) in
      print("Finished Adding the album. \(success ? "Success" : String(describing: error))")
      if success {
        self.fetchCollection(folderType: .userFolder)
        guard let placeholder = placeholder else { return }
        let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
        guard let album = fetchResult.firstObject else { return }
        let subAlbum = SubCollection(id: album.localIdentifier,
                                     title: album.localizedTitle ?? "unknown",
                                     type: .album)
        DispatchQueue.main.async {
          withAnimation {
            let _ = self.albumsArray.append(subAlbum)
          }
        }
        completion(album)
      } else {
        completion(nil)
      }
      self.innerProcessing = false
    }
  }
  
  
  // 하위 폴더 삭제
  func deleteFolder(folder: PHCollectionList,
                    completion: @escaping (Bool) -> Void) {
    self.innerProcessing = true
    PHPhotoLibrary.shared().performChanges ({
      PHCollectionListChangeRequest
        .deleteCollectionLists([folder] as! NSFastEnumeration)
    }) { [unowned self] (success, error) in
      print("Finished removing the folder [\(folder.localizedTitle ?? "")] from the [\(self.title)]folder. \(success ? "Success" : String(describing: error))")
      if success {
        self.fetchCollection(folderType: .userFolder)
        if let index = self.foldersArray
          .compactMap({ $0.id })
          .firstIndex(of: folder.localIdentifier) {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
              let _ = self.foldersArray.remove(at: index)
            }
          }
        }
      }
      self.innerProcessing = false
      completion(success)
    }
  }
  // 하위 앨범 삭제
  func deleteAlbum(album: PHAssetCollection,
                   completion: @escaping (Bool) -> Void) {
    self.innerProcessing = true
    PHPhotoLibrary.shared().performChanges ({
      PHAssetCollectionChangeRequest
        .deleteAssetCollections([album] as! NSFastEnumeration)
    }) { [unowned self] (success, error) in
      if success {
        print("Finished removing the album [\(album.localizedTitle ?? "")] from the [\(self.title)]folder. \(success ? "Success" : String(describing: error))")
        self.fetchCollection(folderType: .userFolder)
        if let index = self.albumsArray
          .compactMap({ $0.id })
          .firstIndex(of: album.localIdentifier) {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
              let _ = self.albumsArray.remove(at: index)
            }
          }
        }
      }
      completion(success)
      self.innerProcessing = false
    }
  }
  // 하위 콜렉션 순서 교체
  func moveCollection(from: IndexSet, to: Int, completion: @escaping (Bool) -> Void) {
    self.innerProcessing = true
    var moveRequest: PHCollectionListChangeRequest?
    PHPhotoLibrary.shared().performChanges ({
      if self.phCollectionList == nil {
        moveRequest = PHCollectionListChangeRequest(
          forTopLevelCollectionListUserCollections: self.fetchResultA)
      } else {
        moveRequest = PHCollectionListChangeRequest(
          for: self.phCollectionList,
          childCollections: self.fetchResultA)
      }
      withAnimation {
        moveRequest?.moveChildCollections(at: from, to: to)
      }
    }) { [unowned self] (success, error) in
      print("Finished Reordeing Collections in folder. \(success ? "Success" : String(describing: error))")
      if success {
        self.fetchCollection(folderType: .userFolder)
      }
      self.innerProcessing = false
      completion(success)
    }
  }
  // 이 폴더의 하위로 콜렉션 옮기기
  func displaceCollelction(collectionType: CollectionType,
                           collection: PHCollection,
                           completion: @escaping (Bool) -> Void) {
    self.innerProcessing = true
    PHPhotoLibrary.shared().performChanges {
      var addRequest: PHCollectionListChangeRequest
      if self.phCollectionList == nil {
        addRequest = PHCollectionListChangeRequest(
          forTopLevelCollectionListUserCollections: self.fetchResultA) ?? PHCollectionListChangeRequest()
      } else {
        addRequest = PHCollectionListChangeRequest(
          for: self.phCollectionList,
          childCollections: self.fetchResultA) ?? PHCollectionListChangeRequest()
      }
      addRequest.addChildCollections([collection] as NSFastEnumeration)
    } completionHandler: { [unowned self] success, _ in
      if success {
        self.fetchCollection(folderType: .userFolder)
        if collectionType == .album {
          let subAlbum = SubCollection(
            id: collection.localIdentifier,
            title: collection.localizedTitle ?? "unknown",
            type: .album)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
              self.albumsArray.append(subAlbum)
            }
          }
        } else {
          let subFolder = SubCollection(
            id: collection.localIdentifier,
            title: collection.localizedTitle ?? "unknown",
            type: .folder)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
              self.foldersArray.append(subFolder)
            }
          }
        }
      }
      self.innerProcessing = false
      completion(success)
    }
  }
  
  func findIndexA(afterFetch: PHFetchResult<PHCollection>,
                  isFolder: Bool,
                  folder: PHCollectionList! = nil,
                  album: PHAssetCollection! = nil) -> Int! {
    let array = afterFetch
      .objects(at: IndexSet(integersIn: 0..<afterFetch.count))
      .filter {
        $0.isKind(of: isFolder ? PHCollectionList.self : PHAssetCollection.self)
      }
    let index = array.firstIndex(of: isFolder ? folder : album)
    return index
  }
  func appendAlbumInArray(album: PHAssetCollection,
                          completion: @escaping () -> Void) {
    let offsetCount = albumsArray.count
    let subAlbum = SubCollection(id: album.localIdentifier,
                                 title: album.localizedTitle ?? "unknown",
                                 type: .album)
    DispatchQueue.main.async {
      withAnimation {
        self.albumsArray.append(subAlbum)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
          withAnimation {
            self.albumsArray
              .move(fromOffsets: IndexSet(integer: offsetCount),
                    toOffset: 0)
          }
        }
        
      }
      completion()
    }
  }
  func removeAlbumInArray(album: PHAssetCollection) {
    if let index = self.albumsArray
      .compactMap({ $0.id })
      .firstIndex(of: album.localIdentifier) {
      DispatchQueue.main.async {
        let _ = withAnimation {
          self.albumsArray.remove(at: index)
        }
      }
    } 
  }
}

// sh category 처리
extension MLFolder {
  func removeCategory(id: String,
                      collectionType: CollectionType,
                      completion: @escaping (SubCollection) -> Void) {
    if collectionType == .folder {
      if let index = self.foldersArray
                  .compactMap({ $0.id })
                  .firstIndex(of: id) {
        DispatchQueue.main.async {
          withAnimation {
            let collection = self.foldersArray.remove(at: index)
            completion(collection)
          }
        }
      }
    } else {
      if let index = self.albumsArray
                  .compactMap({ $0.id })
                  .firstIndex(of: id) {
        DispatchQueue.main.async {
          withAnimation {
            let collection = self.albumsArray.remove(at: index)
            completion(collection)
          }
        }
      }
    }
  }
  func changeCategoryTitle(_ newName: String, completion: @escaping (String) -> Void) {
    DispatchQueue.main.async {
      withAnimation {
        self.title = newName
      }
      completion(newName)
    }
  }
  func addSubCollection(type: CollectionType,
                        collection: SubCollection,
                        completion: @escaping () -> Void) {
    if type == .folder {
      DispatchQueue.main.async {
        withAnimation {
          self.foldersArray.append(collection)
        }
        completion()
      }
    } else {
      DispatchQueue.main.async {
        withAnimation {
          self.albumsArray.append(collection)
        }
        completion()
      }
    }
  }
  func removeSubCollection(type: CollectionType,
                           id: String,
                           completion: @escaping () -> Void) {
    if type == .folder {
      if let index = self.foldersArray
                        .compactMap({ $0.id })
                        .firstIndex(of: id) {
        DispatchQueue.main.async {
          let _ = withAnimation {
            self.foldersArray.remove(at: index)
          }
          completion()
        }
      }
    } else {
      if let index = self.albumsArray
                      .compactMap({ $0.id })
                      .firstIndex(of: id) {
        DispatchQueue.main.async {
          let _ = withAnimation {
            self.albumsArray.remove(at: index)
          }
          completion()
        }
      }
    }
  }
  func changeSubTitle(type: CollectionType, id: String, newTitle: String) {
    let newSub = SubCollection(id: id, title: newTitle, type: type)
    if type == .album {
      if let index = self.albumsArray.firstIndex(of: newSub) {
        self.albumsArray[index] = newSub
      }
    } else {
      if let index = self.foldersArray.firstIndex(of: newSub) {
        self.albumsArray[index] = newSub
      }
    }
  }
  func subCollection(id: String, type: CollectionType) -> SubCollection {
    if self.id == id {
      let sub = SubCollection(id: self.id,
                              title: self.title,
                              type: .folder)
      return sub
    } else {
      if type == .album {
        if let index = self.albumsArray
                      .firstIndex(where: { $0.id == id }) {
          return self.albumsArray[index]
        } else {
          return SubCollection(id: id, title: "", type: .album)
        }
      } else {
        if let index = self.foldersArray
                      .firstIndex(where: { $0.id == id }) {
          return self.foldersArray[index]
        } else {
          return SubCollection(id: id, title: "", type: .folder)
        }
      }
    }
  }
}

// MARK: - 3. change Observer
extension MLFolder: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_ change: PHChange) {
    if self.innerProcessing == false {
      if self.phCollectionList != nil {
        if let folder = change.changeDetails(for: self.phCollectionList) {
          if folder.objectAfterChanges?.localizedTitle != self.title {
            DispatchQueue.main.async {
              withAnimation {
                self.title = folder.objectAfterChanges?.localizedTitle ?? self.title
              }
            }
          }
        }
      }
      
      if let change = change.changeDetails(for: self.fetchResultA) {
        if self.fetchResultA.count != change.fetchResultAfterChanges.count &&
            change.fetchResultAfterChanges.count != 0 {
          DispatchQueue.main.async { [unowned self] in
            self.fetchResultA = change.fetchResultAfterChanges
            print("folder \(self.title) fetchResult changed")
          }
          // 삽입
          for collection in change.insertedObjects {
            if let folder = collection as? PHCollectionList {
              if self.foldersArray
                .compactMap({ $0.id })
                .firstIndex(of: folder.localIdentifier) == nil {
                if let _ = findIndexA(
                  afterFetch: change.fetchResultAfterChanges,
                  isFolder: true,
                  folder: folder) {
                  let subFolder = SubCollection(
                    id: folder.localIdentifier,
                    title: folder.localizedTitle ?? "unknown",
                    type: .folder)
                  DispatchQueue.main.async { [unowned self] in
                    withAnimation {
                      self.foldersArray.insert(subFolder, at: 0)
                      //                                        self.foldersArray.append(folder)
                      //                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) { [unowned self] in
                      //                                            self.foldersArray.move(fromOffsets: [self.foldersArray.count-1],
                      //                                                                  toOffset: index)
                      //                                        }
                    }
                  }
                }
              }
            } else if let album = collection as? PHAssetCollection {
              if self.albumsArray
                .compactMap({ $0.id })
                .firstIndex(of: album.localIdentifier) == nil {
                if let index = findIndexA(
                  afterFetch: change.fetchResultAfterChanges,
                  isFolder: false,
                  album: album) {
                  let subAlbum = SubCollection(
                    id: album.localIdentifier,
                    title: album.localizedTitle ?? "unknown",
                    type: .album)
                  DispatchQueue.main.async { [unowned self] in
                    withAnimation {
                      self.albumsArray.append(subAlbum)
                      DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) { [unowned self] in
                        self.albumsArray
                          .move(fromOffsets: [self.albumsArray.count-1],
                                toOffset: index)
                      }
                    }
                  }
                }
              }
            }
          }
          // 제거
          for collection in change.removedObjects.reversed() {
            print("제거 at: \(self.title) what: \(collection.localizedTitle ?? "ad")")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              if let folder = collection as? PHCollectionList,
                 let index = self.foldersArray
                .compactMap({ $0.id })
                .firstIndex(of: folder.localIdentifier) {
                DispatchQueue.main.async { [unowned self] in
                  withAnimation {
                    let _ = self.foldersArray.remove(at: index)
                  }
                }
              } else if let album = collection as? PHAssetCollection,
                        let index = self.albumsArray
                .compactMap({ $0.id })
                .firstIndex(of: album.localIdentifier) {
                DispatchQueue.main.async { [unowned self] in
                  withAnimation {
                    let _ = self.albumsArray.remove(at: index)
                  }
                  NotificationCenter.default
                    .post(name: .outsideFetchChange, object: "myPhotos")
                }
              }
            }
          }
          // 교체
          //                for collection in change.changedObjects {
          //                    print("교체 : \(collection.localizedTitle ?? "")")
          //                    if let folder = collection as? PHCollectionList,
          //                       let index = self.foldersArray.firstIndex(of: folder) {
          //                            DispatchQueue.main.async { [unowned self] in
          //                                withAnimation {
          //                                    self.foldersArray
          //                                        .replace([self.foldersArray[index]], with: [folder])
          //                                }
          //                            }
          //                    } else if let album = collection as? PHAssetCollection,
          //                              let index = self.albumsArray.firstIndex(of: album) {
          //                        DispatchQueue.main.async { [unowned self] in
          //                            withAnimation {
          //                                self.albumsArray
          //                                    .replace([self.albumsArray[index]], with: [album])
          //                            }
          //                        }
          //                    }
          //                }
        }
      }
    }
  }
}

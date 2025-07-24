//
//  MLFolder.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/3/25.
//

import SwiftUI
import Photos

extension PHCollectionList: @retroactive Identifiable {}

struct MLAssetCollection {
    
}

class MLFolder: NSObject, ObservableObject, Observable {
    let isSample: Bool
    let id: String
    @Published var title: String
    @Published var phCollectionList: PHCollectionList!
    var fetchResult = PHFetchResult<PHCollection>()
    
    @Published var albumsArray: [PHAssetCollection] = []
    @Published var foldersArray: [PHCollectionList] = [] 
    
    init(collectionList: PHCollectionList!) {
        self.isSample = false
        self.id = collectionList?.localIdentifier ?? "topFolder"
        self.phCollectionList = collectionList
        self.title = collectionList?.localizedTitle ?? "마이 리틀 앨범"
        super.init()
        PHPhotoLibrary.shared().register(self)
        fetchCollection()
    }
    init(sampleID: Int) {
        self.isSample = true
        self.id = "folder\(sampleID)"
        self.title = "폴더\(sampleID)"
        super.init()
    }
    deinit {
        if !isSample {
            print("deinited Folder : \(self.title)")
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    func fetchCollection() {
        let options = PHFetchOptions()
        options.wantsIncrementalChangeDetails = true
        if let folder = self.phCollectionList {
            self.fetchResult = PHCollection
                .fetchCollections(in: folder, options: options)
        } else {
            self.fetchResult = PHCollection
                .fetchTopLevelUserCollections(with: options)
        }
    }
}
// MARK: - 1. folder Set Functions
extension MLFolder {
    func makeArray(completion: @escaping (Bool) -> Void) {
        var count = 0
        self.fetchResult.enumerateObjects { collection, _, _ in
            if collection.isKind(of: PHCollectionList.self) {
                DispatchQueue.main.async {
                    self.foldersArray.append(collection as! PHCollectionList)
                }
            } else {
                DispatchQueue.main.async {
                    self.albumsArray.append(collection as! PHAssetCollection)
                }
            }
            count += 1
            if count == self.fetchResult.count {
                completion(true)
            }
        }
    }
}

enum CategoryType {
    case all, folder, album
}
// MARK: - 2. folder Edit Functions
extension MLFolder {
    // 타이틀 변경
    func modifyFolderTitle(_ newName: String, completion: @escaping (Bool) -> Void) {
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
            completion(bool)
        }
    }
    // 하위에 폴더 생성
    func createFolder(folderToAdd: PHCollectionList!,
                      _ name: String,
                      completion: @escaping (PHCollectionList?) -> Void) {
        var placeholder: PHObjectPlaceholder?
        var changeRequest: PHCollectionListChangeRequest?
        PHPhotoLibrary.shared().performChanges {
            let createFolderRequest = PHCollectionListChangeRequest
                .creationRequestForCollectionList(withTitle: name == "" ? "무제" : name)
            placeholder = createFolderRequest
                .placeholderForCreatedCollectionList
            if folderToAdd == nil {
                // TopFolder
                guard let addCollectionList = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: self.fetchResult ) else { return }
                changeRequest = addCollectionList
                print("folder is Added at Top Folder")
            } else {
                // 지정 폴더
                guard let addCollectionList = PHCollectionListChangeRequest(
                    for: self.phCollectionList,
                    childCollections: self.fetchResult)
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
                self.fetchCollection()
                guard let placeholder = placeholder else { return }
                let fetchResult = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let folder = fetchResult.firstObject else { return }
                DispatchQueue.main.async {
                    withAnimation {
                        let _ = self.foldersArray.append(folder)
                    }
                }
                completion(folder)
            } else {
                completion(nil)
            }
        }
    }
    
    // 하위에 앨범 추가
    func createAlbum(folderToAdd: PHCollectionList!,
                     _ name: String,
                     completion: @escaping (PHAssetCollection?) -> Void) {
        var placeholder: PHObjectPlaceholder?
        var changeRequest: PHCollectionListChangeRequest?
        PHPhotoLibrary.shared().performChanges {
            let createAlbumRequest = PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(withTitle: name == "" ? "무제" : name)
            placeholder = createAlbumRequest
                .placeholderForCreatedAssetCollection
            if folderToAdd == nil {
                // Top Folder
                guard let addAssetCollection = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: self.fetchResult) else { return }
                changeRequest = addAssetCollection
                print("Request Adding an Album at Top Folder")
            } else {
                // 지정 Folder
                guard let addAssetCollection = PHCollectionListChangeRequest(
                    for: self.phCollectionList,
                    childCollections: self.fetchResult) else { return }
                changeRequest = addAssetCollection
                print("Request Adding an Album at Current Depth")
            }
            guard let addRequest = changeRequest else { return }
            addRequest.addChildCollections([placeholder] as NSFastEnumeration)
        } completionHandler: { [unowned self] (success, error) in
            print("Finished Adding the album. \(success ? "Success" : String(describing: error))")
            if success {
                self.fetchCollection()
                guard let placeholder = placeholder else { return }
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let album = fetchResult.firstObject else { return }
                DispatchQueue.main.async {
                    withAnimation {
                        let _ = self.albumsArray.append(album)
                    }
                }
                completion(album)
            } else {
                completion(nil)
            }
            
        }
    }
    
    
    // 하위 폴더 삭제
    func deleteFolder(folder: PHCollectionList,
                      completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges ({
            PHCollectionListChangeRequest
                .deleteCollectionLists([folder] as! NSFastEnumeration)
        }) { [unowned self] (success, error) in
            print("Finished removing the folder [\(folder.localizedTitle ?? "")] from the [\(self.title)]folder. \(success ? "Success" : String(describing: error))")
            if success {
                self.fetchCollection()
                if let index = self.foldersArray.firstIndex(of: folder) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            let _ = self.foldersArray.remove(at: index)
                        }
                    }
                }
            }
            completion(success)
        }
    }
    // 하위 앨범 삭제
    func deleteAlbum(album: PHAssetCollection,
                     completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges ({
            PHAssetCollectionChangeRequest
                .deleteAssetCollections([album] as! NSFastEnumeration)
        }) { [unowned self] (success, error) in
            if success {
                print("Finished removing the album [\(album.localizedTitle ?? "")] from the [\(self.title)]folder. \(success ? "Success" : String(describing: error))")
                self.fetchCollection()
                if let index = self.albumsArray.firstIndex(of: album) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            let _ = self.albumsArray.remove(at: index)
                        }
                    }
                }
            }
            completion(success)
        }
    }
    // 하위 콜렉션 순서 교체
    func moveCollection(from: IndexSet, to: Int, completion: @escaping (Bool) -> Void) {
        var moveRequest: PHCollectionListChangeRequest?
        PHPhotoLibrary.shared().performChanges ({
            if self.phCollectionList == nil {
                moveRequest = PHCollectionListChangeRequest(
                    forTopLevelCollectionListUserCollections: self.fetchResult)
            } else {
                moveRequest = PHCollectionListChangeRequest(
                    for: self.phCollectionList,
                    childCollections: self.fetchResult)
            }
            withAnimation {
                moveRequest?.moveChildCollections(at: from, to: to)
            }
        }) { [unowned self] (success, error) in
            print("Finished Reordeing Collections in folder. \(success ? "Success" : String(describing: error))")
            if success {
                self.fetchCollection()
            }
            completion(success)
        }
    }
    // 이 폴더의 하위로 콜렉션 옮기기
    func displaceCollelction(collectionType: CollectionType,
                             collection: PHCollection,
                             completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            var addRequest: PHCollectionListChangeRequest
            if self.phCollectionList == nil {
                addRequest = PHCollectionListChangeRequest(
                    forTopLevelCollectionListUserCollections: self.fetchResult) ?? PHCollectionListChangeRequest()
            } else {
                addRequest = PHCollectionListChangeRequest(
                    for: self.phCollectionList,
                    childCollections: self.fetchResult) ?? PHCollectionListChangeRequest()
            }
            addRequest.addChildCollections([collection] as NSFastEnumeration)
        } completionHandler: { [unowned self] success, _ in
            if success {
                self.fetchCollection()
                if collectionType == .album {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            self.albumsArray.append(collection as! PHAssetCollection)
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            self.foldersArray.append(collection as! PHCollectionList)
                        }
                    }
                }
            }
            completion(success)
        }
    }
    
    func findIndex(afterFetch: PHFetchResult<PHCollection>,
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
}
// MARK: - 3. change Observer
extension MLFolder: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ change: PHChange) {
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
        
        if let change = change.changeDetails(for: self.fetchResult) {
            if self.fetchResult.count != change.fetchResultAfterChanges.count &&
                change.fetchResultAfterChanges.count != 0 {
                DispatchQueue.main.async { [unowned self] in
                    self.fetchResult = change.fetchResultAfterChanges
                    print("folder \(self.title) fetchResult changed")
                }
                // 삽입
                for collection in change.insertedObjects {
                    if let folder = collection as? PHCollectionList {
                        if self.foldersArray.firstIndex(of: folder) == nil {
                            if let index = findIndex(
                                afterFetch: change.fetchResultAfterChanges,
                                isFolder: true,
                                folder: folder) {
                                DispatchQueue.main.async { [unowned self] in
                                    withAnimation {
                                        self.foldersArray.insert(folder, at: 0)
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
                        if self.albumsArray.firstIndex(of: album) == nil {
                            if let index = findIndex(
                                afterFetch: change.fetchResultAfterChanges,
                                isFolder: false,
                                album: album) {
                                DispatchQueue.main.async { [unowned self] in
                                    withAnimation {
                                        self.albumsArray.append(album)
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
                           let index = self.foldersArray.firstIndex(of: folder) {
                            DispatchQueue.main.async { [unowned self] in
                                withAnimation {
                                    let _ = self.foldersArray.remove(at: index)
                                }
                            }
                        } else if let album = collection as? PHAssetCollection,
                                  let index = self.albumsArray.firstIndex(of: album) {
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

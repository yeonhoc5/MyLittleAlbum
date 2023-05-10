//
//  FolderModel.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/26.
//

import SwiftUI
import Photos

// MARK: - 1. [Folder] Class
class Folder: NSObject, Identifiable, ObservableObject {
    
    var isHome: Bool = false
    var folder: PHCollectionList!
    let id: UUID = UUID()
    var identifier: String = ""
    @Published var title: String = ""
    var colorIndex: Int = 0
    @Published var fetchResult = PHFetchResult<PHCollection>()
    @Published var albumArray = [PHAssetCollection]()
    @Published var folderArray = [PHCollectionList]()
    @Published var countAlbum: Int = 0
    @Published var countFolder: Int = 0
    
    var placeholder: PHObjectPlaceholder?
    var changeRequest: PHCollectionListChangeRequest?
    
    init(isHome: Bool! = false, folder: PHCollectionList! = nil, fetchResult: PHFetchResult<PHCollection>! = nil, colorIndex: Int = 0) {
        super.init()
        PHPhotoLibrary.shared().register(self)
        self.isHome = isHome
        if isHome {
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = false
            fetchOptions.wantsIncrementalChangeDetails = true
            self.fetchResult = fetchResult ?? PHCollection.fetchTopLevelUserCollections(with: fetchOptions)
        } else {
            self.folder = folder
            self.identifier = folder.localIdentifier
            self.title = folder.localizedTitle ?? ""
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = false
            fetchOptions.wantsIncrementalChangeDetails = true
            self.fetchResult = PHCollection.fetchCollections(in: folder, options: fetchOptions)
        }
        self.colorIndex = colorIndex
        refreshFolderModel(self.fetchResult)
        //        print("폴더 init 체크 \(self.title)")
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func renewFetchResult() {
        DispatchQueue.main.async {
            if self.isHome {
                self.fetchResult = PHCollection.fetchTopLevelUserCollections(with: nil)
            } else {
                let fetchOptions = PHFetchOptions()
                fetchOptions.includeHiddenAssets = false
                fetchOptions.wantsIncrementalChangeDetails = true
                self.fetchResult = PHCollection.fetchCollections(in: self.folder, options: fetchOptions)
            }
            self.refreshFolderModel(self.fetchResult)
        }
    }
    
    func refreshFolderModel(_ newFetchResult: PHFetchResult<PHCollection>) {
        withAnimation(.interactiveSpring()) {
            let albumFetch = newFetchResult.objects(at: IndexSet(integersIn: 0..<newFetchResult.count)).filter{$0.isKind(of: PHAssetCollection.self
            )}
            let folderFetcth = newFetchResult.objects(at: IndexSet(integersIn: 0..<newFetchResult.count)).filter{$0.isKind(of: PHCollectionList.self
            )}
            self.albumArray = Array(albumFetch.map{$0 as! PHAssetCollection})
            self.folderArray = Array(folderFetcth.map{$0 as! PHCollectionList})
            self.countAlbum = self.albumArray.count
            self.countFolder = self.folderArray.count
        }
    }
    
    func refreshAlbumList(_ newFetchResult: PHFetchResult<PHCollection>) {
        let albumFetch = newFetchResult.objects(at: IndexSet(integersIn: 0..<newFetchResult.count)).filter{$0.isKind(of: PHAssetCollection.self
        )}
        self.albumArray = Array(albumFetch.map{$0 as! PHAssetCollection})
        self.countAlbum = self.albumArray.count
    }
    func refreshFolderList(_ newFetchResult: PHFetchResult<PHCollection>) {
        let folderFetcth = newFetchResult.objects(at: IndexSet(integersIn: 0..<newFetchResult.count)).filter{$0.isKind(of: PHCollectionList.self
        )}
        self.folderArray = Array(folderFetcth.map{$0 as! PHCollectionList})
        self.countFolder = self.folderArray.count
    }
    
}

// MARK: - 2. extenstion [Folder] 폴더 함수
extension Folder {
    
    // 하위에 폴더 생성
    func createFolder(depth: DepthType, folderToAdd: PHCollectionList!, _ name: String, completion: @escaping (Bool?) -> Void) {
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges {
                let createFolderRequest = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: name)
                self.placeholder = createFolderRequest.placeholderForCreatedCollectionList
    //            guard let placeholder = self.placeholder else { return }
    //            let fetchResult = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                switch depth {
                case .current:
                    if self.isHome {
                        guard let addCollectionList = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: self.fetchResult ) else { return }
                        self.changeRequest = addCollectionList
                        print("folder is Added at Top Folder")
                    } else {
                        guard let addCollectionList = PHCollectionListChangeRequest(for: self.folder, childCollections: self.fetchResult ) else { return }
                        self.changeRequest = addCollectionList
                        print("folder is Added at Current Depth")
                    }
                case .secondary:
                    let index = self.fetchResult.index(of: folderToAdd)
                    let secondFolder = self.fetchResult[index] as! PHCollectionList
                    let secondFetchResult = PHCollectionList.fetchCollections(in: secondFolder, options: nil)
                    guard let addCollectionList = PHCollectionListChangeRequest(for: secondFolder, childCollections: secondFetchResult ) else { return }
                    self.changeRequest = addCollectionList
                    print("folder is Added at Secondary Depth")
                default:
                    if let thirdFolder = folderToAdd {
                        let thirdFetchResult = PHCollectionList.fetchCollections(in: thirdFolder, options: nil)
                        guard let addCollectionList = PHCollectionListChangeRequest(for: thirdFolder, childCollections: thirdFetchResult ) else { return }
                        self.changeRequest = addCollectionList
                        print("folder is Added at Third Depth")
                    }
                }
                guard let addRequest = self.changeRequest else { return }
                addRequest.addChildCollections([self.placeholder] as NSFastEnumeration)
            } completionHandler: { (success, error) in
                print("Finished Adding the folder. \(success ? "Success" : String(describing: error))")
    //            guard let placeholder = self.placeholder else { return }
    //            let fetchResult = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
    //            guard let folder = fetchResult.firstObject else { return }
                self.changeRequest = nil
                completion(success)
            }
        }
    }
    // 하위에 앨범 생성
    func createAlbum(depth: DepthType, folderToAdd: PHCollectionList!, _ name: String, completion: @escaping (PHAssetCollection?) -> Void) {
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges {
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                self.placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
                switch depth {
                case .current:
                    if self.isHome {
                        guard let addAssetCollection = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: self.fetchResult) else { return }
                        self.changeRequest = addAssetCollection
                        print("album is Added at Top Folder")
                    } else {
                        guard let firstFolder = folderToAdd,
                              let addAssetCollection = PHCollectionListChangeRequest(for: firstFolder, childCollections: self.fetchResult) else { return }
                        self.changeRequest = addAssetCollection
                        print("album is Added at Current Depth")
                    }
                case .secondary:
                    let index = self.fetchResult.index(of: folderToAdd)
                    let secondFolder = self.fetchResult[index] as! PHCollectionList
                    let secondFetchResult = PHCollectionList.fetchCollections(in: secondFolder, options: nil)
                    guard let addAssetCollection = PHCollectionListChangeRequest(for: secondFolder, childCollections: secondFetchResult) else { return }
                    self.changeRequest = addAssetCollection
                    print("album is Added at Secondary Depth")
                default:
                    if let thirdFolder = folderToAdd {
                        let thirdFetchResult = PHCollectionList.fetchCollections(in: thirdFolder, options: nil)
                        guard let addAssetCollection = PHCollectionListChangeRequest(for: thirdFolder, childCollections: thirdFetchResult) else { return }
                        self.changeRequest = addAssetCollection
                        print("album is Added at Third Folder")
                    }
                }
                self.changeRequest?.addChildCollections([createAlbumRequest.placeholderForCreatedAssetCollection] as NSArray)
            } completionHandler: { (success, error) in
                print("Finished Adding the album. \(success ? "Success" : String(describing: error))")
                guard let placeholder = self.placeholder else { return }
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let album = fetchResult.firstObject else { return }
                completion(album)
                self.changeRequest = nil
            }
        }
    }
    // 폴더 삭제
    func deleteFolder(folder: PHCollectionList!, completion: @escaping (Bool?) -> Void) {
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges ({
                PHCollectionListChangeRequest.deleteCollectionLists([folder] as! NSFastEnumeration)
            }) { (success, error) in
                print("Finished removing the album from the folder. \(success ? "Success" : String(describing: error))")
                completion(success)
            }
        }
    }
    // 폴더 / 앨범 순서 변경
    func moveCollection(from: IndexSet, to: Int, completion: @escaping (PHFetchResult<PHCollection>?) -> Void) {
        var moveRequest: PHCollectionListChangeRequest?
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges ({
                if self.isHome {
                    moveRequest = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: self.fetchResult)
                } else {
                    moveRequest = PHCollectionListChangeRequest(for: self.folder, childCollections: self.fetchResult)
                }
                withAnimation {
                    moveRequest?.moveChildCollections(at: from, to: to)
                }
                
            }) { (success, error) in
                print("Finished Reordeing Collections in folder. \(success ? "Success" : String(describing: error))")
                if success {
                    DispatchQueue.main.async {
                        self.renewFetchResult()
                    }
                    
//                    if let folder = self.folder {
//                        PHCollectionList.fetchCollections(in: folder, options: nil)
//                    } else {
//                        PHCollectionList.fetchTopLevelUserCollections(with: nil)
//                    }
//                    completion(newFetchResult)
                }
                
            }
        }
    }
    
}
// MARK: - 3. extenstion [Folder] change observer
extension Folder: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let folder = self.folder {
            print("Change 옵저버 [FOLDER] 1")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let change = changeInstance.changeDetails(for: folder) {
                    let newFolder = change.objectAfterChanges
                    self.folder = newFolder
                    self.title = newFolder?.localizedTitle ?? ""
                }
            }
        }
        
        if let detail = changeInstance.changeDetails(for: self.fetchResult) {
            print("Change 옵저버 [FOLDER] 2")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let newFetchResult: PHFetchResult<PHCollection>!
                if let folder = self.folder {
                    newFetchResult = PHCollection.fetchCollections(in: folder, options: nil)
                } else {
                    newFetchResult = PHCollection.fetchTopLevelUserCollections(with: nil)
                }
                self.fetchResult = newFetchResult
                DispatchQueue.main.async {
                    self.checkAlbumArray(detail: detail, newFetchResult: newFetchResult)
                }
                DispatchQueue.main.async {
                    self.checkFolderArray(detail: detail, newFetchResult: newFetchResult)
                }
            }
        }
    }
    
    func checkAlbumArray(detail: PHFetchResultChangeDetails<PHCollection>, newFetchResult: PHFetchResult<PHCollection>) {
        if detail.insertedObjects.first?.isKind(of: PHAssetCollection.self) == true
            || detail.removedObjects.first?.isKind(of: PHAssetCollection.self) == true
            || detail.changedObjects.first?.isKind(of: PHAssetCollection.self) == true {
            print("Change 옵저버 [FOLDER] 3")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.8)) {
                    self.refreshAlbumList(newFetchResult)
                }
            }
        }
    }

    func checkFolderArray(detail: PHFetchResultChangeDetails<PHCollection>, newFetchResult: PHFetchResult<PHCollection>) {
        if detail.insertedObjects.first?.isKind(of: PHCollectionList.self) == true
            || detail.removedObjects.first?.isKind(of: PHCollectionList.self) == true
            || detail.changedObjects.first?.isKind(of: PHCollectionList.self) == true {
            print("Change 옵저버 [FOLDER] 4")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.8)) {
                    self.refreshFolderList(newFetchResult)
                }
            }
        }
    }
}

//
//  CollectionAlertModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import SwiftUI
import Photos

struct CollectionAlertModifier: ViewModifier {
  let notificationName: Notification.Name
  let isHiddenAsset: Bool
  @EnvironmentObject var photoData: MLPhotoData
  @Environment(\.colorScheme) var colorScheme
  @State var editAlert: EditAlert!
  @State var newText: String = ""
  
  func body(content: Content) -> some View {
    let title = editAlert?.title ?? ""
    let show: Bool = editAlert != nil
    
    content
      .alert(title, isPresented: .constant(show)) {
        textFieldInNeeds()
        btnCancelAndClose()
        btnAlertAction()
      } message: {
        let message = editAlert?.message ?? ""
        Text(message != "" ? ("\n" + (message)) : "")
      }
      .onReceive(NotificationCenter.default
        .publisher(for: notificationName),
                 perform: { output in
          if let alertObject = output.object as? AlertObject {
            handleAlertObject(alertObject)
          }
        })
  }
}

extension CollectionAlertModifier {
  func handleAlertObject(_ object: AlertObject) {
    let alertCase = object.alertCase
    self.newText = changeNewText(alertCase,
                                 folderType: object.folderType,
                            folderID: object.folderID,
                            albumID: object.albumID)
    let album = switch object.albumType {
    case .share: photoData.shareAlbums[object.albumID ?? ""]
    case .home, .picker: photoData.homeAlbum
    default: photoData.albums[object.albumID ?? ""]
    }
    let folder = photoData.mlFolder(type: object.folderType,
                                    object.folderID ?? "")
    let title = configTitle(alertCase,
                title: object.title)
    let edit = EditAlert(
      alertCase: alertCase,
      title: title,
      message: configMessage(alertCase,
                             folderType: object.folderType,
                             folderID: object.folderID,
                             albumID: object.albumID),
      placeHolder: configPlaceHolder(alertCase,
                                     folderID: object.folderID,
                                     albumID: object.albumID),
      buttonDonetitle: configButtonTitle(alertCase),
      album: album,
      folder: folder,
      parent: object.parent)
    DispatchQueue.main.async {
      self.editAlert = edit
    }
  }
}

extension CollectionAlertModifier{
  func textFieldInNeeds() -> some View {
    Group {
      let inNeeds = editAlert?.alertCase == .addAlbumToFolder
      || editAlert?.alertCase == .addFolderToFolder
      || editAlert?.alertCase == .albumNameChange
      || editAlert?.alertCase == .folderNameChange
      if inNeeds {
        TextField(editAlert?.placeHolder ?? "", text: $newText)
        .foregroundStyle(colorScheme == .dark ? .white : .black)
      } else {
        EmptyView()
      }
    }
  }
  func btnAlertAction() -> some View {
    Button {
      guard let alert = editAlert else { return }
      alertAction(alertCase: alert.alertCase)
    } label: {
      Text(editAlert?.buttonDonetitle ?? "확인")
    }
    .keyboardShortcut(.defaultAction) // 키보드 엔터 처리
  }
  func btnCancelAndClose() -> some View {
    Button {
      self.newText = ""
      self.editAlert = nil
    } label: {
      Text("취소")
    }
  }
  func alertAction(alertCase: CollectionAlertCase) {
    switch alertCase {
    case .addAlbumToFolder:
      editAlert.folder?
        .createAlbum(folderToAdd: editAlert.folder?.phCollectionList,
                     newText) { album in
          if let album = album {
            photoData
              .setAlbum(album: album,
                        folderType: .userFolder)
          }
        }
    case .addFolderToFolder:
      if editAlert.folder.folderType != .shareCategory {
        editAlert.folder?.createFolder(
          folderToAdd: editAlert.folder?.phCollectionList,
          newText) { folder in
            if let folder = folder {
              photoData.setFolders(folder: folder,
                                   loadSecondary: false) { }
            }
          }
      } else {
        if let parentID = editAlert?.folder.id,
           var parent = photoData.shareCategories[parentID] {
          let newCategoryID = UUID().uuidString
          // step 1. 부모 카테고리에 추가
          parent.subFolder.append(newCategoryID)
          // step 2. 자식 카테고리 생성
          let shCategory = ShareCategory(
            id: newCategoryID,
            title: newText,
            subFolder: [], subAlbums: [])
          // step 3. 자식 폴더 등록
          photoData.setFolders(folderType: .shareCategory,
                               shareCategory: shCategory) {
            if let parentFolder = photoData.shareFolders[parent.id] {
              let childCollection = SubCollection(
                id: shCategory.id,
                title: shCategory.title,
                type: .folder)
              // step 2. 부모 폴더에 추가
              parentFolder.addSubCollection(
                type: .folder, collection: childCollection) {}
              // step 3. 자식 카테고리 등록
              DispatchQueue.main.async {
                photoData.registCategory(shCategory) {
                  // step 4. 부모 카테고리 업데이트
                  photoData.registCategory(parent) {
                    // step 5. 카테고리 데이터 저장
                    photoData.saveCategoriData()
                  }
                }
              }
            }
          }
        }
      }
    case .albumNameChange:
      guard let album = editAlert.album else { return }
      editAlert.album
        .modifyAlbumTitle(newName: newText) { _ in
          if let parentID = editAlert?.parent,
             let pageFolder = photoData
                    .mlFolder(type: .userFolder,
                              parentID) {
             pageFolder
            .changeSubTitle(type: .album,
                            id: album.id,
                            newTitle: newText)
          }
          self.newText = ""
        }
    case .folderNameChange:
      guard let folder = editAlert.folder else { return }
      if folder.folderType == .userFolder {
        editAlert.folder
          .modifyFolderTitle(newText) { _ in
            if let parentID = editAlert?.parent,
               let pageFolder = photoData
                      .mlFolder(type: .userFolder, parentID) {
               pageFolder
              .changeSubTitle(type: .folder,
                              id: folder.id,
                              newTitle: newText)
            }
            self.newText = ""
          }
      } else {
        photoData
          .changeCategoryTitle(categoryID: editAlert.folder.id,
                               newName: newText) {
            self.newText = ""
          }
      }
    case .delShareCategory:
      // shFolder의 앨범들 하나씩 삭제
      // shFolder 삭제 -> subCollection 삭제 -> shCategory 삭제
      guard let objectFolder = photoData.shareFolders[editAlert?.folder.id ?? "unknown"],
            let parentID = editAlert?.parent,
            let parentFolder = photoData.shareFolders[parentID],
            var parentCategory = photoData.shareCategories[parentID],
            var shareTopCategory = photoData.shareCategories["shareTop"]
      else { return }
      DispatchQueue.global(qos: .userInitiated).async {
        self.deleteFolderData(shareFolder: objectFolder,
                              parentID: parentID) { albumIDs in
          if let cateIndex = parentCategory.subFolder
                          .firstIndex(of: objectFolder.id),
             let foldIndex = parentFolder.foldersArray
                          .compactMap({ $0.id })
                          .firstIndex(of: objectFolder.id){
            parentCategory.subFolder.remove(at: cateIndex)
            DispatchQueue.main.async {
              withAnimation {
                let _ = parentFolder.foldersArray
                                    .remove(at: foldIndex)
                photoData.shareFolders
                  .updateValue(parentFolder, forKey: parentID)
              }
            }
            if parentID == "shareTop" {
              parentCategory.subAlbums
                .append(contentsOf: albumIDs)
              photoData.updateCategory([parentCategory]) {
                photoData.saveCategoriData()
              }
            } else {
              shareTopCategory.subAlbums
                .append(contentsOf: albumIDs)
              photoData.updateCategory([shareTopCategory, parentCategory]) {
                photoData.saveCategoriData()
              }
            }
          }
        }
      }
    }
    self.newText = ""
    self.editAlert = nil
  }
  
  func deleteFolderData(shareFolder: MLFolder,
                        parentID: String,
                        completion: @escaping ([String]) -> Void) {
    moveAlbumsToTop(shareFolder: shareFolder) { albums, folders in
      // step 2. 카테고리 모두 삭제
      removeCategoryLoop(folders: folders) {
        completion(albums)
      }
    }
  }
  func removeCategoryLoop(folders: [String],
                          completion: @escaping () -> Void ) {
    var count = folders.count
    for folder in folders {
      photoData.removeCategory(folder) {
        count -= 1
        if count == 0 {
          completion()
        }
      }
    }
  }
  func moveAlbumsToTop(shareFolder: MLFolder,
                       completion: @escaping ([String], [String]) -> Void) {
    var idsForAlbums: [String] = shareFolder.albumsArray
                                  .compactMap({ $0.id })
    var idsForFolders: [String] = [shareFolder.id]
    guard let shareTopFold = photoData.shareFolders["shareTop"]
    else { return }
    DispatchQueue.main.async {
      withAnimation {
        while !shareFolder.albumsArray.isEmpty {
          let subAlbum = shareFolder.albumsArray.removeFirst()
          shareTopFold.albumsArray.append(subAlbum)
        }
      }
    }
    if shareFolder.foldersArray.isEmpty {
      completion(idsForAlbums, idsForFolders)
    } else {
      var completionCount = shareFolder.foldersArray.count
      for folder in shareFolder.foldersArray {
        guard let mlFolder = photoData.shareFolders[folder.id]
        else { return }
        moveAlbumsToTop(shareFolder: mlFolder) { albums, folders in
          completionCount -= 1
          idsForAlbums.append(contentsOf: albums)
          idsForFolders.append(contentsOf: folders)
          if completionCount == 0 {
            completion(idsForAlbums, idsForFolders)
            DispatchQueue.main.async {
              withAnimation {
                let _ = photoData.shareFolders
                  .removeValue(forKey: folder.id)
              }
            }
          }
        }
      }
    }
  }
}

extension CollectionAlertModifier {
  func configTitle(_ alertCase: CollectionAlertCase,
                   title: String! = "",
                   isDetailView: Bool = false) -> String {
    return switch alertCase {
    case .addAlbumToFolder: "새로운 앨범을 추가합니다."
    case .addFolderToFolder: "새로운 폴더를 추가합니다."
    case .albumNameChange: "앨범의 타이틀을 변경합니다."
    case .folderNameChange: "폴더의 타이틀을 변경합니다."
    case .delShareCategory: "공유 앨범에서\n[\(title ?? "")] 폴더를 삭제합니다."
    }
  }
  func configMessage(_ alertCase: CollectionAlertCase,
                     folderType: FolderType,
                     folderID: String! = nil,
                     albumID: String! = nil) -> String {
    switch alertCase {
    case .addAlbumToFolder, .addFolderToFolder, .folderNameChange:
      guard let folder = photoData.mlFolder(type: folderType, folderID) else { return "" }
      let addedTitle = folder.id == "shareTop"
                    || folder.id == "topFolder"
                    ? "의 최상위" : ""
      return "📂 대상 폴더 : \"\(folder.title)\"\(addedTitle)"
    case .albumNameChange:
      guard let title = photoData.mlAlbum(type: folderType, albumID)?.title else { return "" }
      return "📗 대상 앨범 : \"\(title)\""
    case .delShareCategory:
      return "- 하위 폴더들 : 삭제됩니다.\n- 하위 앨범들 : [최상위] 폴더로 이동합니다."
    }
  }
  func configPlaceHolder(_ alertCase: CollectionAlertCase,
                         folderID: String! = nil,
                         albumID: String! = nil) -> String {
    return switch alertCase {
    case .addAlbumToFolder: "추가할 앨범 이름을 입력하세요."
    case .addFolderToFolder: "추가할 폴더 이름을 입력하세요."
    default: ""
    }
  }
  func configButtonTitle(_ alertCase: CollectionAlertCase) -> String {
    return switch alertCase {
    case .addAlbumToFolder, .addFolderToFolder: "추가하기"
    case .albumNameChange, .folderNameChange: "변경하기"
//    case .mediaTakeFromAlbum: "앨범에서 빼기"
    default: "확인"
    }
  }
  func changeNewText(_ alertCase: CollectionAlertCase,
                     folderType: FolderType,
                     folderID: String! = nil,
                     albumID: String! = nil) -> String {
    return switch alertCase {
    case .albumNameChange:
      if let album = photoData.mlAlbum(type: folderType, albumID) {
        album.title
      } else {
        ""
      }
    case .folderNameChange:
      if let folder = photoData.mlFolder(type: folderType, folderID) {
        folder.title
      } else {
        ""
      }
    default: ""
    }
  }
}

//
//  EditCollectionMenuView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 6/8/26.
//

import SwiftUI
import Photos

struct EditCollectionMenuView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @ObservedObject var pageFolder: MLFolder
  @Binding var processing: SubCollection?
  @Binding var isEditMode: Bool
  let subCollection: SubCollection
  let isSecondary: Bool
  let index: Int
  let nameSpace: Namespace.ID
  let deleteAction: (SubCollection) -> Void
  
  var body: some View {
    if subCollection.type == .album {
      editAlbumView()
    } else {
      editFolderView()
    }
  }
}

extension EditCollectionMenuView {
  var titleView: some View {
    if subCollection.type == .album {
      if let album = photoData
        .mlAlbum(type: .shareCategory, subCollection.id) {
        Text(album.title).bold()
      } else {
        Text(subCollection.title).bold()
      }
    } else {
      if let folder = photoData
        .mlFolder(type: .shareCategory, subCollection.id) {
        Text(folder.title).bold()
      } else {
        Text(subCollection.title).bold()
      }
    }
  }
  func modifyTitle() -> some View {
    Button {
      if subCollection.type == .album {
        guard let album = photoData
          .mlAlbum(type: pageFolder.folderType, subCollection.id)
        else { return }
        let alertObject = AlertObject(
          alertCase: .albumNameChange,
          folderType: pageFolder.folderType,
          albumID: album.id,
          folderID: nil,
          parent: pageFolder.id)
        NotificationCenter.default
          .post(name: .showAlert, object: alertObject)
      } else {
        guard let folder = photoData
          .mlFolder(type: pageFolder.folderType, subCollection.id)
        else { return }
        let alertObject = AlertObject(
          alertCase: .folderNameChange,
          folderType: pageFolder.folderType,
          albumID: nil,
          folderID: folder.id,
          parent: pageFolder.id)
        NotificationCenter.default
          .post(name: .showAlert, object: alertObject)
      }
    } label: {
      if subCollection.type == .album {
        if let mlAlbum = photoData
          .mlAlbum(type: pageFolder.folderType, subCollection.id) {
          Label(mlAlbum.title, systemImage: iconModify)
        }
      } else {
        if let mlFolder = photoData
          .mlFolder(type: pageFolder.folderType, subCollection.id) {
          Label(mlFolder.title, systemImage: iconModify)
        }
      }
    }
  }
  func editAlbumView() -> some View {
    VStack {
      if pageFolder.folderType == .userFolder {
        modifyTitle()
      } else {
        titleView
      }
      ControlGroup {
        if pageFolder.folderType == .userFolder {
          Button(role: .destructive) {
            dispatchAnimation {
              processing = subCollection
            }
            deleteAction(subCollection)
          } label: {
            Label("앨범 삭제하기", systemImage: iconTrash)
          }
        }
        Button {
          let moveObject = MoveCollectionObject(
            currentParent: pageFolder,
            collectionType: .album,
            objectSubCollection: subCollection,
            objectColorIndex: index,
            objectIdentifier: subCollection.id,
            nameSpace: nameSpace)
          NotificationCenter.default
            .post(name: .showMoveCollectionSheet,
                  object: moveObject)
        } label: {
          ContextMenuItem(title: "다른 폴더로 이동하기",
                          image: iconMoveToOtherFolder)
        }
      }
    }
  }
  func editFolderView() -> some View {
      VStack {
        if (pageFolder.folderType == .shareCategory
            && subCollection.type == .album)
            || subCollection.id == "topFolder"
            || subCollection.id == "shareTop" {
          titleView
        } else {
          modifyTitle()
        }
        Divider()
        if pageFolder.id != subCollection.id {
          ControlGroup {
            Button(role: .destructive) {
              deleteAction(subCollection)
            } label: {
              Label("폴더 삭제하기", systemImage: iconTrash)
            }
            Button {
              let moveObject = MoveCollectionObject(
                currentParent: pageFolder,
                collectionType: .folder,
                objectSubCollection: subCollection,
                objectColorIndex: index,
                objectIdentifier: subCollection.id,
                nameSpace: nameSpace)
              NotificationCenter.default
                .post(name: .showMoveCollectionSheet,
                      object: moveObject)
            } label: {
              ContextMenuItem(title: "다른 폴더로 이동하기",
                              image: iconMoveToOtherFolder)
            }
          }
        }
        if pageFolder.folderType == .userFolder
            && pageFolder.id == subCollection.id {
          Button {
            withAnimation {
              isEditMode = true
            }
          } label: {
            Label("지우기 모드", systemImage: iconEraser)
              .symbolRenderingMode(.multicolor)
          }
        }
        if !isSecondary {
          Button {
            let reorderObject = ReorderObject(
              localIdentifier: subCollection.id,
              folderType: pageFolder.folderType
            )
            NotificationCenter.default
              .post(name: .showReorderSheet,
                    object: reorderObject)
          } label: {
            ContextMenuItem(title: "순서 조정하기", image: iconReorder)
          }
        }
        Divider()
        Button {
          let alertObject = AlertObject(
            alertCase: .addFolderToFolder,
            folderType: pageFolder.folderType,
            albumID: nil,
            folderID: subCollection.id)
          DispatchQueue.main.async {
            NotificationCenter.default
              .post(name: .showAlert,
                    object: alertObject)
          }
        } label: {
          ContextMenuItem(title: "폴더 추가하기", image: iconAddFolder)
        }
        if pageFolder.folderType == .userFolder {
          Button {
            let alertObject = AlertObject(
              alertCase: .addAlbumToFolder,
              folderType: pageFolder.folderType,
              albumID: nil,
              folderID: subCollection.id)
            DispatchQueue.main.async {
              NotificationCenter.default
                .post(name: .showAlert,
                      object: alertObject)
            }
          } label: {
            ContextMenuItem(title: "앨범 추가하기",
                            image: iconAddAlbum)
          }
        }
    }
  }
}

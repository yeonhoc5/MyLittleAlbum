//
//  InAppAlertModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import SwiftUI
import Photos

struct InAppAlertModifier: ViewModifier {
    let notificationName: Notification.Name
    @EnvironmentObject var photoData: MLPhotoData
    @State var editAlert: EditAlert!
    @State var newText: String = ""
    @State var isShowingMessage: Bool = false
    
    func body(content: Content) -> some View {
        content
            // 알럿
            .alert(editAlert?.title ?? "",
                   isPresented: .constant(editAlert != nil)) {
                if editAlert?.needsTextField ?? false {
                    TextField(editAlert?.placeHolder ?? "",
                              text: $newText)
                    .foregroundStyle(.white)
                }
                Button {
                    switch editAlert.alertCase {
                    case .mediaTakeFromAlbum, .mediaUnhide, .mediaMoved:
                        DispatchQueue.main.async {
                            withAnimation {
                                NotificationCenter.default
                                    .post(name: .endProgress, object: nil)
                                NotificationCenter.default
                                    .post(name: .showProgressEndDetailView, object: "")
                            }
                        }
                    default: break
                    }
                    self.newText = ""
                    self.editAlert = nil
                } label: {
                    Text("취소")
                }
                Button {
                    alertAction(alertCase: editAlert.alertCase,
                                isDetailView: editAlert.isDetailView)
                } label: {
                    Text(editAlert?.buttonDonetitle ?? "확인")
                }
                .keyboardShortcut(.defaultAction) // 키보드 엔터 처리
            } message: {
                let message = editAlert?.message ?? ""
                Text(message != "" ? ("\n" + (editAlert?.message ?? "")) : "")
            }
            .colorScheme(.dark)
            .overlay(content: {
                if isShowingMessage {
                    Text(newText)
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.ultraThinMaterial)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    isShowingMessage = false
                                }
                                newText = ""
                            }
                        }
                }
            })
            .onReceive(NotificationCenter.default
                .publisher(for: notificationName), perform: { output in
                if let alertObject = output.object as? AlertObject {
                    let alertCase = alertObject.alertCase
                        
                    newText = changeNewText(alertCase,
                                            folder: alertObject.folder,
                                            album: alertObject.album)
                    let album = switch alertObject.albumType {
                    case .home, .picker: photoData.homeAlbum
                    case .smartAlbum: photoData
                            .smartAlbums[alertObject.album?.localIdentifier ?? ""]
                    default: photoData
                            .albums[alertObject.album?.localIdentifier ?? ""]
                    }
                    editAlert = EditAlert(
                        alertCase: alertCase,
                        title: configTitle(
                            alertCase,
                            isDetailView: alertObject.isDetailView,
                            count: alertObject.selectedItems.count),
                        message: configMessage(
                            alertCase,
                            count: alertObject.selectedItems.count,
                            folder: alertObject.folder,
                            album: alertObject.album),
                        needsTextField: alertObject.needsTextField,
                        placeHolder: configPlaceHolder(
                            alertCase,
                            folder: alertObject.folder,
                            album: alertObject.album),
                        buttonDonetitle: configButtonTitle(alertCase),
                        album: album,
                        folder: photoData
                            .folders[alertObject.folder?.localIdentifier ?? "topFolder"],
                        isHiddenAsset: alertObject.isHiddenAsset,
                        selectedItems: alertObject.selectedItems,
                        isDetailView: alertObject.isDetailView
                    )
                }
            })
            .onReceive(NotificationCenter.default
                .publisher(for: .showMessage)) { message in
                    self.newText = message.object as? String ?? ""
                    withAnimation {
                        isShowingMessage = true
                    }
                }
    }
    
}

extension InAppAlertModifier{
    
    func alertAction(alertCase: AlertCase, isDetailView: Bool) {
        switch alertCase {
        case .addAlbumToFolder:
            editAlert.folder
                .createAlbum(folderToAdd: editAlert.folder.phCollectionList,
                             newText) { album in
                    if let album = album {
                        photoData.setAlbum(album: album)
                        DispatchQueue.main.async {
                            let object = ScrollItem(identifier: album.localIdentifier,
                                                    collectionType: .album,
                                                    depth: .current)
                            NotificationCenter.default
                                .post(name: .scrollToItem, object: object)
                        }
                    }
            }
        case .addFolderToFolder:
            editAlert.folder
                .createFolder(folderToAdd: editAlert.folder.phCollectionList,
                              newText) { folder in
                    if let folder = folder {
                        photoData.setFolders(folder: folder, isNew: true)
                        DispatchQueue.main.async {
                            let object = ScrollItem(identifier: folder.localIdentifier,
                                                    collectionType: .folder,
                                                    depth: .current)
                            NotificationCenter.default
                                .post(name: .scrollToItem, object: object)
                        }
                    }
            }
        case .albumNameChange:
            editAlert.album
                .modifyAlbumTitle(newName: newText) { _ in
                    self.newText = ""
                }
        case .folderNameChange:
            editAlert.folder
                .modifyFolderTitle(newText) { _ in
                    self.newText = "" 
            }
        case .mediaTakeFromAlbum:
            let id = editAlert.album?.id ?? ""
            editAlert.album
                .removeAssetFromAlbum(
                    assets: editAlert.selectedItems,
                    isHidden: editAlert.isHiddenAsset) { bool in
                        if bool {
                            DispatchQueue.main.async {
                                NotificationCenter.default
                                    .post(name: .innerFetchChange, object: id)
                                NotificationCenter.default
                                    .post(name: .outsideFetchChange, object: "myPhotos")
                                if isDetailView {
                                    NotificationCenter.default
                                        .post(name: .detailViewRemoveAsset, object: nil)
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            NotificationCenter.default
                                .post(name: .showProgressEndDetailView, object: "")
                        }
                }
        case .mediaUnhide:
            let id = editAlert.album?.id ?? " "
            editAlert.album?
                .hideOrUnhideAsset(assets: editAlert.selectedItems,
                                   toHide: false,
                                   isDetailView: editAlert.isDetailView) { bool in
                    DispatchQueue.main.async {
                        if bool {
                            if isDetailView {
                                NotificationCenter.default
                                    .post(name: .detailViewRemoveAsset, object: nil)
                            }
                            NotificationCenter.default
                                .post(name: .innerFetchChange, object: id)
                        }
                    }
                }
//        case .mediaMoved:
//            <#code#>
//        case .none:
//            <#code#>
        default: break
        }
        self.newText = ""
        self.editAlert = nil
    }
}
    
extension InAppAlertModifier {
    func configTitle(_ alertCase: AlertCase,
                     isDetailView: Bool = false,
                     count: Int!) -> String {
        return switch alertCase {
        case .addAlbumToFolder:
            "새로운 앨범을 추가합니다."
        case .addFolderToFolder:
            "새로운 폴더를 추가합니다."
        case .albumNameChange:
            "앨범의 타이틀을 변경합니다."
        case .folderNameChange:
            "폴더의 타이틀을 변경합니다."
        case .mediaTakeFromAlbum:
            "현재 앨범에서 \(!isDetailView ? "선택한 \(count ?? 0)개의" : "이") 항목을 제거합니다."
        case .mediaUnhide:
            "\(!isDetailView ? "선택한 \(count ?? 0)개" : "이") 항목의 가리기를 해제합니다."
        default: ""
        }
    }
    func configMessage(_ alertCase: AlertCase,
                       count: Int! = nil,
                       folder: PHCollectionList! = nil,
                       album: PHAssetCollection! = nil) -> String {
        return switch alertCase {
        case .addAlbumToFolder, .addFolderToFolder, .folderNameChange:
            "📂 대상 폴더 : \(folder == nil ? "(최상위 폴더)" : " \"\(folder?.localizedTitle ?? "")\"")"
        case .albumNameChange:
            "📗 대상 앨범 : \"\(album?.localizedTitle ?? "")\""
        case .mediaTakeFromAlbum:
            "해당 항목\(count > 1 ? "들" : "")은 [나의 포토] 탭에서 찾을 수 있습니다."
        case .mediaMoved:
            "\(count ?? 0)개 항목을 [\(album?.localizedTitle ?? "")] 앨범으로 이동하였습니다."
        default: ""
        }
    }
    func configPlaceHolder(_ alertCase: AlertCase,
                           folder: PHCollectionList! = nil,
                           album: PHAssetCollection! = nil) -> String {
        return switch alertCase {
        case .addAlbumToFolder: "추가할 앨범 이름을 입력하세요."
        case .addFolderToFolder: "추가할 폴더 이름을 입력하세요."
        default: ""
        }
    }
    func configButtonTitle(_ alertCase: AlertCase) -> String {
        return switch alertCase {
        case .addAlbumToFolder, .addFolderToFolder: "추가하기"
        case .albumNameChange, .folderNameChange: "변경하기"
        case .mediaTakeFromAlbum: "앨범에서 빼기"
        default: "확인"
        }
    }
    func changeNewText(_ alertCase: AlertCase,
                       folder: PHCollectionList! = nil,
                       album: PHAssetCollection! = nil) -> String {
        return switch alertCase {
        case .albumNameChange:
            if let album = photoData.albums[album?.localIdentifier ?? ""] {
                album.title
            } else {
                ""
            }
        case .folderNameChange:
            if let folder = photoData.folders[folder?.localIdentifier ?? ""] {
                folder.title
            } else {
                ""
            }
        default: ""
        }
    }
}

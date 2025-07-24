//
//  InAppAlertModifier.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/12/24.
//

import SwiftUI

struct InAppAlertModifier: ViewModifier {
    @State var editAlert: EditAlert!
    @State var newText: String = ""
    
    func body(content: Content) -> some View {
        content
            // 알럿
            .onReceive(NotificationCenter.default.publisher(for: .showAlert),
                       perform: { output in
                if let alertObject = output.object as? AlertObject {
                    let alertCase = alertObject.alertCase
                    newText = changeNewText(alertCase,
                                  folder: alertObject.folder,
                                  album: alertObject.album)
                    editAlert = EditAlert(
                        alertCase: alertCase,
                        title: configTitle(
                            alertCase,
                            count: alertObject.count),
                        message: configMessage(
                            alertCase,
                            count: alertObject.count,
                            folder: alertObject.folder,
                            album: alertObject.album),
                        needsTextField: alertObject.needsTextField,
                        placeHolder: configPlaceHolder(
                            alertCase,
                            folder: alertObject.folder,
                            album: alertObject.album),
                        buttonDonetitle: configButtonTitle(alertCase),
                        album: alertObject.album,
                        folder: alertObject.folder
                    )
                }
            })
            // 미디어 이동 시트
            .onReceive(NotificationCenter.default.publisher(for: .showSecondSheet),
                       perform: { output in
                
            })
            .alert(editAlert?.title ?? "",
                   isPresented: .constant(editAlert != nil)) {
                if editAlert?.needsTextField ?? false {
                    TextField(editAlert?.placeHolder ?? "",
                              text: $newText)
                        .foregroundStyle(.white)
                }
                Button {
                    self.newText = ""
                    self.editAlert = nil
                } label: {
                    Text("취소")
                }
                Button {
                    
                } label: {
                    Text(editAlert?.buttonDonetitle ?? "확인")
                }
            } message: {
                Text("\n" + (editAlert?.message ?? ""))
            }
    }
    
    func configTitle(_ alertCase: AlertCase, count: Int!) -> String {
        return switch alertCase {
        case .addAlbumCurrent, .addAlbumSecondary:
            "새로운 앨범을 추가합니다."
        case .addFolderCurrent, .addFolderSecondary:
            "새로운 폴더를 추가합니다."
        case .albumNameChange:
            "앨범의 타이틀을 변경합니다."
        case .folderNameChange:
            "폴더의 타이틀을 변경합니다."
        case .mediaTakeFromAlbum:
            "선택한 \(count ?? 0)개 항목을 현재 앨범에서 빼냅니다."
        case .mediaUnhide:
            "선택한 \(count ?? 0)개 항목의 가리기를 해제합니다."

        default: ""
        }
    }
    func configMessage(_ alertCase: AlertCase,
                       count: Int! = nil,
                       folder: Folder! = nil,
                       album: Album! = nil) -> String {
        return switch alertCase {
        case .addAlbumCurrent, .addAlbumSecondary,
                .addFolderCurrent, .addFolderSecondary, .folderNameChange:
            "📂 대상 폴더 : \(folder.folder == nil ? "(최상위 폴더)" : " [\(folder.title)]")"
        case .albumNameChange:
            "📗 대상 앨범 : [\(album.title)]"
        case .mediaTakeFromAlbum:
            "해당 항목들은 [나의 포토] 탭에서 찾을 수 있습니다."
        case .mediaMoved:
            "\(count ?? 0)개 항목을 [\(album?.title ?? "")] 앨범으로 이동하였습니다."
        default: ""
        }
    }
    func configPlaceHolder(_ alertCase: AlertCase,
                           folder: Folder! = nil,
                           album: Album! = nil) -> String {
        return switch alertCase {
        case .addAlbumCurrent, .addAlbumSecondary:
            "추가할 앨범 이름을 입력하세요."
        case .addFolderCurrent, .addFolderSecondary:
            "추가할 폴더 이름을 입력하세요."
        case .albumNameChange:
            album?.title ?? ""
        case .folderNameChange:
            folder?.title ?? ""
        default: ""
        }
    }
    func configButtonTitle(_ alertCase: AlertCase) -> String {
        return switch alertCase {
        case .addAlbumCurrent, .addAlbumSecondary,
                .addFolderCurrent, .addFolderSecondary:
            "추가하기"
        case .albumNameChange, .folderNameChange:
            "변경하기"
        case .mediaTakeFromAlbum:
            "앨범에서 빼기"
        default: "확인"
        }
    }
    func changeNewText(_ alertCase: AlertCase,
                       folder: Folder! = nil,
                       album: Album! = nil) -> String {
        return switch alertCase {
        case .albumNameChange:
            album?.title ?? ""
        case .folderNameChange:
            folder?.title ?? ""
        default: ""
        }
    }
}



extension Notification.Name {
    static let showAlert = Notification.Name("showAlert")
    static let showSecondSheet = Notification.Name("showSecondSheet")
}

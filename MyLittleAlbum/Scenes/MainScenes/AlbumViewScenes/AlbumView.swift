//
//  AlbumView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
//import PhotosUI

// 앨범 뷰
struct AlbumView: View {
    // 사진 데이터 프라퍼티
    @EnvironmentObject var photoData: PhotoData
    @StateObject var pageFolder: Folder
    // UI 프라퍼티
    @State var title: String! = "My Album"
    var isTopFolder: Bool! = true
    var color: Color! = .orange
    @State var isPortrait: Bool = true
    @Binding var isPhotosView: Int
    // 애니메이션 프라퍼티
    var nameSpace: Namespace.ID
    @Namespace var albumViewNameSpace
    @Namespace var folderViewInScroll
    @Namespace var albumViewInScroll
    @State var scrollToEdge: EdgeToScroll = .none
    // 추가 뷰 프라퍼티
    @State var isShowingSheet: Bool = false
    @State var isShowingPhotosPicker: Bool = false
    @State var isShowingReorderSheet: Bool = false
    @Binding var isShowingSettingView: Bool
    // 수정용 프라퍼티
    @StateObject var stateChangeObject: StateChangeObject
    // 수정 모드 프라퍼티
    @State var isEditingMode: Bool = false
    // 앨범 타이틀 수정용 프라퍼티
    @State var newName: String = ""
    // 앨범 밖에서 사진 추가용 프라퍼티
    @State var selectedItems: [Int] = []
    // 앨범 / 폴더 리스트에서 수정 발생 시 기준 폴더 전달용
    @State var currentFolder: Folder!
    // 제스처로 팝오프용 프라퍼티
    @Environment(\.presentationMode) var isPresented: Binding<PresentationMode>
    
    var body: some View {
        GeometryReader(content: { geometry in
            let widthOfAlbum = (geometry.size.width - (10 * CGFloat(listCount + 2))) / CGFloat(listCount)
            let secondaryWidth = (geometry.size.width - 20 - CGFloat(listCount * 10))
            / CGFloat(listCount + 1)
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 5) {
                        AlbumListView(
                            stateChangeObject: stateChangeObject,
                            pageFolder: pageFolder,
                            uiMode: photoData.uiMode,
                            widthOfAlbum: widthOfAlbum,
                            randomNum1: photoData.randomNum1,
                            randomNum2: photoData.randomNum2,
                            isShowingSheet: $isShowingSheet,
                            isShowingPhotosPicker: $isShowingPhotosPicker,
                            isEditingMode: isEditingMode,
                            nameSpace: nameSpace,
                            albumViewNameSpace: albumViewNameSpace,
                            currentFolder: $currentFolder,
                            isPhotosView: $isPhotosView
                        )
                        .padding(.top, 10)
                        .id(albumViewInScroll)
                        FolderListView(
                            stateChangeObject: stateChangeObject,
                            pageFolder: pageFolder,
                            isTopFolder: isTopFolder,
                            uiMode: photoData.uiMode,
                            secondaryWidth: secondaryWidth,
                            randomNum1: photoData.randomNum1,
                            randomNum2: photoData.randomNum2,
                            isShowingSheet: $isShowingSheet,
                            isShowingPhotosPicker: $isShowingPhotosPicker,
                            isShowingReorderSheet: $isShowingReorderSheet,
                            isEditingMode: isEditingMode,
                            nameSpace: nameSpace,
                            albumViewNameSpace: albumViewNameSpace,
                            currentFolder: $currentFolder,
                            isPhotosView: $isPhotosView
                        )
                        .padding(.bottom, tabbarHeight
                                 + tabbarTopPadding
                                 + tabbarBottomPadding)
                        .id(folderViewInScroll)
                    }
                    .onChange(of: pageFolder.countAlbum) { [oldValue = pageFolder.countAlbum] newValue in
                        if oldValue < newValue {
                            scrollToNewItem(proxy: proxy, at: .currentAlbum)
                        }
                    }
                    .onChange(of: pageFolder.countFolder) { [oldValue = pageFolder.countFolder] newValue in
                        if oldValue < newValue {
                            scrollToNewItem(proxy: proxy, at: .currenFolder)
                        }
                    }
                    .onChange(of: stateChangeObject.isShowingAlert) { newValue in
                        newName = !newValue
                        ? "" : ((stateChangeObject.editType == .add
                            ? "" :  (stateChangeObject.collectionToEdit?.localizedTitle ?? "")))
                    }
                    .onChange(of: photoData.scrollToTop) { bool in
                        if bool {
                            withAnimation {
                                proxy.scrollTo(albumViewInScroll, anchor: .top)
                            }
                            DispatchQueue.main.async {
                                photoData.scrollToTop = false
                            }
                        }
                    }
                    .onChange(of: geometry.size, perform: { new in
                        if new.width > new.height {
                            withAnimation {
                                isPortrait = true
                            }
                        } else {
                            withAnimation {
                                isPortrait = false
                            }
                        }
                    })
                }
                .onTapGesture {
                    stateChangeObject.isShowingMenu = false
                }
                .simultaneousGesture(popOffCurrentPage)
                .disabled(isShowingSettingView)
            }
            .overlay {
                Rectangle()
                    .foregroundStyle(Color.black)
                    .opacity(isShowingSettingView ? 0.5 : 0)
                    .ignoresSafeArea()
            }
            SettingView(isShowingSettingView: $isShowingSettingView)
                .frame(width: device == .phone
                       ? screenWidth : 400)
                .position(x: isShowingSettingView
                          ? (device == .phone
                            ? (geometry.size.width / 2) : 220)
                          : (device == .phone
                               ? (-geometry.size.width)
                               : (-geometry.size.width + 200)),
                          y: geometry.size.height / 2)
                .animation(isShowingSettingView
                           ? .linear.delay(0.15) : .linear,
                           value: isShowingSettingView)
        })
        .navigationTitle(
            pageFolder.isHome ? title : pageFolder.title
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { rightToolBarItems
                .opacity(isShowingSettingView ? 0 : 1)
                .offset(y: isShowingSettingView ? -100 : 0)
            }
            if pageFolder.isHome {
                ToolbarItem(placement: .navigationBarLeading) { leftHomeToolBarItem }
            }
        }
        .foregroundColor(.secondary)
        .background { FancyBackground() }
        .edgesIgnoringSafeArea(.trailing)
        .alert("",
               isPresented: $stateChangeObject.isShowingAlert,
               actions: {
            TextField(text: $newName) {
                let edit = stateChangeObject.editType == .add ? "추가":"변경"
                let collection = stateChangeObject.collectionType == .album ? "앨범":"폴더"
                Text("\(edit)할 \(collection) 이름을 입력하세요.")
            }
            cancelButton()
            switch stateChangeObject.editType {
            case .add: addButton()
            default: saveButton()
            }
        }, message: {
            Text(generateAlertSentence())
        })
        .sheet(isPresented: $isShowingSheet, content: {
            // 1. 폴더/앨범 이동 시트
            MoveCollectionCategoryView(isShowingSheet: $isShowingSheet, currentFolder: $currentFolder, stateChangeObject: stateChangeObject)
        })
        .sheet(isPresented: $isShowingPhotosPicker, content: {
            // 3. 앨범 밖에서 사진 넣기 시트
            let albumToAdd = Album(album: stateChangeObject.collectionToEdit as! PHAssetCollection)
            CustomPhotosPicker(isShowingPhotosPicker: $isShowingPhotosPicker,
                               stateChangeObject: stateChangeObject,
                               albumToEdit: albumToAdd)
        })
        .fullScreenCover(isPresented: $isShowingReorderSheet, content: {
            // 2. 폴더/앨범 재정렬 시트(풀커버)
            ReorderCategoriView(pageFolder: $currentFolder,
                                albumArray: $pageFolder.albumArray,
                                folderArray: $pageFolder.folderArray,
                                isShowingReorderSheet: $isShowingReorderSheet)
        })
    }
}

// MARK: - functions
extension AlbumView {
    var popOffCurrentPage: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onEnded({ value in
                if pageFolder.folder != nil {
                    if value.translation.width > 50 {
                        isPresented.wrappedValue.dismiss()
                    }
                }
            })
    }
    
    func generateAlertSentence() -> String {
        let toEditedTitle = stateChangeObject.collectionToEdit?.localizedTitle ?? ""
        let pressed = stateChangeObject.pressedType == .album ? "앨범" : "폴더"
        let collection = stateChangeObject.collectionType == .album ? "앨범을" : "폴더를"
        let depth = stateChangeObject.depthType == .current ? "현재 \(pressed) 리스트" : "[\(toEditedTitle)] 안"
        let sentence = stateChangeObject.editType == .add ? "\(depth)에 \(collection) 추가합니다." : "선택하신 \(pressed)의 이름을 변경합니다."
        return sentence
    }
    
    func scrollToNewItem(proxy: ScrollViewProxy, at: NewToScroll) {
        let newToScroll = at == .currenFolder ? folderViewInScroll : albumViewInScroll
        let edgeToSCroll: UnitPoint = at == .currenFolder ? .bottom : .top
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interactiveSpring()) {
                proxy.scrollTo(newToScroll, anchor: edgeToSCroll)
            }
        }
    }
}

// MARK: - [툴바] 아이템 / context 메뉴
extension AlbumView {
    // Trailing 툴바 아이텝 (2개)
    @ViewBuilder
    var rightToolBarItems: some View {
        let iconWidth: CGFloat = 45
        if isEditingMode {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isEditingMode = false
                }
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)
                    Text("Done")
                }
            }
            .frame(width: iconWidth, height: 20, alignment: .center)
            .buttonStyle(ClickScaleEffect())
        } else {
            Menu {
                contextMenu
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(.clear)
                    imageWithScale(systemName: "folder.fill.badge.gearshape",
                                   scale: .large)
                }
            }
            .menuStyle(.borderlessButton)
            .frame(width: iconWidth, height: 20, alignment: .center)
            .onTapGesture {
                objectChange(type: .menu,
                             bool: stateChangeObject.isShowingMenu ? false : true)
            }
        }
    }
    // Leading 툴바 아이텝 (1개) - Home에서만 출현
    var leftHomeToolBarItem: some View {
        let settingIcon = "gearshape.fill"
        return Button {
            DispatchQueue.main.async {
                withAnimation {
                    isShowingSettingView.toggle()
                }
            }
        } label: {
            ZStack {
                imageWithScale(systemName: settingIcon, scale: .large)
                    .rotationEffect(.degrees(isShowingSettingView ? -180 : 0))
                    .animation(isShowingSheet ? .linear.delay(1.5) : .linear,
                               value: isShowingSheet)
                Rectangle()
                    .foregroundColor(.clear)
            }
        }
        .buttonStyle(ClickScaleEffect())
    }
    // 툴바 아이템 (Trailing) - contextMenu
    var contextMenu: some View {
        let albumIcon = "rectangle.stack.fill.badge.plus"
        let folderIcon = "folder.fill.badge.plus"
        let deleteModeIcon = "pencil"
        return VStack {
            Button {
                showingAlert(depth: .current, preesed: .album, toAdd: .album, edit: .add, collection: pageFolder.folder, index: 0)
                stateChangeObject.isShowingMenu = false
            } label: {
                ContextMenuItem(title: "앨범 추가하기", image: albumIcon)
            }
            Button {
                showingAlert(depth: .current, preesed: .folder, toAdd: .folder, edit: .add, collection: pageFolder.folder, index: 0)
                objectChange(type: .menu, bool: false)
            } label: {
                ContextMenuItem(title: "폴더 추가하기", image: folderIcon)
            }
            Divider()
            Button {
                withAnimation {
                    isEditingMode = true
                }
            } label: {
                ContextMenuItem(title: "폴더 / 앨범 지우기 모드", image: deleteModeIcon)
            }
            Divider()
            Button {
                currentFolder = pageFolder
                isShowingReorderSheet = true
            } label: {
                ContextMenuItem(title: "리스트 순서 조정하기", image: "arrow.up.arrow.down")
            }
        }
    }
}

// MARK: - [Funcs] 앨범 추가 / 수정 Alert
extension AlbumView {
    enum ObjectType {
        case menu, editingMode
    }
    func objectChange(type: ObjectType, bool: Bool) {
        switch type {
        case .menu:
            DispatchQueue.main.async {
                stateChangeObject.isShowingMenu = bool
            }
        case .editingMode:
            DispatchQueue.main.async {
                withAnimation {
                    stateChangeObject.isEditingMode = bool
                }
            }
        }
    }
    
    // 알럿 띄우기 (현재 뎁스 & 세컨더리 / 추가 & 이름 수정)
    func showingAlert(depth: DepthType, 
                      preesed: PressedType,
                      toAdd: CollectionType,
                      edit: EditType,
                      collection: PHCollection!,
                      index: Int) {
        stateChangeObject.isShowingAlert = true
        stateChangeObject.depthType = depth
        stateChangeObject.pressedType = preesed
        stateChangeObject.collectionType = toAdd
        stateChangeObject.editType = edit
        stateChangeObject.collectionToEdit = collection
    }
    // 취소 버튼
    func cancelButton() -> some View {
        Button {
            resetEditStatus()
        } label: {
            Text("취소")
        }
    }
    // 이름 수정 버튼
    func saveButton() -> some View {
        Button {
            switch stateChangeObject.pressedType {
            case .album:
                let album = stateChangeObject.collectionToEdit as! PHAssetCollection
                PHPhotoLibrary.shared().performChanges {
                    guard let request = PHAssetCollectionChangeRequest(for: album) else { return }
                    request.title = newName
                } completionHandler: { bool, _ in
                    resetEditStatus()
                }
            case .folder:
                let folder = stateChangeObject.collectionToEdit as! PHCollectionList
                PHPhotoLibrary.shared().performChanges {
                    guard let request = PHCollectionListChangeRequest(for: folder) else { return }
                    request.title = newName
                } completionHandler: { bool, _ in
                    resetEditStatus()
                }
            default: break
            }
        } label: {
            Text("저장하기")
        }

    }
    // 추가 버튼
    func addButton() -> some View {
        Button {
            let folder = stateChangeObject.collectionToEdit as? PHCollectionList
            let depth = stateChangeObject.depthType
            switch stateChangeObject.collectionType {
            case .folder:
                let folderName = newName == "" ? "새폴더" : newName
                pageFolder.createFolder(depth: depth, folderToAdd: folder, folderName) { folder in
                    resetEditStatus()
                }
            case .album:
                let albumName = newName == "" ? "새앨범" : newName
                pageFolder.createAlbum(depth: depth, folderToAdd: folder, albumName) { album in
                    resetEditStatus()
                }
            default: break
            }
        } label: {
            Text("추가하기")
        }
    }
    
    func resetEditStatus() {
        DispatchQueue.main.async {
            stateChangeObject.isShowingAlert = false
            stateChangeObject.editType = .none
            stateChangeObject.collectionType = .none
            stateChangeObject.pressedType = .none
            stateChangeObject.depthType = .none
            stateChangeObject.collectionToEdit = nil
            stateChangeObject.isShowingMenu = false
        }
        newName = ""
    }
}

struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView(pageFolder: Folder(isHome: true),
                  isPhotosView: .constant(0),
                  nameSpace: Namespace().wrappedValue,
                  isShowingSettingView: .constant(false),
                  stateChangeObject: StateChangeObject())
            .environmentObject(PhotoData())
    }
}

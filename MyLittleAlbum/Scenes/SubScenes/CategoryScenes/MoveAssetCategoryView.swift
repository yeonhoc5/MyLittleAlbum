//
//  CategoryScene.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/11.
//

import SwiftUI
import Photos
//import PhotosUI

// MARK: - 1st Struct
struct MoveAssetCategoryView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @Binding var isShowingSelectFolderSheet: Bool
    @Binding var object: MoveAssetObject!
    @Environment(\.dismiss) var dismiss
    
    // 버튼 타이틀 조정을 위해 "홈/앨범" 확인
    var albumType: AlbumType = .album
    let currentAlbum: PHAssetCollection!
    let isHiddenAssets: Bool
    var isDetailView: Bool = false
    // 앨범에서 선택한 사진 인덱스
    let selectedItems: [MLAsset]
    // 사진을 옮길 목표지 앨범
    @State var isTopFolderSelected: Bool = false
    @State var selectedFolder: PHCollectionList!
    @State var albumToAddPhotos: PHAssetCollection!
    // 새로운 앨범 만들기
    @State var newName: String = ""
    // 버튼 타이틀
    @State var isSettedMLAlbum: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                watchItemsView(count: selectedItems.count)
                moveAssetTitleView
            }
            VStack(spacing: 10) {
                if albumType != .home {
                    legendView
                }
                folderCategoryView
                recentWorkAlbumList
            }
            HStack {
                btnCancelAndClose
                btnAddAndClose
            }
            .padding([.horizontal, .bottom], 22)
        }
        .padding(.top, 20)
        .background(Color.fancyBackground)
        .onChange(of: isSettedMLAlbum) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    addAssetIntoAlbum(assets: selectedItems)
                }
            }
        }
    }
}
// MARK: - 2. subViews
extension MoveAssetCategoryView {
    var legendView: some View {
        HStack(spacing: 3) {
            Spacer()
            imageScaledFit(systemName: "circle.circle.fill", width: 14, height: 14)
            Text("현재 앨범")
                .font(.callout)
        }
        .foregroundStyle(.gray.opacity(0.6))
        .padding(.horizontal, 30)
    }
    var folderCategoryView: some View {
        let topFolder = photoData.folders["topFolder"] ?? MLFolder(collectionList: nil)
        return GeometryReader { proxy in
            ScrollViewReader() { scrollProxy in
                List {
                    Group {
                        topFolderLineView(topFolder: topFolder)
                            .listRowSeparator(isTopFolderSelected ? .hidden : .visible)
                        if isTopFolderSelected {
                            albumInFolderLineView(folder: topFolder)
                        }
                        subFolderLineView(topFolders: topFolder.foldersArray,
                                          scrollProxy: scrollProxy)
                    }
                    .listRowBackground(Color.white)
                    .listRowInsets(
                        EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40)
                    )
                }
                .scrollIndicators(.visible)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .mask {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .frame(height: proxy.size.height)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    func albumInFolderLineView(folder: MLFolder) -> some View {
//                VStack(spacing: 5) {
//                    HStack(spacing: 10) {
//                        btnAtFolder(isFolder: true)
//                        btnAtFolder(isFolder: false)
//                    }
//                    .padding([.horizontal, .top], 10)
//                }
        SelectableCollectionView(
            collectionType: .album,
            emptytext: "이 폴더에는 앨범이 없습니다.",
            currentAlbum: currentAlbum,
            albumArray: folder.albumsArray.map({ $0.localIdentifier }),
            albumToAddPhotos: $albumToAddPhotos,
            depthCount: 0,
            objectFolder: nil,
            currentParent: nil,
            folderToAddCollection: .constant(nil),
            isTopFolderSelected: $isTopFolderSelected,
            lowers: [])
    }
    
    var recentWorkAlbumList: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("최근 선택한 앨범 리스트")
                .foregroundStyle(Color.gray)
                .padding(.horizontal, 22)
            SelectableCollectionView(
                collectionType: .album,
                emptytext: "최근 선택한 앨범이 없습니다.",
                currentAlbum: currentAlbum,
                albumArray: photoData.recentWorkAlbum,
                albumToAddPhotos: $albumToAddPhotos,
                depthCount: 0,
                objectFolder: nil,
                currentParent: nil,
                folderToAddCollection: .constant(nil),
                isTopFolderSelected: $isTopFolderSelected,
                lowers: [])
        }
    }
    
    func topFolderLineView(topFolder: MLFolder) -> some View {
        let isSelected = isTopFolderSelected && selectedFolder == nil
        return FolderLineView(isCollectionMoveView: false,
                              title: "최상위 폴더",
                              subImage: "",
                              isSelected: isSelected,
                              albumEmpty: topFolder.albumsArray.isEmpty)
        .onTapGesture {
            withAnimation {
                isTopFolderSelected.toggle()
            }
            selectedFolder = nil
            albumToAddPhotos = nil
        }
        .foregroundColor(isSelected ? .selectedColor : .nonSelectedColor)
    }
    // 그 외 라인
    func subFolderLineView(topFolders: [PHCollectionList], scrollProxy: ScrollViewProxy) -> some View {
        return ForEach(topFolders, id: \.localIdentifier) { folder in
            FolderCategoryView(isHome: false,
                               currentFolder: nil,
                               currentAlbum: currentAlbum,
                               lineFolder: folder,
                               toMoveCollection: nil,
                               isTopFolderSelected: $isTopFolderSelected,
                               folderToAddCollection: $selectedFolder,
                               albumToAddPhotos: $albumToAddPhotos,
                               inheritedDisable: false,
                               showAlbumList: true,
                               moveBtnTitle: $newName,
                               scrollProxy: scrollProxy) { folder in
                withAnimation {
                    albumToAddPhotos = nil
                }
            }
        }
    }
    func watchItemsView(count: Int) -> some View {
        Button {
        } label: {
            imageScaledFit(systemName: "photo.fill.on.rectangle.fill",
                           width: 60, height: 45)
                .overlay(alignment: .topTrailing,
                         content: {
                    Text("\(count)")
                        .font(Font.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.fancyBackground)
                        .padding(.horizontal, 7)
                        .background {
                            Capsule()
                                .foregroundStyle(Color.blue)
                                .frame(minWidth: 20, minHeight: 20)
                                .padding(2.3)
                                .background(content: {
                                    Capsule()
                                        .foregroundStyle(Color.black)
                                })
                        }
                        .offset(x: 1 + (count > 9 ? 5 : (count > 99 ? 10 : 0)), y: -4)
                })
                .foregroundStyle(Color.white)
        }
        .disabled(true)
    }
    // 타이틀 뷰
    var moveAssetTitleView: some View {
        let basicText = "항목을 \(albumType == .home ? "넣을" : "옮길") 앨범을"
        return Group {
            if device == .pad {
                Text("\(basicText) 선택해 주세요.")
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    Text(basicText)
                    Text("선택해 주세요.")
                }
            }
        }
        .foregroundColor(.gray)
        .font(.headline)
    }
    // 리스트 목록 프레임
    func roundedFrame(proxy: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 15)
            .frame(width: screenSize.width - 44, height: proxy.size.height)
    }
    // (왼쪽) 취소 버튼
    var btnCancelAndClose: some View {
        Button {
            DispatchQueue.main.async {
                NotificationCenter.default
                    .post(name: .assetWorkDone,
                          object: currentAlbum?.localIdentifier ?? "myPhotos")
            }
            self.object = nil
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                Text("취소")
                    .foregroundStyle(.black)
            }
        }
        .foregroundStyle(.white)
        .frame(width: 120, height: 50)
    }
    
    func btnAtFolder(isFolder: Bool) -> some View {
        let disable = !isTopFolderSelected && (selectedFolder == nil)
        return Button {
            let alertObject = AlertObject(
                alertCase: isFolder ? .addFolderToFolder : .addAlbumToFolder,
                album: nil,
                folder: selectedFolder,
                needsTextField: true)
            NotificationCenter.default
                .post(name: .showAlert, object: alertObject)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                    .fontWeight(.light)
                Text(isFolder ? "폴더" :  "앨범")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .foregroundStyle(disable ? .gray.opacity(0.5) : .blue)
            }
        }
        .disabled(disable)
    }
    
    var btnAddAndClose: some View {
        let disable = albumToAddPhotos == nil
        return Button {
            dispatchAnimation {
                self.object = nil
            }
            addAssetIntoAlbum(assets: selectedItems)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                FlipViewTransitor(isModeChange: disable) {
                    VStack {
                        HStack(spacing: 1) {
                            Text("\(albumToAddPhotos.localizedTitle ?? "앨범")")
                                .truncationMode(.middle)
                                .contentTransition(.numericText())
                            Text(albumType == .home ? "에" : "(으)로")
                        }
                        Text(albumType == .home ? "넣기" : "옮기기")
                    }
                } flipReverseView: {
                    Text("앨범을 선택해 주세요.")
                }
                .foregroundStyle(disable ? .gray : .white)
            }
        }
        .frame(height: 50)
        .foregroundStyle(disable ? Color.addButton : .blue)
        .disabled(disable)
        .animation(.easeOut, value: disable)
    }
    // 앨범 만들어 넣기 List Line(맨 윗줄)
    var createAlbumLineView: some View {
        Button {
            
        } label: {
            Rectangle()
                .foregroundColor(.white)
                .overlay {
                    HStack {
                        imageScaledFit(
                            systemName: "rectangle.stack.fill.badge.plus",
                            width: 20, height: 20)
                        Text("앨범 추가하여 \(albumType == .home ? "넣기" : "이동하기")")
                    }
                    .foregroundColor(.blue)
                }
        }
        .listRowBackground(Color.white)
        .listRowInsets(
            EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40)
        )
    }
    // 앨범 만들어 넣기 알럿창 취소 버튼
    func cancelButton() -> some View {
        Button {
            newName = ""
        } label: {
            Text("취소")
        }
    }
    // 탑폴더의 앨범리스트
    func albumsInTopFolderLineView(topFolder: MLFolder) -> some View {
        ForEach(topFolder.albumsArray, id: \.self) { album in
            let subText = album.localIdentifier == (currentAlbum?.localIdentifier ?? "") ? "[현재 앨범]" : ""
            let selected = album.localIdentifier == albumToAddPhotos?.localIdentifier ?? ""
            AlbumLineView(albumType: albumType,
                          title: album.localizedTitle ?? "",
                          subText: subText,
                          selected: selected)
            .listRowBackground(Color.white)
            .listRowInsets(
                EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40)
            )
            .foregroundColor(
                album.localIdentifier == (currentAlbum?.localIdentifier ?? "")
                             ? .disabledColor
                             : (selected ? .selectedColor : .nonSelectedColor)
            )
            .onTapGesture {
                toggleAlbumToAddAssets(album: album)
            }
            .disabled(album.localIdentifier == (currentAlbum?.localIdentifier ?? ""))
        }
    }
    // 탑폴더의 폴더 리스트 + 하위 리스트
    func folderCategoryLineView(topFoler: MLFolder, proxy: ScrollViewProxy) -> some View {
        ForEach(topFoler.foldersArray, id: \.self) { folder in
            FolderCategory(albumType: albumType,
                           currentAlbum: currentAlbum,
                           folder: folder,
                           albumToAddPhotos: $albumToAddPhotos,
                           proxy: proxy)
            .listRowBackground(Color.white)
            .listRowInsets(
                EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40)
            )
        }
    }
}
// MARK: - 3. functions
extension MoveAssetCategoryView {
    // 앨범 라인 선택/해제 토글
    func toggleAlbumToAddAssets(album: PHCollection) {
        if albumToAddPhotos == album as? PHAssetCollection {
            albumToAddPhotos = nil
        } else {
            albumToAddPhotos = album as? PHAssetCollection
        }
    }
    // 앨범 만들기 -> 탑폴더에 앨범 만들어 사진 넣기
    func addAtTopFolderButton() -> some View {
        Button {
            let folder = Folder(isHome: true)
            let albumName = newName == "" ? "새앨범" : newName
            folder.createAlbum(folderToAdd: folder.folder, albumName) { album in
                if let album = album {
                    self.albumToAddPhotos = album
                    // 여기서 addAsset을 부르면 view가 change를 인지하지 못함 -> didset으로 처리
                    self.isSettedMLAlbum = true
                    newName = ""
                }
            }
        } label: {
            Text("최상위 폴더에 앨범 추가하기")
                .accentColor(.green)
        }
    }
    // 앨범 만들기 -> 선택한 폴더에 앨범 만들어 사진 넣기
    func addAtFolderButton() -> some View {
        Button {
            withAnimation {
//                self.isShowingSheet = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    stateChangeObject.newName = self.newName
//                    stateChangeObject.selectedIndexes = selectedItemsIndex
//                    self.isShowingSelectFolderSheet = true
//                    self.newName = ""
//                }
            }
        } label: {
            Text("폴더를 지정하여 앨범 추가하기")
        }
    }
    
    // 사진 넣기 최종 함수
    // tab1 : 선택한 앨범에 사진 넣기 / tab2 : Asset 다른 앨범으로 옮기기
    func addAssetIntoAlbum(assets: [MLAsset]) {
        guard let toAlbum = photoData.albums[albumToAddPhotos?.localIdentifier ?? ""]
        else { return }
        // 목표 앨범에서 삽입
        toAlbum.addAsset(assets: assets, completion: { bool in
            // 현재 앨범에서 제거
            if bool {
                if isDetailView {
                    DispatchQueue.main.async {
                        NotificationCenter.default
                            .post(name: .detailViewRemoveAsset, object: assets.first!)
                    }
                }
                switch albumType {
                case .home:
                    DispatchQueue.main.async {
                        NotificationCenter.default
                            .post(name: .innerFetchChange, object: "myPhotos")
                        NotificationCenter.default
                            .post(name: .outsideFetchChange, object: toAlbum.id)
                    }
                case .album:
                    // 다른 앨범으로 이동한 asset 제거
                    if let current = photoData.albums[currentAlbum?.localIdentifier ?? ""] {
                        current
                            .removeAssetFromAlbum(assets: assets, isHidden: isHiddenAssets) { bool in
                                DispatchQueue.main.async {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        NotificationCenter.default
                                            .post(name: .innerFetchChange, object: current.id)
                                    }
                                }
                        }
                    }
                default: break
                }
            }
            // 최근 작업 앨범 저장
            DispatchQueue.global(qos: .utility).async {
                photoData
                    .addRecentWorkSpace(id: toAlbum.id, isAlbum: true)
            }
        })
    }
}

// MARK: - 2nd Struct
struct FolderCategory: View {
    @EnvironmentObject var photoData: MLPhotoData
    var albumType: AlbumType = .album
    var currentAlbum: PHAssetCollection!
    var folder: PHCollectionList!
    @State var isOpen: Bool = false
    @Binding var albumToAddPhotos: PHAssetCollection!
    var proxy: ScrollViewProxy
    var depthCountCircle: Int = 1
    
    init(albumType: AlbumType, currentAlbum: PHAssetCollection!, folder: PHCollectionList!, albumToAddPhotos: Binding<PHAssetCollection?>,
         proxy: ScrollViewProxy, depthCountCircle: Int! = 1) {
        self.albumType = albumType
        self.currentAlbum = currentAlbum
        self.folder = folder
        self._albumToAddPhotos = albumToAddPhotos
        self.proxy = proxy
        self.depthCountCircle = depthCountCircle
    }
    
    
    var body: some View {
        let folder = photoData.folders[self.folder.localIdentifier] ?? MLFolder(collectionList: self.folder)
        Group {
            FolderLineView(
                isCollectionMoveView: false,
                title: folder.title,
                subImage: nil,
                isSelected: false,
                albumEmpty: folder.albumsArray.isEmpty)
                .foregroundColor(folder.fetchResult.count == 0
                                    ? .disabledColor : .nonSelectedColor)
                .id(folder.id)
                .onTapGesture {
                    withAnimation { isOpen.toggle() }
                }
            if isOpen {
                let current = currentAlbum ?? nil
                ForEach(folder.albumsArray , id: \.self) { album in
                    let subText = album == currentAlbum ? "[현재 앨범]" : ""
                    let selected = album == albumToAddPhotos
                    HStack {
                        DepthArrow(count: depthCountCircle, subCount: 2)
                        AlbumLineView(albumType: albumType,
                                      title: album.localizedTitle ?? "",
                                      subText: subText,
                                      selected: selected)
                        .listRowBackground(Color.white)
                        .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                        .foregroundColor(album == currentAlbum ? .disabledColor : (album == albumToAddPhotos ? .selectedColor:.nonSelectedColor))
                        .id(album.localIdentifier)
                        .onTapGesture {
                            if albumToAddPhotos == album {
                                albumToAddPhotos = nil
                            } else {
                                albumToAddPhotos = album
                            }
                        }
                        .disabled(album == currentAlbum)
                    }
                }
                ForEach(folder.foldersArray, id: \.self) { folder in
                    FolderCategory(albumType: albumType,
                                   currentAlbum: current,
                                   folder: folder,
                                   albumToAddPhotos: $albumToAddPhotos,
                                   proxy: proxy,
                                   depthCountCircle: depthCountCircle + 1)
                }
                .onChange(of: isOpen) { newValue in
                    if newValue {
                        DispatchQueue.main.async {
                            proxy.scrollTo(
                                folder.foldersArray.last?.localIdentifier ?? "",
                                anchor: .bottom)
                        }
                    }
                }
            }
        }
        
//        if PHCollection.fetchCollections(in: folder, options: nil).count != 0 {
//            let collections = PHCollection
//                .fetchCollections(in: folder, options: nil)
////            HStack {
////                DepthCircle(count: depthCountCircle - 1, subCount: 2)
//                
////            }
//            if isOpen {
//                let current = currentAlbum ?? nil
//                ForEach(0..<collections.count, id: \.self) { index in
//                    if collections[index].isKind(of: PHAssetCollection.self) {
//                        let album = collections[index]
//                        let subText = album == currentAlbum ? "[현재 앨범]" : ""
//                        let selected = album == albumToAddPhotos
//                        HStack {
//                            DepthArrow(count: depthCountCircle, subCount: 2)
//                            AlbumLineView(albumType: albumType,
//                                          title: album.localizedTitle ?? "",
//                                          subText: subText,
//                                          selected: selected)
//                                .listRowBackground(Color.white)
//                                .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
//                                .foregroundColor(album == currentAlbum ? .disabledColor : (album == albumToAddPhotos ? .selectedColor:.nonSelectedColor))
//                                .id(album.localIdentifier)
//                                .onTapGesture {
//                                    if albumToAddPhotos == album as? PHAssetCollection {
//                                        albumToAddPhotos = nil
//                                    } else {
//                                        albumToAddPhotos = album as? PHAssetCollection
//                                    }
//                                }
//                                .disabled(album == currentAlbum)
//                        }
//                    }
//                }
//            }
//        } else {
//            HStack {
//                DepthArrow(count: depthCountCircle - 1, subCount: 1)
//                FolderLineView(isCollectionMoveView: false,
//                               title: folder.localizedTitle ?? "",
//                               subImage: "",
//                               isSelected: false)
//                    .foregroundColor(.disabledColor)
//                    .disabled(albumType == .home)
//                    .id(folder.localIdentifier)
//            }
//        }
    }
}

struct CategoryScene_Previews: PreviewProvider {
    static var previews: some View {
        MoveAssetCategoryView(
            isShowingSelectFolderSheet: .constant(false),
            object: .constant(nil),
            currentAlbum: nil,
            isHiddenAssets: false,
            selectedItems: [])
    }
}

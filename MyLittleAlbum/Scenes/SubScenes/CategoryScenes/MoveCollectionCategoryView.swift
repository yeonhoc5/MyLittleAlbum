//
//  MoveCollectionCategoryView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/28.
//

import SwiftUI
import Photos

// 기본적으로 앨범씬에서 폴더/앨범 이용용으로 사용
// - 그 외 사진을 넣을 앨범을 만들 경우 사용

// MARK: - 1st Struct
struct MoveCollectionCategoryView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @Binding var moveObject: MoveCollectionObject!
    
    // 원래 위치 폴더
    let currentParent: MLFolder
    // 이동시킬 것들
    var objectCellType: CellType
    var objectAlbum: PHAssetCollection!
    var objectFolder: PHCollectionList!
    
    var nameSpace: Namespace.ID
    @State var lowerFolders: [String] = []
    
    // [마이포토] 탭에서 폴더 지정하여 앨범 생성할 경우
//    var currentAlbum: MLAlbum! = nil
//    var filteringType: FilteringType = .all
    // 이동할 목표지로 선택된 폴더
    @State private var folderToAddCollection: PHCollectionList!
    // 이동할 목표지가 top폴더인지 선택 구분
    @State var isTopFolderSelected: Bool = false
    // 버튼 타이틀 체인지
    @State var moveBtnTitle: String = ""
    let width: CGFloat = 70
    
    var body: some View {
        NavigationView {
            VStack(spacing: 5) {
                moveCollectionTitleView(cellType: objectCellType)
                VStack(spacing: 10) {
                    legendView
                    categoryView()
                    recentSelectedView()
                }
                HStack {
                    btnCancelAndClose
                    btnAddAndClose
                }
                .padding([.horizontal, .top], 20)
            }
            .padding(.bottom, 20)
            .background(FancyBackground())
        }
        .onAppear {
            if objectCellType == .folder {
                if let folder = objectFolder {
                    DispatchQueue.global(qos: .userInteractive).async {
                        getLowerFolders(folder: folder)
                    }
                }
            }
        }
//        .onChange(of: isSettedMLAlbum) { newValue in
//            if newValue {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    addAssetIntoAlbum()
//                }
//                isShowingSheet = false
//            }
//        }
    }
}


// MARK: - extension 1. subViews
extension MoveCollectionCategoryView {
    func recentSelectedView() -> some View {
        return VStack(alignment: .leading, spacing: 5) {
            Text("최근 선택한 폴더 리스트")
                .foregroundStyle(Color.gray)
                .padding(.horizontal, 22)
            SelectableCollectionView(
                collectionType: .folder,
                emptytext: "최근 선택한 폴더가 없습니다.",
                currentAlbum: nil,
                albumArray: [],
                albumToAddPhotos: .constant(nil),
                depthCount: 0,
                objectFolder: objectFolder,
                currentParent: currentParent.phCollectionList,
                folderToAddCollection: $folderToAddCollection,
                isTopFolderSelected: $isTopFolderSelected,
                lowers: lowerFolders)
        }
    }
    func categoryView() -> some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                List {
                    Group {
                        topFolderLineView
                        subFolderLineView(scrollProxy: scrollProxy)
                    }
                    .listRowBackground(Color.white)
                    .listRowInsets(
                        EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40)
                    )
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .mask {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: screenSize.width - 44,
                               height: proxy.size.height)
                }
            }
        }
    }
    // View 타이틀
    func moveCollectionTitleView(cellType: CellType) -> some View {
        let collectionTitle = cellType == .folder ? "폴더" : "앨범"
        return HStack(spacing: 20) {
            CellView(uiMode: photoData.uiMode,
                     cellType: cellType,
                     index: moveObject?.objectColorIndex ?? 0,
                     width: width) { size, namespace in
                Group {
                    if cellType == .folder {
                        if let folder = photoData.folders[objectFolder.localIdentifier] {
                            FolderCoverView(folder: folder,
                                            phCollectionList: objectFolder,
                                            uiMode: photoData.uiMode,
                                            size: size,
                                            cellNameSpace: namespace)
                        } else {
                            EmptyView()
                        }
                    } else {
                        if let album = photoData.albums[objectAlbum.localIdentifier] {
                            AlbumCoverView(album: album,
                                           assetCollection: objectAlbum,
                                           uiMode: photoData.uiMode,
                                           cellType: cellType,
                                           size: size,
                                           colorIndex: 0,
                                           albumCell: namespace,
                                           isEditingMode: false)
                        } else {
                            EmptyView()
                        }
                    }
                }
            }
            .matchedGeometryEffect(id: moveObject?.objectIdentifier ?? "",
                                    in: nameSpace)
            VStack(alignment: .leading, spacing: 15) {
                Text("\(collectionTitle)의 위치를 이동합니다.")
                Text("원하는 위치를 선택해 주세요.")
            }
            .foregroundColor(.gray)
            .font(.headline)
        }
        .padding(.horizontal, 20)
        .frame(height: cellHeight(width: width,
                                  uiMode: photoData.uiMode,
                                  cellType: .album) + 50 )
    }

    // 탑폴더 라인
    var topFolderLineView: some View {
        let disable = currentParent.phCollectionList == nil
        return FolderLineView(isCollectionMoveView: true,
                              title: "최상위 폴더",
                              subImage: disable ? "chevron.left.circle.fill" : "",
                              isSelected: isTopFolderSelected,
                              albumEmpty: true)
        .foregroundColor(disable ? .disabledColor
                                : (isTopFolderSelected
                                        ? .selectedColor :
                                        .nonSelectedColor))
        .onTapGesture {
            if currentParent.phCollectionList != nil {
                isTopFolderSelected.toggle()
                moveBtnTitle = isTopFolderSelected ? "[최상위] 폴더로" : ""
                folderToAddCollection = nil
            }
        }
        .disabled(disable)
    }
    // 그 외 라인
    func subFolderLineView(scrollProxy: ScrollViewProxy) -> some View {
        let topFolders = photoData.folders["topFolder"]?.foldersArray ?? []
        return ForEach(topFolders, id: \.localIdentifier) { folder in
            FolderCategoryView(
                isHome: false,
                currentFolder: currentParent.phCollectionList,
                lineFolder: folder,
                toMoveCollection: objectCellType == .folder ? objectFolder : objectAlbum,
                isTopFolderSelected: $isTopFolderSelected,
                folderToAddCollection: $folderToAddCollection,
                albumToAddPhotos: .constant(nil),
                inheritedDisable: folder == objectFolder,
                showAlbumList: false,
                moveBtnTitle: $moveBtnTitle,
                scrollProxy: scrollProxy) { selectedFolder in
//                if folderToAddCollection == nil || folderToAddCollection != selectedFolder {
//                    folderToAddCollection = selectedFolder
//                } else {
//                    folderToAddCollection = nil
//                }
            }
        }
    }
    func chevronDirection(direction: DepthType) -> some View {
        let image = switch direction {
        case .current: "chevron.left.circle.fill" // 현재위치
        case .none: "circle.circle.fill" // 오브젝트 대상
        case .secondary: "chevron.down.circle.fill" // 하위
        }
        let text = switch direction {
        case .current: "현재 위치"
        case .none: "이동할 객체"
        case .secondary: "하위 폴더"
        }
        return HStack(spacing: 3) {
            imageScaledFit(systemName: image, width: 14, height: 14)
            Text(text)
                .font(.callout)
        }
        .foregroundStyle(.gray.opacity(0.6))
    }
}
// MARK: - extension 2. functions
extension MoveCollectionCategoryView {
    var legendView: some View {
        HStack(spacing: 10) {
            Spacer()
            chevronDirection(direction: .current)
            if objectCellType == .folder {
                chevronDirection(direction: .none)
                chevronDirection(direction: .secondary)
            }
        }
        .padding(.horizontal, 30)
    }
    var btnCancelAndClose: some View {
        Button {
            moveObject = nil
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
    
    var btnAddAndClose: some View {
        let disable = !isTopFolderSelected && folderToAddCollection == nil
        var tempIndex: Int?
        return Button {
            dispatchAnimation {
                self.moveObject = nil
            }
            phDataQueue.async {
                if let destinationFolder = photoData.folders[isTopFolderSelected ? "topFolder" : folderToAddCollection.localIdentifier] {
                    destinationFolder
                        .displaceCollelction(
                            collectionType: objectCellType == .folder ? .folder : .album,
                            collection: (objectCellType == .folder ? self.objectFolder : self.objectAlbum) as PHCollection) { result in
                            if result {
                                if objectCellType == .folder {
                                    if let index = currentParent.foldersArray.firstIndex(of: objectFolder) {
                                        tempIndex = index
                                        dispatchAnimation {
                                            currentParent.foldersArray.remove(at: index)
                                        }
                                        print("제거됨 at: \(currentParent.title) what: \(objectFolder?.localizedTitle ?? "nil")")
                                    }
                                } else {
                                    if let index = currentParent.albumsArray.firstIndex(of: objectAlbum) {
                                        tempIndex = index
                                        dispatchAnimation {
                                            currentParent.albumsArray.remove(at: index)
                                        }
                                    }
                                }
                                dispatchAnimation {
                                    currentParent.fetchCollection()
                                }
                            } else {
                                if let tempIndex = tempIndex {
                                    if objectCellType == .folder {
                                        dispatchAnimation {
                                            currentParent.foldersArray
                                                .insert(objectFolder, at: tempIndex)
                                        }
                                    } else {
                                        dispatchAnimation {
                                            currentParent.albumsArray
                                                .insert(objectAlbum, at: tempIndex)
                                        }
                                    }
                                }
                            }
                    }
                    // 최근 작업 폴더 저장
                    DispatchQueue.global(qos: .utility).async {
                        photoData
                            .addRecentWorkSpace(id: destinationFolder.id, isAlbum: false)
                    }
                }
            }
        } label: {
            let folder = isTopFolderSelected ? "[최상위] 폴더" : (folderToAddCollection != nil ? folderToAddCollection?.localizedTitle ?? "" : "")
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                FlipViewTransitor(isModeChange: disable) {
                    VStack {
                        HStack(spacing: 1) {
                            Text("\(folder)")
                                .truncationMode(.middle)
                                .contentTransition(.numericText())
                            Text("(으)로")
                        }
                        Text("이동하기")
                    }
                } flipReverseView: {
                    Text("폴더를 선택해 주세요.")
                }
                .foregroundStyle(disable ? .gray : .white)
            }
        }
        .frame(height: 50)
        .foregroundStyle(disable ? Color.addButton : .blue)
        .disabled(folderToAddCollection == nil && isTopFolderSelected == false)
        .animation(.easeOut, value: disable)
    }
    
    func getLowerFolders(folder: PHCollectionList) {
        if let folder = photoData.folders[folder.localIdentifier] {
            self.lowerFolders
                .append(contentsOf: folder.foldersArray.map{ $0.localIdentifier })
            for lower in folder.foldersArray {
                getLowerFolders(folder: lower)
            }
        }
    }
}

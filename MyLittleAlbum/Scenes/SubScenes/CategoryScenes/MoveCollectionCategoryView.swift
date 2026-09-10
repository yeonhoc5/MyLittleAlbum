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
  var objectType: CollectionType
  let objectCollection: SubCollection
  
  var nameSpace: Namespace.ID
  @State var lowerFolders: [String] = []
  
  // [마이포토] 탭에서 폴더 지정하여 앨범 생성할 경우
  //    var currentAlbum: MLAlbum! = nil
  //    var filteringType: FilteringType = .all
  // 이동할 목표지로 선택된 폴더
  @State private var folderToAddCollection: SubCollection!
  // 이동할 목표지가 top폴더인지 선택 구분
//  @State var isTopFolderSelected: Bool = false
  // 버튼 타이틀 체인지
  @State var moveBtnTitle: String = ""
  let width: CGFloat = 70
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 5) {
        moveCollectionTitleView(collectionType: objectType)
        VStack(spacing: 10) {
          legendView
          categoryView()
          recentSelectedView()
        }
        HStack {
          btnCancelAndClose
          btnAddAndClose(objectID: objectCollection.id)
        }
        .padding([.horizontal, .top], 20)
      }
      .padding(.bottom, 20)
      .background(FancyBackground())
    }
    .onAppear {
      if objectCollection.type == .folder {
        DispatchQueue.global(qos: .userInteractive).async {
          getLowerFolders(subFolder: objectCollection)
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
    let subCurrent = currentParent
      .subCollection(id: currentParent.id, type: .folder)
    return VStack(alignment: .leading, spacing: 5) {
      Text("최근 선택한 \(currentParent.folderType == .shareCategory ? "공유" : "") 폴더 리스트")
        .foregroundStyle(Color.gray)
        .padding(.horizontal, 22)
      SelectableCollectionView(
        folderType: currentParent.folderType,
        recentType: currentParent.folderType == .userFolder
                      ? .folder : .category,
        emptytext: "최근 선택한 폴더가 없습니다.",
        currentAlbumID: "",
        albumArray: [],
        albumToAddPhotos: .constant(nil),
        depthCount: 0,
        objectFolder: objectCollection,
        currentParent: subCurrent,
        folderToAddCollection: $folderToAddCollection,
        isTopFolderSelected: .constant(false),
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
            EdgeInsets(top: 0, leading: 40,
                       bottom: 0, trailing: 40)
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
  func moveCollectionTitleView(collectionType: CollectionType) -> some View {
    let collectionTitle = collectionType == .folder ? "폴더" : "앨범"
    return HStack(spacing: 20) {
      CellView(uiMode: photoData.uiMode,
               cellType: collectionType == .album ? .album : .folder,
               index: moveObject?.objectColorIndex ?? 0,
               width: width) { uiMode, size, namespace in
        Group {
          if collectionType == .folder {
            if let folder = photoData
              .mlFolder(type: currentParent.folderType,
                        objectCollection.id) {
              FolderCoverView(folder: folder,
                              subFolder: objectCollection,
                              uiMode: uiMode,
                              size: size,
                              cellNameSpace: namespace)
            } else {
              EmptyView()
            }
          } else {
            if let album = photoData
              .mlAlbum(type: currentParent.folderType,
                       objectCollection.id) {
              AlbumCoverView(album: album,
                             uiMode: photoData.uiMode,
                             cellType: collectionType == .album ? .album : .folder,
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
    let topID = currentParent.folderType == .userFolder ? "topFolder" : "shareTop"
    let topSelected = folderToAddCollection?.id == topID
    let disable = currentParent.id == topID
    return FolderLineView(isCollectionMoveView: true,
                          title: "최상위 폴더",
                          subImage: disable ? "chevron.left.circle.fill" : "",
                          isSelected: topSelected,
                          albumEmpty: true)
    .foregroundColor(disable ? .disabledColor
                     : (topSelected
                        ? .selectedColor : .nonSelectedColor))
    .onTapGesture {
      if !disable {
        let topCollection = SubCollection(
          id: topID, title: "최상위 폴더", type: .folder)
        moveBtnTitle = topSelected ? "[최상위 폴더]로" : ""
        selectFolder(sub: topCollection)
      }
    }
    .disabled(disable)
  }
  func selectFolder(sub: SubCollection) {
    dispatchAnimation {
      if folderToAddCollection == sub {
        folderToAddCollection = nil
      } else {
        folderToAddCollection = sub
      }
    }
  }
  // 그 외 라인
  func subFolderLineView(scrollProxy: ScrollViewProxy) -> some View {
    let folderType = currentParent.folderType
    let topFolders = photoData
      .mlFolder(type: folderType, folderType == .userFolder
                                  ? "topFolder" : "shareTop")?
      .foldersArray ?? []
    let subCurrent = SubCollection(id: currentParent.id,
                                   title: currentParent.title,
                                   type: .folder)
    return ForEach(topFolders, id: \.self) { subFolder in
      FolderCategoryView(
        isHome: false,
        folderType: folderType,
        currentFolder: subCurrent,
        lineSubFolder: subFolder,
        toMoveCollection: objectCollection,
        isTopFolderSelected: .constant(false),
        folderToAddCollection: $folderToAddCollection,
        albumToAddPhotos: .constant(nil),
        inheritedDisable: subFolder == objectCollection,
        showAlbumList: false,
        moveBtnTitle: $moveBtnTitle,
        scrollProxy: scrollProxy) { selectedFolder in }
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
      if objectType == .folder {
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
  
  func btnAddAndClose(objectID: String) -> some View {
    let disable = folderToAddCollection == nil
    let folderType = currentParent.folderType
    var tempIndex: Int?
    return Button {
      guard let destinationFolder = photoData.mlFolder(
        type: folderType, 
        folderToAddCollection?.id ?? ""
      ) else { return }
      dispatchAnimation { self.moveObject = nil }
      phDataQueue.async {
        if folderType == .userFolder {
          guard let collection = objectType == .folder
            ? photoData.mlFolder(type: .userFolder, objectID)?
                    .phCollectionList
            : photoData.mlAlbum(type: .userFolder, objectID)?
                    .phAssetCollection
          else { return }
          destinationFolder
            .displaceCollelction(
              collectionType: objectType,
              collection: collection as PHCollection) { result in
                if result {
                  if objectType == .folder {
                    if let index = currentParent.foldersArray
                      .firstIndex(of: objectCollection) {
                      tempIndex = index
                      dispatchAnimation {
                        currentParent.foldersArray
                          .remove(at: index)
                      }
                      print("제거됨 at: \(currentParent.title) what: \(objectCollection.id)")
                    }
                  } else {
                    if let index = currentParent.albumsArray
                      .firstIndex(of: objectCollection) {
                      tempIndex = index
                      dispatchAnimation {
                        currentParent.albumsArray
                          .remove(at: index)
                      }
                    }
                  }
                  dispatchAnimation {
                    currentParent
                      .fetchCollection(folderType: .userFolder)
                  }
                } else {
                  if let tempIndex = tempIndex {
                    if objectType == .folder {
                      dispatchAnimation {
                        currentParent.foldersArray
                          .insert(objectCollection,
                                  at: tempIndex)
                      }
                    } else {
                      dispatchAnimation {
                        currentParent.albumsArray
                          .insert(objectCollection,
                                  at: tempIndex)
                      }
                    }
                  }
                }
              }
        } else {
          // step 1. MlFolder
          // step 1-1. 현재 subCollection 제거
          photoData
            .mlFolder(type: .shareCategory, currentParent.id)?
            .removeCategory(id: objectCollection.id,
                            collectionType: objectType ) { sub in
              // step 1-2. 목적지에 subCollection 삽입
              photoData
                .mlFolder(type: folderType, folderToAddCollection.id)?
                .addSubCollection(type: sub.type,
                                  collection: sub) {
                  checkCategory()
                }
            }
          // step 2. shareCategory
          // step 2-1. 현재 shared의 subFolder 제거
          guard var currentShared = photoData
                            .shareCategories[currentParent.id],
                var desti = photoData
                            .shareCategories[destinationFolder.id]
          else { return }
          DispatchQueue.global().async {
            if objectType == .folder {
              if let index =
                  currentShared.subFolder.firstIndex(of: objectID) {
                let collection = currentShared.subFolder
                  .remove(at: index)
                // step 2-2. 목적지 shared의 subFolder 추가
                desti.subFolder.append(collection)
                // step 2-3. shared Data 저장
                photoData.updateCategory([currentShared, desti]) {
                  photoData.saveCategoriData()
                }
              }
            } else {
              if let index =
                  currentShared.subAlbums.firstIndex(of: objectID) {
                let collection = currentShared.subAlbums
                                .remove(at: index)
                // step 2-2. 목적지 shared의 subFolder 추가
                desti.subAlbums.append(collection)
                // step 2-3. shared Data 저장
                photoData.updateCategory([currentShared, desti]) {
                  photoData.saveCategoriData()
                }
              }
            }
          }
        }
        // 최근 작업 폴더 저장
        DispatchQueue.global(qos: .utility).async {
          photoData
            .addRecentWorkSpace(
              id: destinationFolder.id,
              recentType: currentParent.folderType == .userFolder
                          ? .folder : .category)
        }
      }
    } label: {
      let topFolderSelected = folderToAddCollection?.id == "topFolder" || folderToAddCollection?.id == "shareTtop"
      let folder = topFolderSelected
      ? "[최상위] 폴더" : (folderToAddCollection != nil
                      ? folderToAddCollection?.title ?? "" : "")
      ZStack {
        RoundedRectangle(cornerRadius: 10)
        FlipViewTransitor(isModeChange: disable) {
          conditionalStackView(condition: device != .pad,
                               spacing: 5,
                               vAlignment: .center) {
            Group {
              HStack(spacing: 1) {
                Text("\(folder)")
                  .truncationMode(.middle)
                  .contentTransition(.numericText())
                Text("(으)로")
              }
              Text("이동하기")
            }
          }
        } flipReverseView: {
          Text("폴더를 선택해 주세요.")
        }
        .foregroundStyle(disable ? .gray : .white)
      }
    }
    .frame(height: 50)
    .foregroundStyle(disable ? Color.addButton : .blue)
    .disabled(folderToAddCollection == nil)
    .animation(.easeOut, value: disable)
  }
  
  func getLowerFolders(subFolder: SubCollection) {
    if let folder = photoData
              .mlFolder(type: currentParent.folderType,
                                       subFolder.id) {
      self.lowerFolders
        .append(contentsOf: folder.foldersArray.map{ $0.id })
      for lower in folder.foldersArray {
        getLowerFolders(subFolder: lower)
      }
    }
  }
  
  func checkCategory(id: String = "shareTop", retainText: String = "") {
    if let folder = photoData.shareFolders[id] {
      for sub in folder.foldersArray {
        print("[\(retainText)\(folder.title)]", sub.title)
        checkCategory(id: sub.id, retainText: "\(retainText)\(folder.title)-")
      }
    }
  }
}

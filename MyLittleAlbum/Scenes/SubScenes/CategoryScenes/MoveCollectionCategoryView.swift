//
//  MoveCollectionCategoryView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/28.
//

import SwiftUI
import Photos

// MARK: - 1st Struct
struct MoveCollectionCategoryView: View {
    var isHome: Bool! = false
    @Binding var isShowingSheet: Bool
    // 이동시킬 앨범/폴더의 현재 폴더 -> 해당 폴더 및 하위 폴더 disable 처리
    @Binding var currentFolder: Folder!
    // [마이포토] 탭에서 폴더 지정하여 앨범 생성할 경우
    var currentAlbum: Album! = nil
    // 이동시킬 앨범/폴더
    @ObservedObject var stateChangeObject: StateChangeObject
    // 이동할 목표지로 선택된 폴더
    @State private var folderToAddCollection: PHCollectionList!
    // 이동할 목표지가 top폴더인지 선택 구분
    @State var isSelectedTopFolder: Bool = false
    // 버튼 타이틀 체인지
    @State var moveBtnTitle: String = ""
    
    @State var albumToAdd: Album!
    @State var isSettedNewAlbum: Bool = false
    
    var body: some View {
        let collectionType = isHome ? "앨범" : (stateChangeObject.collectionToEdit.isKind(of: PHAssetCollection.self) ? "앨범" : "폴더")
        NavigationView {
            VStack {
                moveCollectionTitleView(collectionType: collectionType)
                GeometryReader { proxy in
                    List {
                        topFolderLineView
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                        subFolderLineView
                            .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .mask {
                        RoundedRectangle(cornerRadius: 15)
                            .frame(width: screenSize.width - 44, height: proxy.size.height)
                    }
                }
            }
            .background(FancyBackground())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { toolItemLeading }
                ToolbarItem(placement: .navigationBarTrailing) { toolItemTrailing }
            }
        }
        .onDisappear { currentFolder = nil }
        .onChange(of: isSettedNewAlbum) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    addAssetIntoAlbum()
                }
                isShowingSheet = false
            }
        }
    }
}


// MARK: - extension 1. subViews
extension MoveCollectionCategoryView {
    // View 타이틀
    func moveCollectionTitleView(collectionType: String) -> some View {
        VStack(spacing: 5) {
            Text("폴더를 선택해 주세요.")
                .font(.title)
                .foregroundColor(.white)
            if !isHome {
                Text("이동할 \(collectionType) : [\(stateChangeObject.collectionToEdit.localizedTitle ?? "")]")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.bottom, 10)
    }
    
    // 툴바 버튼 - cancel
    var toolItemLeading: some View {
        Button("취소") {
            self.isShowingSheet = false
        }
    }

    // 툴바 버튼 - 옮기기
    var toolItemTrailing: some View {
        let actionTitle = isHome ? "넣기" : "이동하기"
        return Button("\(moveBtnTitle) \(actionTitle)")  {
            if isHome {
                addAlbumAtTheFolderWithPhotos()
                self.isShowingSheet = false
            } else {
                if isSelectedTopFolder {
                    displaceCollelction(isTopFolder: isSelectedTopFolder)
                } else {
                    displaceCollelction(isTopFolder: isSelectedTopFolder, 
                                        folder: folderToAddCollection)
                }
                self.isShowingSheet = false
            }
        }
        .disabled(!isHome && folderToAddCollection == nil && isSelectedTopFolder == false)
    }
    // 탑폴더 라인
    var topFolderLineView: some View {
        let collectionType = isHome ? "앨범" : (stateChangeObject.collectionToEdit.isKind(of: PHAssetCollection.self) ? "앨범" : "폴더")
        return FolderLineView(title: "최상위 폴더", subText: isHome ? "" : "\(currentFolder.folder == nil ? "[이동할 \(collectionType)의 현재 위치]":"")")
            .listRowBackground(Color.white)
            .foregroundColor(!isHome && currentFolder.folder == nil ? .disabledColor : (isSelectedTopFolder ? .selectedColor : .nonSelectedColor))
            .onTapGesture {
                isSelectedTopFolder.toggle()
                let letter = isHome ? "에" : "로"
                moveBtnTitle = isSelectedTopFolder ? "[최상위] 폴더\(letter)" : ""
                folderToAddCollection = nil
            }
            .disabled(self.isHome ? false : currentFolder.folder == nil)
    }
    // 그 외 라인
    var subFolderLineView: some View {
        let collections = PHCollection.fetchTopLevelUserCollections(with: nil)
        return ForEach(0..<collections.count, id: \.self) { index in
            if collections[index].isKind(of: PHCollectionList.self) {
                FolderCategoryView(isHome: isHome,
                                   stateChangeObject: stateChangeObject,
                                   currentFolder: isHome ? nil : currentFolder.folder,
                                   folder: collections[index] as! PHCollectionList,
                                   selectedCollection: stateChangeObject.collectionToEdit,
                                   folderToAddCollection: $folderToAddCollection,
                                   isSelectedTopFolder: $isSelectedTopFolder,
                                   moveBtnTitle: $moveBtnTitle)
                .listRowBackground(Color.white)
            }
        }
    }
}
// MARK: - extension 2. functions
extension MoveCollectionCategoryView {
    // [마이 앨범] Tab :  move collection 함수
    func displaceCollelction(isTopFolder: Bool, folder: PHCollectionList! = nil) {
        PHPhotoLibrary.shared().performChanges {
            var addRequest = PHCollectionListChangeRequest()
            if isTopFolder {
                let fetchResult = PHCollection.fetchTopLevelUserCollections(with: nil)
                addRequest = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: fetchResult) ?? addRequest
            } else {
                let fetchResult = PHCollection.fetchCollections(in: folder, options: nil)
                addRequest = PHCollectionListChangeRequest(for: folder, childCollections: fetchResult) ?? addRequest
            }
            addRequest.addChildCollections([stateChangeObject.collectionToEdit] as NSFastEnumeration)
        } completionHandler: { success, _ in
            folderToAddCollection = nil
            isSelectedTopFolder = false
        }
    }
    // [마이 포토] Tab : 폴더 지정 후 앨범 만들기
    func addAlbumAtTheFolderWithPhotos() {
        let folder = isSelectedTopFolder ? Folder(isHome: true) : Folder(folder: folderToAddCollection)
        let albumName = stateChangeObject.newName == "" ? "새앨범" : stateChangeObject.newName
        folder.createAlbum(depth: .current, folderToAdd: folder.folder, albumName) { album in
            if let album = album {
                self.albumToAdd = Album(album: album)
                self.isSettedNewAlbum = true
            }
        }
    }
    
    func addAssetIntoAlbum() {
        var assetArray: [PHAsset] = []
        switch currentAlbum.filteringType {
        case .all: assetArray = currentAlbum.photosArray
        case .image: assetArray = currentAlbum.photosArray.filter({$0.mediaType == .image})
        case .video: assetArray = currentAlbum.photosArray.filter({$0.mediaType == .video})
        }
        var assets: [PHAsset] = []
        let indexSet = stateChangeObject.selectedIndexes.sorted(by: { $0 < $1 })
        for i in indexSet {
            assets.append(assetArray[i])
        }
        
        DispatchQueue.main.async {
            albumToAdd.addAsset(assets: assets, stateObject: stateChangeObject)
            stateChangeObject.selectedIndexes = []
//            stateChangeObject.assetChanged = true
            stateChangeObject.assetChanged = .changed
        }
    }
    
}

// MARK: - 2nd Struct
struct FolderCategoryView: View {
    var isHome: Bool
    @ObservedObject var stateChangeObject: StateChangeObject
    // 현재 위치
    var currentFolder: PHCollectionList!
    // 해당 라인 폴더
    var folder: PHCollectionList
    // 이동시킬 앨범/폴더
    var selectedCollection: PHCollection!
    // 이동할 목표지로 선택할 폴더
    @Binding var folderToAddCollection: PHCollectionList!
    // (폴더 이동의 경우) 이동시킬 폴더의 하위폴더들은 전부 disable 처리
    var inheritedDisable: Bool = false
    // 폴더 depth 정보
    var depthCount = 1
    
    @Binding var isSelectedTopFolder: Bool
    @Binding var moveBtnTitle: String
    
    var body: some View {
        let folderFetchResult = PHCollection.fetchCollections(in: folder, options: nil)
        if folderFetchResult.objects(at: IndexSet(0..<folderFetchResult.count)).filter({ $0.isKind(of: PHCollectionList.self) }).count != 0 {
            folderLineView
            let folderFetchResult = PHCollection.fetchCollections(in: folder, options: nil)
            ForEach(0..<folderFetchResult.count, id: \.self) { index in
                if folderFetchResult[index].isKind(of: PHCollectionList.self) {
                    FolderCategoryView(isHome: isHome,
                                       stateChangeObject: stateChangeObject,
                                       currentFolder: currentFolder,
                                       folder: folderFetchResult[index] as! PHCollectionList,
                                       selectedCollection: selectedCollection,
                                       folderToAddCollection: $folderToAddCollection,
                                       inheritedDisable: isHome ? false : selectedCollection == folder || inheritedDisable,
                                       depthCount: depthCount + 1,
                                       isSelectedTopFolder: $isSelectedTopFolder,
                                       moveBtnTitle: $moveBtnTitle)
                }
            }
        } else {
            folderLineView
        }
    }
    
    var folderLineView: some View {
        let collectionType = isHome ? "앨범" : (selectedCollection.isKind(of: PHAssetCollection.self) ? "앨범" : "폴더")
        let sideText = isHome ? "" : (folder == currentFolder ? "[이동할 \(collectionType)의 현재 위치]" :(selectedCollection == folder ? "[이동할 \(collectionType)]":""))
        let disable = isHome ? false : (folder == currentFolder || (selectedCollection.isKind(of: PHCollectionList.self) && folder == selectedCollection))
        return HStack {
            DepthCircle(count: depthCount)
            FolderLineView(title: "\(folder.localizedTitle ?? "")", subText: sideText)
        }
        .listRowBackground(Color.white)
        .foregroundColor(disable || inheritedDisable ? .disabledColor : (folderToAddCollection == folder ? .selectedColor:.nonSelectedColor))
        .onTapGesture {
            folderToAddCollection = folderToAddCollection == folder ? nil : folder
            isSelectedTopFolder = false
            let letter = isHome ? "에" : "로"
            moveBtnTitle = folderToAddCollection == nil ? "" : "[\(folder.localizedTitle ?? "")] 폴더\(letter)"
        }
        .disabled(disable || inheritedDisable)
    }
}

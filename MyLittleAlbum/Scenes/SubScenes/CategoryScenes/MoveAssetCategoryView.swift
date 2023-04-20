//
//  CategoryScene.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/11.
//

import SwiftUI
import Photos
import PhotosUI

// MARK: - 1st Struct
struct MoveAssetCategoryView: View {
    @Binding var isShowingSheet: Bool
    @Binding var isShowingSelectFolderSheet: Bool
    // top폴더의 앨범 정보 가져오기
    @StateObject var stateChangeObject: StateChangeObject
    
    // 버튼 타이틀 조정을 위해 "홈/앨범" 확인
    var albumType: AlbumType = .album
    // 현재 앨범
    var currentAlbum: Album!
    
    // 앨범에서 선택한 사진 인덱스
    @Binding var selectedItemsIndex: [Int]
    // 사진을 옮길 목표지 앨범
    @State var albumToAddPhotos: PHAssetCollection!
    // 새로운 앨범 만들기
    @State var newName: String = ""
    
    // 버튼 타이틀
    @State var addBtnTitle: String = ""
    // 시트 닫힌 후 select모드 조정
    @Binding var isSelectMode: Bool
    
    @State var isSettedNewAlbum: Bool = false

    var body: some View {
        VStack {
            moveAssetTitleView
            ScrollViewReader { scrollProxy in
                GeometryReader { proxy in
                    List {
                        createAlbumLineView
                        albumsInTopFolderLineView
                        folderCategoryLineView(proxy: scrollProxy)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .mask { roundedFrame(proxy: proxy) }
                }
            }
        }
        .background(Color.fancyBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { toolbarItemLeading }
            ToolbarItem(placement: .navigationBarTrailing) { toolbarItemTrailing }
        }
        .alert("앨범 이름을 입력해주세요.", isPresented: $stateChangeObject.isShowingAlert, actions: {
            TextField("추가할 앨범 이름을 입력하세요.", text: $newName)
            cancelButton()
            addAtTopFolderButton()
            addAtFolderButton()
        }, message: {
            Text("\n앨범을 추가하면 선택한 사진/비디오가\n추가한 앨범에 들어갑니다.")
                .multilineTextAlignment(.leading)
        })
        .onChange(of: isSettedNewAlbum) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    addAssetIntoAlbum(indexSet: selectedItemsIndex.sorted{ $0 < $1})
                }
                isShowingSheet = false
            }
        }
    }
}
// MARK: - 2. subViews
extension MoveAssetCategoryView {
    // 타이틀 뷰
    var moveAssetTitleView: some View {
        Text("앨범을 선택해 주세요.")
            .font(.title)
            .foregroundColor(.white)
    }
    // 리스트 목록 프레임
    func roundedFrame(proxy: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 15)
            .frame(width: screenSize.width - 44, height: proxy.size.height)
    }
    // (왼쪽) 취소 버튼
    var toolbarItemLeading: some View {
        Button("취소") {
            isShowingSheet = false
        }
    }
    // (오른쪽) 선택한 앨범에 사진 넣기/이동하기 버튼
    var toolbarItemTrailing: some View {
        Button(albumType == .home ? "\(addBtnTitle) 넣기" : "\(addBtnTitle) 이동하기")  {
            DispatchQueue.main.async {
                addAssetIntoAlbum(indexSet: selectedItemsIndex.sorted{ $0 < $1})
            }
            isShowingSheet = false
        }
        .listRowBackground(Color.white)
        .disabled(albumToAddPhotos == nil)
    }
    // 앨범 만들어 넣기 List Line(맨 윗줄)
    var createAlbumLineView: some View {
        Button {
            stateChangeObject.isShowingAlert = true
        } label: {
            HStack {
                Text("앨범 추가하여 넣기")
                imageScaledFit(systemName: "rectangle.stack.fill.badge.plus", width: 20, height: 20)
                Rectangle()
                    .foregroundColor(.white)
            }
            .foregroundColor(.blue)
        }
        .listRowBackground(Color.white)
        .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
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
    var albumsInTopFolderLineView: some View {
        let collections = PHCollection.fetchTopLevelUserCollections(with: nil)
        return ForEach(0..<collections.count, id: \.self) { index in
            if collections[index].isKind(of: PHAssetCollection.self) {
                let subText = collections[index] == currentAlbum ? "[현재 앨범]" : ""
                AlbumLineView(title: collections[index].localizedTitle ?? "", subText: subText)
                    .listRowBackground(Color.white)
                    .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                    .foregroundColor(collections[index] == currentAlbum ? .disabledColor : (albumToAddPhotos == collections[index] ? .selectedColor:.nonSelectedColor))
                    .onTapGesture {
                        toggleAlbumToAddAssets(album: collections[index])
                    }
                    .disabled(collections[index] == currentAlbum)
            }
        }
    }
    // 탑폴더의 폴더 리스트 + 하위 리스트
    func folderCategoryLineView(proxy: ScrollViewProxy) -> some View {
        let collections = PHCollection.fetchTopLevelUserCollections(with: nil)
        return ForEach(0..<collections.count, id: \.self) { index in
            if collections[index].isKind(of: PHCollectionList.self) {
                FolderCategory(albumType: albumType, currentAlbum: currentAlbum.album, folder: collections[index] as? PHCollectionList, albumToAddPhotos: $albumToAddPhotos, addBtnTitle: $addBtnTitle, proxy: proxy)
                    .listRowBackground(Color.white)
                    .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
            }
        }
    }
}
// MARK: - 3. functions
extension MoveAssetCategoryView {
    // 앨범 라인 선택/해제 토글
    func toggleAlbumToAddAssets(album: PHCollection) {
        if albumToAddPhotos == album as? PHAssetCollection {
            albumToAddPhotos = nil
            addBtnTitle = ""
        } else {
            albumToAddPhotos = album as? PHAssetCollection
            addBtnTitle = albumType == .home ?
            "[\(albumToAddPhotos.localizedTitle ?? "")]에" : "[\(albumToAddPhotos.localizedTitle ?? "")](으)로"
        }
    }
    // 앨범 만들기 -> 탑폴더에 앨범 만들어 사진 넣기
    func addAtTopFolderButton() -> some View {
        Button {
            let folder = Folder(isHome: true)
            let albumName = newName == "" ? "새앨범" : newName
            folder.createAlbum(depth: .current, folderToAdd: folder.folder, albumName) { album in
                if let album = album {
                    self.albumToAddPhotos = album
                    // 여기서 addAsset을 부르면 view가 change를 인지하지 못함 -> didset으로 처리
                    self.isSettedNewAlbum = true
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
                self.isShowingSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    stateChangeObject.newName = self.newName
                    stateChangeObject.selectedIndexes = selectedItemsIndex
                    self.isShowingSelectFolderSheet = true
                    self.newName = ""
                }
            }
        } label: {
            Text("폴더를 지정하여 앨범 추가하기")
        }
    }
    
    // 사진 넣기 최종 함수
    // tab1 : 선택한 앨범에 사진 넣기 / tab2 : Asset 다른 앨범으로 옮기기
    func addAssetIntoAlbum(indexSet: [Int]) {
        var assetArray: [PHAsset] = []
        switch currentAlbum.filteringType {
        case .all: assetArray = currentAlbum.photosArray
        case .image: assetArray = currentAlbum.photosArray.filter({$0.mediaType == .image})
        case .video: assetArray = currentAlbum.photosArray.filter({$0.mediaType == .video})
        }
        var assets: [PHAsset] = []
        let indexSet = indexSet.sorted(by: { $0 < $1 })
        for i in indexSet {
            assets.append(assetArray[i])
        }
        
        if albumType != .home {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentAlbum.removeAssetFromAlbum(indexSet: indexSet)
                }
                stateChangeObject.assetRemoving = true
            }
        }
        
        let albumToAdd = Album(album: albumToAddPhotos)
        DispatchQueue.main.async {
            albumToAdd.addAsset(assets: assets)
                if stateChangeObject.assetRemoving == false {
                    stateChangeObject.assetRemoving = true
                }

        }
    }
    
}

// MARK: - 2nd Struct
struct FolderCategory: View {
    var albumType: AlbumType = .album
    var currentAlbum: PHAssetCollection!
    var folder: PHCollectionList!
    @State var isOpen: Bool = false
    @Binding var albumToAddPhotos: PHAssetCollection!
    @Binding var addBtnTitle: String
    var proxy: ScrollViewProxy
    
    var depthCountCircle: Int = 1
    
    var body: some View {
        if PHCollection.fetchCollections(in: folder, options: nil).count != 0 {
            let collections = PHCollection.fetchCollections(in: folder, options: nil)
            HStack {
                DepthCircle(count: depthCountCircle - 1)
                FolderLineView(title: folder.localizedTitle ?? "", subText: "", isOpen: isOpen)
                    .foregroundColor(collections.count == 0 ? .disabledColor : .nonSelectedColor)
                    .id(folder.localIdentifier)
                    .onTapGesture {
                        withAnimation { isOpen.toggle() }
                    }
            }
            
            if isOpen {
                ForEach(0..<collections.count, id: \.self) { index in
                    if collections[index].isKind(of: PHAssetCollection.self) {
                        let album = collections[index]
                        let subText = album == currentAlbum ? "[현재 앨범]" : ""
                        HStack {
                            DepthCircle(count: depthCountCircle)
                            AlbumLineView(title: album.localizedTitle ?? "", subText: subText)
                                .listRowBackground(Color.white)
                                .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                                .foregroundColor(album == currentAlbum ? .disabledColor : (albumToAddPhotos == collections[index] ? .selectedColor:.nonSelectedColor))
                                .id(album.localIdentifier)
                                .onTapGesture {
                                    if albumToAddPhotos == album as? PHAssetCollection {
                                        albumToAddPhotos = nil
                                        addBtnTitle = ""
                                    } else {
                                        albumToAddPhotos = album as? PHAssetCollection
                                        addBtnTitle = albumType == .home ?
                                        "[\(albumToAddPhotos.localizedTitle ?? "")]에" : "[\(albumToAddPhotos.localizedTitle ?? "")](으)로"
                                    }
                                }
                                .disabled(collections[index] == currentAlbum)
                        }
                    }
                }
                ForEach(0..<collections.count, id: \.self) { index in
                    if collections[index].isKind(of: PHCollectionList.self) {
                        FolderCategory(albumType: albumType, folder: collections[index] as? PHCollectionList, albumToAddPhotos: $albumToAddPhotos, addBtnTitle: $addBtnTitle, proxy: proxy, depthCountCircle: depthCountCircle + 1)
                    }
                }
                .onChange(of: isOpen) { newValue in
                    if newValue {
                        DispatchQueue.main.async {
                            proxy.scrollTo(collections[collections.count - 1].localIdentifier, anchor: .bottom)
                        }
                    }
                }
            }
        } else {
            HStack {
                DepthCircle(count: depthCountCircle - 1)
                FolderLineView(title: folder.localizedTitle ?? "", subText: "")
                    .foregroundColor(.disabledColor)
                    .disabled(albumType == .home)
                    .id(folder.localIdentifier)
            }
        }
    }
}

struct CategoryScene_Previews: PreviewProvider {
    static var previews: some View {
        MoveAssetCategoryView(isShowingSheet: .constant(false),
                              isShowingSelectFolderSheet: .constant(false),
                              stateChangeObject: StateChangeObject(),
                              selectedItemsIndex: .constant([]),
                              isSelectMode: .constant(false))
    }
}

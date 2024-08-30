//
//  PhotoView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
//import PhotosUI // photospicker
import LocalAuthentication

struct AllPhotosView: View {
    @EnvironmentObject var photoData: PhotoData
    @StateObject var stateChangeObject = StateChangeObject()
    @Environment(\.presentationMode) var isPresented: Binding<PresentationMode>
    @Environment(\.scenePhase) var scenePhase
    
    // 앨범 타입이 album일 경우에만 "피커버튼" 노출 결정
    var albumType: AlbumType = .album
    // 보여줄 사진 - 앨범 프라퍼티 : [나의 앨범]탭에서는 상위에서 부여 / [나의 사진], [사진 관리]탭에서는 본 페이지 진입하여 로딩
    @State var album: Album!
    // [나의 사진]탭용 album 세팅용 프라퍼티
    @State var settingDone: Bool! = true
    // 필터링 1 : ([나의 사진]탭에서만) 전체 / In앨범 / NotIn앨범 필터링
    @State var belongingType: BelongingType = .nonAlbum
    // 필터링 2 : (전체탭) 미디어 타입 필터링
    @State var filteringType: FilteringType = .all
    @State var filteringTypeChanged: Bool = false
    // [smartAlbum]탭용 프라퍼티
    @State var isPrivacy: Bool! = false
    var smartAlbum: SmartAlbum = .none
    
    // 네비게이션 타이틀 (앨범을 여기 넘어와서 로딩할 수 있으므로 album.title을 쓸 수 없음)
    @State var title = ""
    @Binding var isPhotosView: Int
    
    var nameSpace: Namespace.ID
    // ui에 영향 있는 프라퍼티 -> 바인딩 처리
    @State var edgeToScroll: EdgeToScroll = .none
    @State var isShowingAlert: Bool = false
    @State var isShowingSheet: Bool = false
    @State var isShowingSelectFolderSheet: Bool = false
    @State var isShowingPhotosPicker: Bool = false
    @State var isShowingShareSheet: Bool = false
    @State var newName: String = ""
    // detail 모드용 프라퍼티
    @State var indexToView: Int = 0
    @State var isExpanded: Bool = false
    // asset 선택모드용 프라퍼티
    @State var isSelectMode: Bool = false
    @State var selectedItemsIndex: [Int] = []
    @State var isSelectingBySwipe: Bool = false
    
    @State var requsetDone: Bool! = false
    // 노크 기능 프라퍼티
    @State var showHiddenAssets: Bool = false
    var isHiddenAssets: Bool = false
    
    var body: some View {
        ZStack(alignment: device == .phone ? .bottom : .bottomTrailing) {
            if isPrivacy {
                // [스마트 앨범]탭용 템프뷰
                notValidatedView
                    .onAppear {
                        DispatchQueue.main
                            .asyncAfter(deadline: .now() + 0.3) {
                            authenticate()
                        }
                    }
            } else if settingDone == false {
                // [나의 사진]탭용 템프뷰
                RefreshPhotoView()
                    .task {
                        if scenePhase != .background {
                            DispatchQueue.main.async {
                                readyToShowMyPhotos(type: belongingType)
                            }
                        }
                    }
            } else {
                let assetCount = (album?.count ?? 0) == 0
                if (albumType == .home || albumType == .picker) && assetCount {
                    AllPhotosAreInAlbumsView()
                } else {
                    GeometryReader { geoProxy in
                        PhotosCollectionView(
                            stateChangeObject: stateChangeObject,
                            albumType: albumType,
                            album: album,
                            hiddenAssets: isHiddenAssets,
                            edgeToScroll: $edgeToScroll,
                            filteringTypeChanged: $filteringTypeChanged,
                            isSelectMode: $isSelectMode,
                            selectedItemsIndex: $selectedItemsIndex,
                            isShowingPhotosPicker: $isShowingPhotosPicker,
                            indexToView: $indexToView,
                            isExpanded: $isExpanded,
                            insertedIndex: album.insertedIndexPath,
                            removedIndex: album.removedIndexPath,
                            changedIndex: album.changedIndexPath,
                            currentCount: isHiddenAssets
                                            ? album.hiddenAssetsArray.count
                                            : album.count,
                            isSelectingBySwipe: $isSelectingBySwipe,
                            animationID: nameSpace,
                            geoProxy: geoProxy)
                        
                    }
                    .navigationDestination(isPresented: $showHiddenAssets) {
                        AllPhotosView(album: album,
                                      isPhotosView: $isPhotosView,
                                      nameSpace: nameSpace,
                                      isHiddenAssets: true)
                            .overlay(content: {
                                if album.hiddenAssetsArray.count == 0 {
                                    Text("이 앨범에는 가린 항목이 없습니다.")
                                        .foregroundStyle(Color.white.opacity(0.5))
                                        .padding(.bottom, tabbarHeight + tabbarBottomPadding)
                                }
                            })
                            .onDisappear {
                                album.hiddenAssetsArray = []
                            }
                    }
                }
                if album != nil {
                    GeometryReader { geoProxy in
                        let width = geoProxy.size.width
                        let spacerWidth = device == .phone ? 0
                                    : ((width / 4) + (5 * tabbarTopPadding))
                        HStack {
                            if device != .phone {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(width: spacerWidth)
                            }
                            PhotosGridMenu(stateChangeObject: stateChangeObject,
                                           albumType: albumType,
                                           album: album,
                                           smartAlbumType: smartAlbum,
                                           isHiddenAssets: isHiddenAssets,
                                           settingDone: $settingDone,
                                           belongingType: $belongingType,
                                           filteringType: $filteringType,
                                           filteringTypeChanged: $filteringTypeChanged,
                                           isSelectMode: $isSelectMode,
                                           selectedItemsIndex: $selectedItemsIndex,
                                           edgeToScroll: $edgeToScroll,
                                           isShowingSheet: $isShowingSheet,
                                           isShowingShareSheet: $isShowingShareSheet,
                                           isShowingPhotosPicker: $isShowingPhotosPicker,
                                           nameSpace: nameSpace,
                                           width: width - spacerWidth)
                        }
                        .frame(width: geoProxy.size.width)
                        .opacity(photoData.isShowingDigitalShow ? 0 : 1)
                        .onAppear {
                            if device != .phone {
                                withAnimation {
                                    isPhotosView += 1
                                }
                            }
                        }
                        .onDisappear {
                            if device != .phone {
                                withAnimation {
                                    isPhotosView -= 1
                                }
                            }
                        }
                    }
                    .padding(.horizontal,
                             device == .phone ? tabbarTopPadding : 0)
                    .padding(.trailing, device == .phone ? 0 : tabbarBottomPadding)
                    .frame(height: tabbarHeight)
                    .opacity(stateChangeObject.isShowingAlert || isShowingPhotosPicker ? 0 : 1)
                    .padding(.bottom, device == .phone ?
                             tabbarHeight
                             + tabbarTopPadding
                             + tabbarBottomPadding : tabbarBottomPadding)
                }
            }
        }
        .overlay(content: {
            if photoData.isShowingDigitalShow {
                RoundedRectangle(cornerRadius: 20.0)
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .matchedGeometryEffect(id: "digitalShow", in: nameSpace)
            }
        })
        .ignoresSafeArea()
        .onAppear(perform: {
            newName = album != nil ? album.title : ""
        })
        .onDisappear {
            if albumType != .home {
                discardImageCaching()
                self.filteringType = .all
                if let album = album {
                    album.filteringType = .all
                }
            }
        }
        .onChange(of: scenePhase, perform: { value in
            if isHiddenAssets || albumType == .smartAlbum {
                if value == .background {
                    isPrivacy = true
                }
            }
        })
        .onChange(of: self.belongingType, perform: { value in
            self.settingDone = false
            readyToShowMyPhotos(type: value)
        })
        .onChange(of: isExpanded, perform: { bool in
            if !bool {
                stateChangeObject.isSlideShowEnded = true
            }
        })
        .onChange(of: !isHiddenAssets 
                      ? album?.count ?? 0
                      : album.hiddenAssetsArray.count,
                  perform: { newValue in
            DispatchQueue.main.async {
                if let album = album {
                    withAnimation {
                        if albumType == .home {
                            if settingDone  {
                                stateChangeObject.assetChanged = .completed
                            } else if album.count < newValue! {
                                stateChangeObject.assetChanged = .done
                            }
                        } else if albumType == .smartAlbum {
                            if isPrivacy {
                                stateChangeObject.assetChanged = .completed
                            }
                        } else if albumType == .album {
                            stateChangeObject.assetChanged = .completed
                        } else {
                            stateChangeObject.assetChanged = .done
                        }
                    }
                }
            }
        })
        .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged({ value in
                if isSelectMode {
                    self.isSelectingBySwipe = true
                }
            })
            .onEnded({ value in
                if value.translation.width > 50 && !self.isSelectMode{
                    isPresented.wrappedValue.dismiss()
                }
                if self.isSelectingBySwipe {
                    self.isSelectingBySwipe = false
                }
            }))
        .fullScreenCover(isPresented: $isExpanded, content: {
            if !isHiddenAssets {
                let assetArray = self.filteringType == .all ?
                album.photosArray : (self.filteringType == .image ?
                                     album.photosArray.filter({$0.mediaType == .image}) : album.photosArray.filter({$0.mediaType == .video}))
                    PhotosDetailView(assetArray: assetArray, 
                                     indexToView: $indexToView,
                                     isExpanded: $isExpanded, 
                                     navigationTitle: "")
            } else {
                let assetArray = self.filteringType == .all ?
                album.hiddenAssetsArray : (self.filteringType == .image ?
                                     album.hiddenAssetsArray.filter({$0.mediaType == .image}) : album.hiddenAssetsArray.filter({$0.mediaType == .video}))
                    PhotosDetailView(assetArray: assetArray, 
                                     indexToView: $indexToView,
                                     isExpanded: $isExpanded,
                                     navigationTitle: "")
            }
        })
        .sheet(isPresented: $isShowingSheet) {
            if albumType == .home || albumType == .album {
                NavigationView {
                    if album != nil {
                        MoveAssetCategoryView(isShowingSheet: $isShowingSheet,
                                              isShowingSelectFolderSheet: $isShowingSelectFolderSheet,
                                              stateChangeObject: stateChangeObject,
                                              albumType: albumType,
                                              currentAlbum: album,
                                              isHiddenAssets: isHiddenAssets,
                                              selectedItemsIndex: $selectedItemsIndex,
                                              isSelectMode: $isSelectMode)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingSelectFolderSheet) {
            if albumType == .home || albumType == .album {
                MoveCollectionCategoryView(isHome: true,
                                           isShowingSheet: $isShowingSelectFolderSheet,
                                           currentFolder: .constant(nil),
                                           currentAlbum: album,
                                           stateChangeObject: stateChangeObject)
            }
        }
        .sheet(isPresented: $isShowingPhotosPicker) {
            if albumType == .album {
                CustomPhotosPicker(isShowingPhotosPicker: $isShowingPhotosPicker,
                                   stateChangeObject: stateChangeObject,
                                   albumToEdit: album)
            }
        }
        .overlay(content: {
            if stateChangeObject.assetChanged != .done {
                CustomProgressView(stateChangeObject: stateChangeObject)
            }
        })
        .navigationBarHidden(albumType == .home)
        .navigationTitle("\(isHiddenAssets ? "🫣" : "")\(album?.title ?? "")\(isHiddenAssets ? "🫣" : "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if albumType == .album{
                if !showHiddenAssets {
                    ToolbarItem(id: "toctoctoc", placement: .topBarTrailing) {
                        Rectangle()
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.fancyBackground)
                            .onTapGesture(count: 3) {
                                if photoData.useKnock {
                                    withAnimation {
                                        authenticate()
                                    }
                                }
                            }
                    }
                } else {
                    ToolbarItem(id: "toctoctoc", placement: .topBarTrailing) {
                        Text("가려진 사진 닫기")
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.fancyBackground)
                            .onTapGesture(count: 1) {
                                withAnimation {
                                    showHiddenAssets = false
                                }
                            }
                    }
                }
            }
        })
        .background { FancyBackground() }
        .edgesIgnoringSafeArea(.trailing)
        .alert(stateChangeObject.editType == .add ? "선택한 \(selectedItemsIndex.count)개의 항목을\n이 앨범에서 빼냅니다." : "",
               isPresented: $stateChangeObject.isShowingAlert, actions: {
            if stateChangeObject.editType == .modify {
                TextField("변경할 앨범 이름을 입력하세요.", text: $newName)
                btnCancel()
                btnModifyTitle()
            } else if stateChangeObject.editType == .add {
                btnCancel()
                btnRomoveAssetFromAlbum()
            }
        }, message: {
            if stateChangeObject.editType == .modify {
                Text("[\(album.title)]의 이름을 변경합니다.")
            } else if stateChangeObject.editType == .add {
                Text("\n항목은 [나의 포토] 탭에서 찾을 수 있습니다.")
            }
        })
    }
}

// MARK: - 1. extenstion. subviews
extension AllPhotosView {
    var notValidatedView: some View {
        Rectangle()
            .foregroundColor(.fancyBackground)
            .overlay {
                VStack(spacing: 20) {
                    Text("이 사진들을 보려면 사용자 권한이 필요합니다.")
                        .foregroundColor(.gray)
                    imageScaledFit(systemName: "faceid", width: 80, height: 80)
                        .foregroundColor(.gray)
                        .padding(50)
                        .onTapGesture {
                            authenticate()
                        }
                    Button("설정하러 가기") {
                        UIApplication.shared.open(URL(string: "app-settings:root=Privacy")!)
                    }
                }
            }
            .ignoresSafeArea()
    }
    
    func btnCancel() -> some View {
        Button {
            resetEditStatus()
            newName = album.title
        } label: {
            Text("취소")
        }
    }
    func btnModifyTitle() -> some View {
        Button {
            album.modifyAlbumTitle(newName: newName)
            self.title = album.title
            resetEditStatus()
        } label: {
            Text("저장하기")
        }
    }
    
    func btnRomoveAssetFromAlbum() -> some View {
        Button("앨범에서 빼기") {
            album.removeAssetFromAlbum(indexSet: selectedItemsIndex,
                                       isHidden: isHiddenAssets)
            resetEditStatus()
            withAnimation {
                stateChangeObject.assetChanged = .changed
            }
        }
    }
}

// MARK: - 2. extenstion. functions
extension AllPhotosView {
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "We need to unlock your data."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: reason) { success, authenticationError in
                if success {
                    if albumType == .album {
                        DispatchQueue.main.async {
                            self.album.fetchOnlyHiddenAssets()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.showHiddenAssets = true
                            }
                        }
                    } else {
                        readyToShowSmartAlbum()
                    }
                }
            }
        } else {
            let reason = "We need to unlock your data."
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                   localizedReason: reason) { success, authenticationError in
                if success {
                    if albumType == .album {
                        album.fetchOnlyHiddenAssets()
                        showHiddenAssets = true
                    } else {
                        readyToShowSmartAlbum()
                    }
                }
            }
        }
    }
    
    func readyToShowSmartAlbum() {
        if albumType == .smartAlbum {
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = true
            fetchOptions.wantsIncrementalChangeDetails = true
            switch smartAlbum {
            case .none: break
            case .trashCan:
                let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: fetchOptions)
                if let trashCan = smartAlbums.objects(at: IndexSet(0..<smartAlbums.count)).filter({$0.localizedTitle == "Recently Deleted"}).first {
                    self.album = Album(album: trashCan, title: "최근 삭제한 사진", colorIndex: 0)
                }
            case .hiddenAsset:
                if let hiddenAlbum = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumAllHidden, options: fetchOptions).firstObject {
                    self.album = Album(album: hiddenAlbum, title: "가린 사진", colorIndex: 0)
                }
            }
        }
        withAnimation {
            isPrivacy = false
        }
    }
    
    func readyToShowMyPhotos(type: BelongingType) {
        if albumType == .home {
            switch type {
            case .nonAlbum:
                self.album = Album(assetArray: photoData.photosArrayNotInAnyAlbum,
                                   title: "앨범 없는 사진함",
                                   belongingType: .nonAlbum,
                                   allPhotos: photoData.allPhotos,
                                   albumsInAllLevels: photoData.albumsInAllLevels,
                                   arrayAllAlbumFetchResutl: photoData.albumFetchResultArray)
            case .album:
                self.album = Album(assetArray: photoData.allPhotosArrayInAllAlbum,
                                   title: "앨범 있는 사진함",
                                   belongingType: .album,
                                   albumsInAllLevels: photoData.albumsInAllLevels,
                                   arrayAllAlbumFetchResutl: photoData.albumFetchResultArray)
            default:
                self.album = Album(assetArray: photoData.allPhotosArray,
                                   title: "모든 사진함",
                                   belongingType: .all,
                                   allPhotos: photoData.allPhotos)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                settingDone = true
            }
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
    }
    
    func discardImageCaching() {
        print("캐싱 지우기")
        DispatchQueue.main.async {
            // 이미지 캐싱 데이터 지우기
            let imageManger = PHCachingImageManager()
            imageManger.stopCachingImagesForAllAssets()
            // 다른 탭으로 이동 시 포토그리드 뷰 벗어나기
//            isPresented.wrappedValue.dismiss()
        }
    }
    
    func changeRefreshViewForReducingMemory(type: AlbumType, 
                                            scenePhase: ScenePhase) {
        if scenePhase == .background {
            if type == .home {
                self.settingDone = false
                self.album = nil
                self.filteringType = .all
            } else if type == .smartAlbum {
                self.isPrivacy = true
                self.album = nil
                self.filteringType = .all
            }
        }
    }
}

struct AllPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        AllPhotosView(stateChangeObject: StateChangeObject(),
                      album: Album(assetArray: [], title: "샘플"),
                      title: "마이 리틀 앨범",
                      isPhotosView: .constant(0),
                      nameSpace: Namespace().wrappedValue)
        .environmentObject(PhotoData())
    }
}

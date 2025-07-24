//
//  PhotoView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
import LocalAuthentication

enum ReLoadingType {
    case none, initiailFetch, reFetchInside, reFetchOutside
    case selectedModeChange, selectAll, deselectAll
    case filterChange, belongingChange, itemChanged
}

struct AllPhotosView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.isPresented) var isPresented
    
    let imageCachingManger = PHCachingImageManager()
    // 앨범 타입이 album일 경우에만 "피커 버튼" 노출 결정
    var albumType: AlbumType = .album
    // 보여줄 사진-앨범 프라퍼티 : [나의 앨범]탭에서는 상위에서 부여
    //                      / [나의 사진], [사진 관리]탭에서는 본 페이지 진입하여 로딩
    let assetCollection: PHAssetCollection!
    @State var mlAlbum: MLAlbum!
    var smartAlbumType: SmartType = .none
    // [나의 사진]탭용 album 세팅용 프라퍼티
    var isHiddenAsset: Bool
    @State var settingDone: Bool! = true
    // 필터링 1 : ([나의 사진]탭에서만) 전체 / In앨범 / NotIn앨범 필터링
    @State var belongingType: BelongingType = .nonAlbum
    // 필터링 2 : (전체탭) 미디어 타입 필터링
    @State var filteringType: FilteringType = .all
    // ipad에서 탭바 위치 잡기 위한 뷰 카운팅
    @Binding var isPhotosView: Int
    var nameSpace: Namespace.ID
    // ui에 영향 있는 프라퍼티 -> 바인딩 처리
    @State var edgeToScroll: EdgeToScroll = .none
    @State var isShowingShareSheet: Bool = false
    @State var newName: String = ""
    // detail 모드용 프라퍼티
    @State var indexToView: Int = 0
    @State var isExpanded: Bool = false
    // asset 선택모드용 프라퍼티
    @State var isSelectMode: Bool = false
    @State var selectedItems: [MLAsset] = []
    @State var refreshItmes: [MLAsset] = []
    @State var isSelectingBySwipe: Bool = false
    // 노크 기능 프라퍼티
    @State var isReadyHiddenAsset: Bool = false
    @State var showHiddenAssets: Bool = false
    @State var showEmptyHiddenAsset: Bool = false
    // 화면 가리기
    @State var showAuthenticView: Bool = false
    // 셀 리로드
    @State var reLoadingType: ReLoadingType = .none
    @State var showDetailView: Bool = false
    
    var body: some View {
        let assetArray = assetArray(albumType: albumType,
                                    belongingType: belongingType)
        ZStack {
            FancyBackground().ignoresSafeArea()
            GeometryReader { geoProxy in
                Group {
                    if mlAlbum == nil {
                        tempView(geoProxy: geoProxy, onAppear: {
                            phDataQueue.asyncAfter(
                                deadline: .now()
                                + ((albumType == .home || albumType == .picker) ? 0.5 : 0)) {
                                readyToShowView(albumType: albumType)
                            }
                        })
                    } else {
                        let columnCount = columnCount(geoProxy: geoProxy)
                        let cellWidth = (geoProxy.size.width - CGFloat(columnCount - 1))
                                        / CGFloat(columnCount)
                        NewPhotosCollectionView(
                            albumType: albumType,
                            mlAlbum: mlAlbum,
                            smartAlbumType: smartAlbumType,
                            isHiddenAssets: isHiddenAsset,
                            assetArray: assetArray,
                            filteringType: $filteringType,
                            geoProxy: geoProxy,
                            cellWidth: cellWidth,
                            imageCachingManager: imageCachingManger,
                            isSelectMode: $isSelectMode,
                            selectedItems: $selectedItems,
                            refreshItems: $refreshItmes,
                            indexToView: $indexToView,
                            isExpanded: $isExpanded,
                            edgeToScroll: $edgeToScroll,
                            reLoadingType: $reLoadingType)
                        .overlay(content: {
                            if isHiddenAsset && assetArray.isEmpty {
                                emptyHiddenInfoView()
                            }
                        })
                        .overlay(alignment: .top, content: {
                            if showEmptyHiddenAsset {
                                emptyCapsuleView(size: geoProxy.size, cellWidth: cellWidth)
                            }
                        })
                        .onAppear(perform: {
                            thumbnailCaching(isStart: true, width: cellWidth)
                        })
//                        .onChange(of: presentationMode.wrappedValue.isPresented) { value in
//                            print("\(mlAlbum.title) [\(isHiddenAsset)] isPresented? : \(value)")
//                            
//                        }
                        .onDisappear(perform: {
                            if albumType == .album || albumType == .smartAlbum {
//                                if !PresentationMode.wrappedValue == .isPresented && !showHiddenAssets {
//                                    DispatchQueue.global(qos: .background).async {
//                                        print("캐싱 딜리트 [\(mlAlbum.title) \(isHiddenAsset ? " Hidden" : "not Hidden")]")
//                                        imageCachingManger.stopCachingImagesForAllAssets()
//                                    }
//
//                                }
                            }
                        })
                    }
                }
                .overlay(alignment: .bottom, content: {
                    photosGridMenu(assetArray: assetArray,
                                   filteringType: filteringType,
                                   width: geoProxy.size.width)
                })
                .padding(.bottom, (device == .pad || albumType == .picker)
                         ? 5 : tabbarHeight - (safeAraBottom ?? 0))
                .onChange(of: geoProxy.size.width) { _  in
                    if device == .pad {
                        DispatchQueue.main.async {
                            reLoadingType = .reFetchOutside
                        }
                    }
                }
    //            }
                // 가려진 사진 - 인증 화면
    //            if album.isHidden {
    //                viewWithTask(notValidatedView) {
    //                    DispatchQueue.main
    //                        .asyncAfter(deadline: .now() + 0.7) {
    //                            authenticate(albumType: albumType)
    //                        }
    //                }
    //            }
            }
        }
        .ignoresSafeArea(.keyboard)
//        .edgesIgnoringSafeArea(.horizontal)
        .fullScreenCover(isPresented: $isExpanded, content: {
            let assetArray = assetArray
                .filter {
                    return switch filteringType {
                    case .all: true
                    case .favorite: $0.isFavorite
                    default: FilteringType
                            .trueType(type: self.filteringType) == $0.mediaType
                    }
                }
            PhotosDetailView(albumType: self.albumType,
                             assetCollection: self.assetCollection,
                             isHiddenAssets: self.isHiddenAsset,
                             assetArray: assetArray,
                             indexToView: $indexToView,
                             isExpanded: $isExpanded,
                             animationID: nameSpace,
                             reLoadingType: $reLoadingType,
                             selectedItems: $selectedItems)
        })
        .onDisappear(perform: {
            DispatchQueue.global(qos: .default).async {
                if albumType != .smartAlbum {
                    mlAlbum = nil
                }
            }
        })
        .onReceive(NotificationCenter.default
            .publisher(for: .outsideFetchChange), perform: { object in
                if reLoadingType != .reFetchOutside {
                    guard let mlAlbum = mlAlbum else { return }
                    if mlAlbum.id == object.object as? String {
                        print("\(mlAlbum.title) outter fetch Recieved")
                        DispatchQueue.main.async {
                            reLoadingType = .reFetchOutside
                        }
                    }
                }
            })
        .onReceive(NotificationCenter.default
            .publisher(for: .innerFetchChange), perform: { object in
                if reLoadingType != .reFetchInside {
                    guard let mlAlbum = mlAlbum else { return }
                    if mlAlbum.id == object.object as? String {
                        print("\(mlAlbum.title) innerfetch Recieved")
                        DispatchQueue.main.async {
                            reLoadingType = .reFetchInside
                        }
                    }
                }
        })
        .onReceive(NotificationCenter.default
            .publisher(for: .collectionRemoved), perform: { object in
                guard let assetCollection = object.object as? PHAssetCollection
                else { return }
                if assetCollection.localIdentifier == mlAlbum.id {
                    dispatchAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            })
        .onReceive(NotificationCenter.default
            .publisher(for: .itemChanged), perform: { output in
                guard let object = output.object as? ItemChangedView else { return }
//                if object.id != "elsewhere" {
//                    guard object.id == self.mlAlbum?.id else { return }
//                }
                self.refreshItmes = assetArray.filter({ object.items.contains($0.id) })
                if !refreshItmes.isEmpty {
                    dispatchAnimation {
                        reLoadingType = .itemChanged
                    }
                }
        })
        .onReceive(NotificationCenter.default
            .publisher(for: .itemChanged), perform: { output in
                guard let object = output.object as? ItemChangedView,
                      object.id == self.mlAlbum?.id else { return }
                print("Got notice at \(mlAlbum?.title ?? "home")")
                self.refreshItmes = assetArray.filter({ object.items.contains($0.id) })
                if !refreshItmes.isEmpty {
                    dispatchAnimation {
                        reLoadingType = .itemChanged
                    }
                }
        })
        .navigationDestination(isPresented: $showHiddenAssets) {
            AllPhotosView(albumType: albumType,
                          assetCollection: assetCollection,
                          mlAlbum: mlAlbum,
                          smartAlbumType: smartAlbumType,
                          isHiddenAsset: true,
                          isPhotosView: $isPhotosView,
                          nameSpace: nameSpace)
            .onDisappear {
                mlAlbum.unSetHiddenAssets {
                    print("hiddenAssets Removed")
                }
            }
        }
        .onAppear(perform: {
            guard let mlAlbum = mlAlbum else { return }
            newName = mlAlbum.title
        })
        .onDisappear {
//            DispatchQueue
//                .global(qos: .userInteractive)
//                .async {
//                    discardImageCaching()
//                    if album.isHidden {
//                        album.hiddenArray = []
//                        album.isHidden = false
//                        print("hidden Scene End")
//                    }
//                }
//            if albumType != .home {
//                self.filteringType = .all
//                if let album = album {
//                    album.filteringType = .all
//                }
//            }
        }
        .onChange(of: scenePhase, perform: { value in
//            if album.isHidden {
//                if value == .background {
//                    showAuthenticView = true
//                }
//            }
        })
//        .onChange(of: self.belongingType, perform: { value in
//            withAnimation {
//                self.settingDone = false
//            }
//        })
        .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged({ value in
                if isSelectMode {
                    self.isSelectingBySwipe = true
                }
            })
            .onEnded({ value in
                if value.translation.width > 50 && !self.isSelectMode{
                    presentationMode.wrappedValue.dismiss()
                }
                if self.isSelectingBySwipe {
                    self.isSelectingBySwipe = false
                }
            }))
//            .overlay(content: {
//                if showAuthenticView {
//                    notValidatedView
//                        .task {
//                            DispatchQueue.main
//                                .asyncAfter(deadline: .now() + 0.7) {
////                                    authenticate(albumType: albumType)
//                                    authenticate(albumType: albumType) { bool in
//                                        
//                                    }
//                                }
//                        }
//                }
//            })
//        })
        .navigationBarHidden(albumType == .home)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            if (albumType == .album || albumType == .smartAlbum) && !isHiddenAsset {
                ToolbarItem(id: "knockx3", placement: .topBarTrailing) {
                    knockHiddenAsset
                }
            }
            ToolbarItem(placement: .principal) {
                getNavigationTitle(albumType: albumType)
            }
        })
//        .edgesIgnoringSafeArea(.trailing) // 패드
    }
}

// MARK: - 1. extenstion. subviews
extension AllPhotosView {
    func tempView(geoProxy: GeometryProxy, onAppear: @escaping () -> Void) -> some View {
        Group {
            switch albumType {
            case .album: FancyBackground()
            default: // home / Picker에서 사용
                lottieLoadingView(
                    lottie: "photoLoading",
                    size: CGSize(width: geoProxy.size.width / 3,
                                 height: geoProxy.size.height / 1.2),
                    leadingPadding: 0)
                .frame(width: geoProxy.size.width)
            }
        }
        .onAppear { onAppear() }
    }
    func photosGridMenu(assetArray: [MLAsset],
                        filteringType: FilteringType,
                        width: CGFloat) -> some View {
        let spacerWidth = device == .phone
                        ? 0 : ((width / 3) + (5 * tabbarTopPadding))
        return HStack {
            if device == .pad {
                Rectangle()
                    .fill(.clear)
                    .frame(width: spacerWidth)
            }
            if let mlAlbum = mlAlbum {
                PhotosGridMenu(
//                    pickerObject: .constant(nil),
                    albumType: albumType,
                    smartAlbumType: smartAlbumType,
                    mlAlbum: mlAlbum,
                    isHiddenAssets: isHiddenAsset,
                    cachingimageManager: imageCachingManger,
                    assetArray: assetArray,
                    belongingType: $belongingType,
                    filteringType: $filteringType,
                    isSelectMode: $isSelectMode,
                    selectedItems: $selectedItems,
                    refreshItems: $refreshItmes,
                    edgeToScroll: $edgeToScroll,
                    isShowingShareSheet: $isShowingShareSheet,
                    isShowingPhotosPicker: .constant(false),
                    nameSpace: nameSpace,
                    width: width - spacerWidth,
                    reloadingType: $reLoadingType,
                    isReadyHiddenAsset: isReadyHiddenAsset)
//            .frame(width: width)
//            .opacity(photoData.isShowingDigitalShow ? 0 : 1)
                .onAppear {
                    withAnimation {
                        isPhotosView += device != .phone ? 1 : 0
                    }
                }
                .onDisappear {
                    withAnimation {
                        isPhotosView -= device != .phone ? 1 : 0
                    }
                }
            } else {
                EmptyView()
            }
        }
        .frame(height: tabbarHeight)
        .padding(.horizontal,
                 device == .phone ? tabbarTopPadding : 0)
        .padding(.trailing, tabbarBottomPadding)
        .padding(.bottom, device == .phone ? tabbarTopPadding : 0)
    }
    
    var notValidatedView: some View {
        Rectangle()
            .foregroundColor(.fancyBackground)
            .overlay {
                VStack(spacing: 20) {
                    Text("이 사진들을 보려면 사용자 권한이 필요합니다.")
                        .foregroundColor(.gray)
                    btnFaceID
                        .onTapGesture {
                            authenticate(albumType: albumType) { bool in
                                if bool {
                                    returnHiddenAssets(albumType: albumType)
                                }
                            }
                        }
                    Button("FaceID 사용 설정하러 가기") {
                        UIApplication.shared
                            .open(URL(string: "app-settings:root=Privacy")!)
                    }
                }
            }
            .ignoresSafeArea()
    }
    
    var btnFaceID: some View {
        imageScaledFit(systemName: "faceid", width: 80, height: 80)
            .padding(40)
            .overlay(alignment: .topTrailing) {
                Text("Touch")
                    .font(.system(size: 10, weight: .regular))
                    .padding(8)
                    .background {
                        Image(systemName: "bubble.left")
                            .resizable()
                            .fontWeight(.ultraLight)
                            .offset(x: 0, y: 3)
                    }
                    .offset(x: 0, y: 0)
                    .opacity(0.7)
            }
            .foregroundColor(.gray)
    }
    
    var knockHiddenAsset: some View {
        Rectangle()
            .frame(width: 50, height: 40)
            .foregroundStyle(Color.fancyBackground)
            .onTapGesture(count: 3) {
                if photoData.useKnock {
                    authenticate(albumType: albumType) { bool in
                        if bool {
                            returnHiddenAssets(albumType: albumType)
                        }
                    }
                }
            }
    }
}

// MARK: - 2. extenstion. functions
extension AllPhotosView {
    func columnCount(geoProxy: GeometryProxy) -> Int {
        device == .phone
            ? cellCount(type: .small)
            : (albumType == .picker
                ? cellCount(type: .middel2)
                : (geoProxy.size.width > geoProxy.size.height
                   ? cellCount(type: .big)
                   : cellCount(type: .middle1)
                  )
            )
    }
//    func authenticate(albumType: AlbumType) {
//        let context = LAContext()
//        var error: NSError?
//        if context
//            .canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
//                               error: &error) {
//            let reason = "We need to unlock your data."
//            context
//                .evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
//                                localizedReason: reason) { success, authenticationError in
//                if success {
//                    album.setHiddenAsset { int in
//                        returnHiddenAssets(albumType: albumType)
//                    }
////                    returnHiddenAssets(albumType: albumType)
////                    DispatchQueue.main.async {
////                        album.isHidden = true
////                    }
//                }
//            }
//        } else {
//            let reason = "We need to unlock your data."
//            context.evaluatePolicy(.deviceOwnerAuthentication,
//                                   localizedReason: reason) { success, authenticationError in
//                if success {
//                    returnHiddenAssets(albumType: albumType)
//                }
//            }
//        }
//    }
    
    func returnHiddenAssets(albumType: AlbumType) {
        guard let mlAlbum = mlAlbum else { return }
        mlAlbum.setHiddenAsset { count in
            if count == 0 {
                withAnimation(Animation.easeInOut(duration: 0.5), {
                    self.showEmptyHiddenAsset = true
                })
            } else {
                withAnimation {
                    isReadyHiddenAsset = true
                }
//                dispatchAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    mlAlbum.generateArray(isHiddenAsset: true) {
                        dispatchAnimation {
                            self.showHiddenAssets = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                self.isReadyHiddenAsset = false
                            }
                        }
                    }
//                    }
                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    
//                }
            }
        }
    }
    
    func getNavigationTitle(albumType: AlbumType) -> some View {
        let title = switch albumType {
        case .home, .picker: "나의 사진"
        case .smartAlbum, .album:
            mlAlbum != nil ? "\(self.isHiddenAsset ? "🫣" : "")\(mlAlbum.title)" : " "
        }
        return Text(title == "" ? "(No Title)" : title )
            .contentTransition(.numericText())
            .foregroundStyle(title == "" ? .gray : .white)
    }
    
//    func readyToShowSmartAlbum(smart: SmartAlbum, result: @escaping (MLAlbum) -> Void) {
//        var album: MLAlbum!
//        switch smart.type {
//        case .smartAlbumFavorites:
//            album = MLAlbum(smartType: smart.type,
//                             title: smart.title,
//                             isHidden: smart.isPrivacy)
//        case .trashCan:
//            let fetchOptions = PHFetchOptions()
//            fetchOptions.includeHiddenAssets = true
//            fetchOptions.wantsIncrementalChangeDetails = true
//            let smartAlbums = PHAssetCollection
//                .fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: fetchOptions)
//            let titles = smartAlbums.objects(at: IndexSet(0..<smartAlbums.count))
//                .compactMap { $0.localizedTitle }
//            if let trashCan = smartAlbums
//                .objects(at: IndexSet(0..<smartAlbums.count))
//                .filter({$0.localizedTitle == "Recently Deleted"})
//                .first {
//                    album = Album(album: trashCan,
//                                      title: "최근 삭제한 사진",
//                                      colorIndex: 0,
//                                      isHidden: true)
//            }
//        case .smartAlbumAllHidden:
//            album = MLAlbum(smartType: smart.type,
//                             title: smart.title,
//                             isHidden: smart.isPrivacy)
//        default: break
//        }
//        result(album)
//    }
    
    func thumbnailCaching(isStart: Bool, width: CGFloat) {
        guard let mlAlbum = mlAlbum else { return }
        print("캐싱 \(isStart ? "시작" : "지우기") [\(mlAlbum.title) \(isHiddenAsset ? "HiddenAsset" : "not HiddenAsset")]")
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .fastFormat
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        phImageQueue.async {
            let objects = (!isHiddenAsset ? mlAlbum.photosArray : mlAlbum.hiddenArray)
                .compactMap { $0.phAsset }
                    if isStart {
                        imageCachingManger
                            .startCachingImages(
                                for: objects,
                                targetSize: CGSize(width: width, height: width),
                                contentMode: .aspectFill,
                                options: requestOptions)
                    } else {
                        DispatchQueue.global(qos: .background).async {
                            imageCachingManger
                                .stopCachingImages(
                                    for: objects,
                                    targetSize: CGSize(width: width, height: width),
                                    contentMode: .aspectFill,
                                    options: requestOptions)
                        }
                    }
        }
    }
    func emptyHiddenInfoView() -> some View {
        VStack(spacing: 20) {
            Text("이 \(albumType == .smartAlbum ? "기기" : "앨범")에는 가린 항목이 없습니다.")
            .foregroundStyle(.gray)
            if albumType == .smartAlbum {
                Button {
                    dispatchAnimation {
                        NotificationCenter.default
                            .post(name: .showInfoView,
                                  object: Info.hiddenAssets)
                    }
                } label: {
                    Rectangle()
                        .foregroundStyle(Color.fancyBackground)
                        .frame(width: 70, height: 70)
                        .overlay {
                            imageScaledFit(
                                systemName: "info.circle.fill",
                                width: 40,
                                height: 40)
                                .foregroundStyle(.blue)
                                .fontWeight(.thin)
                        }
                }
            }
        }
        .offset(y: -tabbarHeight / 2 + tabbarTopPadding)
    }
    
    func viewWithTask(_ view: some View,
                      condition: Bool! = true,
                      task: @escaping () -> Void) -> some View {
        return view
            .task { if condition { task() } }
    }
    
    func emptyCapsuleView(size: CGSize, cellWidth: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(.thinMaterial)
            HStack {
                Text("\(albumType == .album ? "이 앨범에는 " : "")가린 항목이 없습니다.")
                Button {
                    dispatchAnimation {
                        NotificationCenter.default
                            .post(name: .showInfoView,
                                  object: Info.hiddenAssets)
                    }
                } label: {
                    ZStack {
                        imageScaledFit(
                            systemName: "info.circle.fill",
                            width: 20,
                            height: 20)
                    }
                    .frame(width: 20, height: 20)
                }
            }
        }
        .frame(height: navigationbarHeight + 10)
        .frame(maxWidth: device == .phone ? .infinity : widthLimit)
        .padding(.horizontal, 10)
        .offset(y: ((cellWidth - navigationbarHeight) / 2) - 5)
        .transition(.move(edge: .top))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showEmptyHiddenAsset = false
                }
            }
        }
    }
    
    func readyToShowView(albumType: AlbumType = .album) {
        switch albumType {
        case .home, .picker:
            if let allPhotos = photoData.homeAlbum {
                print("ok i find the home")
                if allPhotos.fetchResult.count != allPhotos.photosArray.count {
                    allPhotos.generateArray(isHiddenAsset: false) {
                        dispatchAnimation {
                            self.mlAlbum = allPhotos
                        }
                    }
                } else {
                    dispatchAnimation {
                        self.mlAlbum = allPhotos
                    }
                }
            } else {
                print("no there is no home. i'll set. wait")
                let allPhotos = MLAlbum(isHome: true)
                allPhotos.generateArray(isHiddenAsset: false) {
                    dispatchAnimation {
                        photoData.homeAlbum = allPhotos
                        self.mlAlbum = allPhotos
                    }
                }
            }
        case .album:
            guard let album = photoData.albums[assetCollection?.localIdentifier ?? ""]
            else { return }
            if album.fetchResult.count != album.photosArray.count {
                album.generateArray(isHiddenAsset: false) {
                    dispatchAnimation {
                        self.mlAlbum = album
                    }
                }
            } else {
                dispatchAnimation {
                    self.mlAlbum = album
                }
            }
        default: break
        }
    }
    
    func assetArray(albumType: AlbumType,
                   belongingType: BelongingType) -> [MLAsset] {
       let assetArray = switch albumType {
       case .album, .smartAlbum:
           !isHiddenAsset ? mlAlbum?.photosArray : mlAlbum?.hiddenArray
       case .home, .picker:
           switch belongingType {
           case .all:
               mlAlbum?.photosArray
           case .nonAlbum:
               mlAlbum?.subtractingArray(
                        isHiddenAsset: false,
                        subtracting: Array(photoData.albumsPhotosSet()))
                    .sorted(by: { $0.creationDate < $1.creationDate })
           case .album:
               mlAlbum?.intersectingArray(
                        isHiddenAsset: false,
                        intersecting: Array(photoData.albumsPhotosSet()))
                    .sorted(by: { $0.creationDate < $1.creationDate })
           }
       }
       return assetArray ?? []
   }
}

struct AllPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        AllPhotosView(assetCollection: .init(),
                      mlAlbum: MLAlbum(sampleID: 0, sampleCase: .none),
                      isHiddenAsset: false,
                      isPhotosView: .constant(0),
                      nameSpace: Namespace().wrappedValue)
        .environmentObject(MLPhotoData())
    }
}

extension View {
    func heroFullScreenCover<Content: View>(
        showDetailView: Binding<Bool>,
        content: @escaping () -> Content) -> some View {
            self
                .modifier(HelperHeroView(show: showDetailView, overlay: content()))
    }
    
    @ViewBuilder
    func sheroFullScreenCover<Content: View>(
        showDetailview: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content) -> some View {
            self
                .modifier(HelperHeroView(show: showDetailview, overlay: content()))
    }
}

fileprivate struct  HelperHeroView<Overlay: View>: ViewModifier {
    @Binding var show: Bool
    var overlay: Overlay
    
    @State private var hostView: UIHostingController<Overlay>?
    @State private var parentController: UIViewController?
    
    func body(content: Content) -> some View {
        content
            .background(content: {
                ExtractSwiftUIParentController(content: overlay,
                                               hostView: $hostView) { viewController in
                    parentController = viewController
                }
            })
            .onAppear {
                hostView = UIHostingController(rootView: overlay)
            }
            .onChange(of: show) { newValue in
                if newValue {
                    if let hostView {
                        hostView.modalPresentationStyle = .overFullScreen
                        hostView.modalTransitionStyle = .crossDissolve
                        hostView.view.backgroundColor = .clear
                        
                        parentController?.present(hostView, animated: false)
                    }
                } else {
                    hostView?.dismiss(animated: false)
                }
            }
    }
}


fileprivate struct ExtractSwiftUIParentController<Content: View>: UIViewRepresentable {
    
    var content: Content
    @Binding var hostView: UIHostingController<Content>?
    var parentController: (UIViewController?) -> ()
    
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        hostView?.rootView = content
        DispatchQueue.main.async {
            parentController(uiView.superview?.superview?.parentController)
        }
    }
}

public extension UIView {
    var parentController: UIViewController? {
        var responder = self.next
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}

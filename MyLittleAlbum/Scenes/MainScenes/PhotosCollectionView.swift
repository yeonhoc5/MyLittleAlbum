//
//  PhotosCollectionView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/03.
//

import SwiftUI
import Photos
import UIKit

struct PhotosCollectionView: UIViewRepresentable {
    var albumType: AlbumType = .album
    @ObservedObject var album: MLAlbum
    var isHiddenAssets: Bool = false
    
    let imageCachingManager: PHCachingImageManager
    
    // 스크롤 관리 프라퍼티
    @State var scrollAtFirst: Bool = true
    @Binding var edgeToScroll: EdgeToScroll
    var filteringType: FilteringType = .all
    var belongingType: BelongingType = .nonAlbum
//    @Binding var filteringTypeChanged: Bool
    // 셀 셀렉트 모드 전환 프라퍼티
    @Binding var isSelectMode: Bool
    @Binding var selectedItemsIndex: [Int]
    @Binding var isShowingPhotosPicker: Bool
    
    @Binding var indexToView: Int
    @Binding var isExpanded: Bool
//    @State var selectedIndex: IndexPath!
    
    @State var multiSelectIndex: [Int] = []
    @State var insertedIndex: [IndexPath]
    @State var removedIndex: [IndexPath]
    @State var changedIndex: [IndexPath]
    @State var currentCount: Int
    @Binding var isSelectingBySwipe: Bool
    
    var animationID: Namespace.ID!
    var geoProxy: GeometryProxy
    @State var beforGeo = CGSize()
    
    @State var collectionView: UICollectionView!
    
    @State var lastSelectedCell = IndexPath()
    @State var currentLongPressedCell: GridCell?
    
    func makeUIView(context: Context) -> UICollectionView {
        // setting layout (cell size)
        let cellCount = device == .phone 
            ? cellCount(type: .small)
            : (albumType == .picker
                ? cellCount(type: .middel2) 
                : (geoProxy.size.width > geoProxy.size.height 
                   ? cellCount(type: .big)
                   : cellCount(type: .middle1)
                  )
            )
        let cellWidth = (geoProxy.size.width - CGFloat(1 * (cellCount-1)))
                        / CGFloat(cellCount)

        DispatchQueue.main.async {
            self.beforGeo = geoProxy.size
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        // 배경은 상위뷰를 따름 (clear 지정 안하면 블랙 화면)
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "VideoCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "PickerCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "SpaceCell")
        
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        
        collectionView.isScrollEnabled = true
        
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.didPan(toSelectCells:))
        )
        panGesture.delegate = context.coordinator as any UIGestureRecognizerDelegate
        panGesture.minimumNumberOfTouches = 1
        collectionView.addGestureRecognizer(panGesture)
        
//        let longPressedGesture = UILongPressGestureRecognizer(
//            target: context.coordinator,
//            action: #selector(Coordinator.handleLongPress(gestureRecognizer:))
//        )
//        longPressedGesture.minimumPressDuration = 0.6
//        longPressedGesture.delegate = context.coordinator as any UIGestureRecognizerDelegate
//        longPressedGesture.delaysTouchesBegan = true
//        collectionView.addGestureRecognizer(longPressedGesture)
        
        DispatchQueue.main.async {
            self.collectionView = collectionView
        }
        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        // 아이패드에서 뷰 너비 전환
        if device != .phone {
            if geoProxy.size != beforGeo {
                let cellCount = albumType == .picker
                                ? cellCount(type: .middel2)
                                : (geoProxy.size.width > geoProxy.size.height
                                   ? cellCount(type: .big)
                                   : cellCount(type: .middle1)
                                  )
                let cellWidth = (geoProxy.size.width - CGFloat(1 * (cellCount-1)))
                                / CGFloat(cellCount)
                let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
                layout?.itemSize = CGSize(width: cellWidth, height: cellWidth)
                withAnimation {
                    collectionView.collectionViewLayout.invalidateLayout()
                    collectionView.reloadData()
                }
                DispatchQueue.main.async {
                    beforGeo = geoProxy.size
                }
            }
        }
        // 1. 첫 진입시 : [나의 앨범]에서는 맨 위 / 그 외(나의사진/피커뷰/스마트앨범)에서는 첫 진입 시 맨 아래로 스크롤
//        if albumType != .album && scrollAtFirst {
//            scrollToBottomAtFirst(collectionView: collectionView)
//            print("updated 1. scrolled to bottom First")
//        }
        // 2. (공통) 스크롤 위/아래 이동
//        if edgeToScroll != .none && currentCount != 0 {
//            moveToEdge(collectionView: collectionView)
//        }
        
        // 3. 필터링 4 : (공통) 비디오 / 이미지 / 모두 보기 필터링
//        if filteringType {
        switch filteringType {
        default: reloadAllPhotos(collectionView: collectionView) { _ in
            }
        }
//        if filteringTypeChanged {
//            reloadAllPhotos(collectionView: collectionView) { count in
//                DispatchQueue.main.async {
//                    withAnimation {
//                        self.filteringTypeChanged = false
//                    }
//                    print("updated 3. photos Are Filtered by you want are changed")
//                }
//            }
//        }
        // 4. 개별 셀 선택시 리로드는 각 셀에서 처리 / 취소 버튼에 의한 선택된 셀들의 리로드와 전체 선택 토글이 이루어지면 여기서 전체 셀 리로드는 여기서 처리
//        if stateChangeObject.selectToggleAllPhotos {
//            DispatchQueue.main.async {
//                withAnimation {
//                    collectionView
//                .reloadItems(at: (0..<currentCount)
//                    .map { IndexPath(row: $0, section: 0)}
//                )
//                }
//            }
//            reloadSelectedPhotos(all: true, collectionView: collectionView)
//            print("updated 4-1. you pressed Cancel SelectMode at Selected All")
//        } else if stateChangeObject.selectToggleSomePhotos {
//            reloadSelectedPhotos(all: false, collectionView: collectionView)
//            print("updated 4-2. you pressed Cancel SelectMode at Selected some")
//        }
        
        // 5. detilaview 완료 후 indextoview 재로딩
//        if stateChangeObject.isSlideShowEnded {
//            if let index = selectedIndex {
//                collectionView.reloadItems(at: [IndexPath(item: indexToView,
//                                                          section: 0),
//                                                index])
//            }
//            DispatchQueue.main.async {
//                stateChangeObject.isSlideShowEnded = false
//                selectedIndex = nil
//            }
//            print("updated 7. Detail View has Ended")
//        }
        
        // 6. 사진 추가/삭제 후 리로딩
        // 6-1. assetArray 카운트 변화 있음 : [마이포토] nonalbum (album,all은 가리기 삭제시에만) / [마이앨범] / [사진관리] 가린 사진
//        if currentCount != (album.isHidden ? album.hiddenArray.count : album.photosArray.count) {
//            DispatchQueue.main.async {
//                withAnimation {
//                    // step 1. 리로드 전 준비
//                    if albumType == .album {
//                        //                        stateChangeObject.showPickerButton = false
//                    }
//                    self.currentCount = album.isHidden
//                    ? album.hiddenArray.count
//                    : album.photosArray.count
//                    
//                    // step 2. 리로드
//                    reloadAllPhotos(collectionView: collectionView) { count in
//                        if currentCount == count {
//                            // step 3. progressView뷰 종료
//                            withAnimation {
//                                NotificationCenter.default.post(
//                                    name: .showProgressDoneView,
//                                    object: nil)
//                                if isSelectMode {
//                                    self.isSelectMode = false
//                                }
//                            }
//                        }
//                    }
//                    selectedItemsIndex = []
//                    //                    album.removedIndexPath = []
//                    //                    album.changedIndexPath = []
//                    //                    album.insertedIndexPath = []
//                }
//            }
//        }
        // 6-2. 카운트 변화 없음: [마이포토] all / album에서 사진 추가
//        } else if stateChangeObject.assetChanged == .changed
//                    && albumType == .home
//                    && self.belongingType != .nonAlbum {
//            // step 1. 부분 리로딩 준비
//            let index = selectedItemsIndex.map({ IndexPath(row: $0, section: 0) })
//            DispatchQueue.main.async {
//                self.isSelectMode = false
//                self.currentCount = album.isHidden
//                                    ? album.hiddenArray.count
//                                    : album.photosArray.count
//            // step 2. 리로드
//                withAnimation {
//                    reloadAllPhotos(collectionView: collectionView,
//                                    all: false,
//                                    index: index) { count in
//                        if currentCount == count {
//            // step 3. progressView뷰 종료
//                            withAnimation {
//                                NotificationCenter.default
//                                    .post(name: .showProgressDoneView, object: nil)
//                                self.isSelectMode = false
//                            }
////                            withAnimation {
////                                stateChangeObject.assetChanged = .completed
////                            }
//                        }
//                    }
//                }
//                selectedItemsIndex = []
//            }
//        }
        
//      7. 선택 모드 토글에 의한 picker 버튼 노출
//        if albumType == .album && stateChangeObject.showPickerButton {
//            loadPickerButtonCell(collectionView: collectionView)
//            DispatchQueue.main.async {
//                stateChangeObject.showPickerButton = false
//            }
//            print("update 5-2. picker button are come home")
//        }
        
        // 8. 포토 피커 취소할 시 피커버튼 다시 작동되도록
//        if stateChangeObject.photosPickerCanceled {
//            DispatchQueue.main.async {
//                collectionView.reloadItems(at: [IndexPath(item: currentCount,
//                                                          section: 0)])
//                stateChangeObject.photosPickerCanceled = false
//            }
//        }

        // 5. 콜렉션뷰 배치 업데이트 - (1) 삭제된 아이템
//        if self.removedIndex.count > 0 {
//            let removedIndexes = album.removedIndexPath
//            collectionView.performBatchUpdates {
//                collectionView.deleteItems(at: removedIndexes)
//                print("deleted Done")
//                DispatchQueue.main.async {
////                    album.removedIndexPath = []
//
//                    let lastCount: Int!
//                    let additional = (self.albumType == .album) ? 11 : 10
//                    switch album.filteringType {
//                    case .all:
//                        lastCount = album.count
//                    case .image:
//                        lastCount = album.countOfImage
//                    case .video:
//                        lastCount = album.countOfVidoe
//                    }
//                    for i in (lastCount + 1)..<(lastCount + additional) {
//                        collectionView.reloadItems(at: [IndexPath(row: i, section: 0)])
//                    }
//
//                }
//            }
//        }
        // 5. 콜렉션뷰 배치 없데이트 - (2) 추가된 아이템
//        if !album.insertedIndexPath.isEmpty {
//            collectionView.performBatchUpdates {
//                collectionView.insertItems(at: album.insertedIndexPath)
//                print("inserted Done")
//                DispatchQueue.main.async {
////                    album.insertedIndexPath = []
//                }
//            }
//        }
        // 5. 콜렉션뷰 배치 없데이트 - (3) 바뀐 아이템
//        if self.changedIndex.count > 0 {
//            let changedIndexes = album.changedIndexPath
//            collectionView.performBatchUpdates {
//                collectionView.reloadItems(at: changedIndexes)
//                print("changed Done")
//                DispatchQueue.main.async {
////                    album.changedIndexPath = []
//
//                }
//            }
//        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // -> (1) scroll at first
//    func scrollToBottomAtFirst(collectionView: UICollectionView) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
//            let contentSize = collectionView.contentSize
//            if contentSize.height > collectionView.bounds.size.height {
//                let targetContentOffset = CGPointMake(0.0, contentSize.height - collectionView.bounds.size.height )
//                collectionView.setContentOffset(targetContentOffset, animated: false)
//            }
//        }
//        DispatchQueue.main.async {
//            self.scrollAtFirst = false
//        }
//    }
    // -> (2) scroll edge
//    func moveToEdge(collectionView: UICollectionView) {
//        let collecitonEdge: UICollectionView.ScrollPosition = edgeToScroll == .top ? .top : .bottom
//        if collecitonEdge == .bottom {
//            let contentSize = collectionView.contentSize
//            if contentSize.height > collectionView.bounds.size.height {
//                let targetContentOffset = CGPointMake(0.0, contentSize.height - collectionView.bounds.size.height)
//                withAnimation {
//                    collectionView.setContentOffset(targetContentOffset, animated: true)
//                }
//            }
//        } else if collecitonEdge == .top {
//            withAnimation {
//                collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), 
//                                            at: collecitonEdge, animated: true)
//            }
//        }
//        print("updated 2. scrolled to \(edgeToScroll) by Tab button")
//        DispatchQueue.main.async {
//            edgeToScroll = .none
//        }
//        
//    }
    // -> (5) beloning filter
    func reloadAllPhotos(collectionView: UICollectionView, 
                         all: Bool = true,
                         index: [IndexPath] = [],
                         completion: @escaping (Int) -> Void) {
        if all {
            DispatchQueue.main.async {
                withAnimation {
                    collectionView.reloadData()
                }
            }
        } else {
            DispatchQueue.main.async {
                withAnimation {
                    collectionView.reloadItems(at: index)
                }
            }
        }
        completion(album.frObject(isHiddenAsset: isHiddenAssets).count)
    }
    
    // -> (6) selectedCell change
    func reloadSelectedPhotos(all: Bool, collectionView: UICollectionView) {
        if all {
            DispatchQueue.main.async {
                withAnimation {
                    collectionView.reloadData()
                }
//                stateChangeObject.selectToggleAllPhotos = false
//                if stateChangeObject.photosEdited == true {
//                    stateChangeObject.photosEdited = false
//                }
            }
        } else {
            let indexPaths = selectedItemsIndex.map{ IndexPath(item: $0, section: 0) }
            DispatchQueue.main.async {
                withAnimation {
                    collectionView.reloadItems(at: indexPaths )
                }
//                stateChangeObject.selectToggleSomePhotos = false
                selectedItemsIndex.removeAll()
            }
        }
    }
    
    
    // -> (6) load pickeButton Cell
    func loadPickerButtonCell(collectionView: UICollectionView) {
        DispatchQueue.main.async {
            var count: Int
            let array = album.frObject(isHiddenAsset: isHiddenAssets)
            switch filteringType {
            case .all:
                count = array.count
            case .image:
                count = array.filter{ $0.mediaType == .image }.count
            case .video:
                count = array.filter{ $0.mediaType == .video }.count
            case .favorite:
                count = array.filter{ $0.isFavorite == true }.count
            }
            withAnimation {
                collectionView
                    .reloadItems(at: [IndexPath(row: count, section: 0)])
            }
        }
    }
}

class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    private let parent: PhotosCollectionView
    
    
    init(_ collectionView: PhotosCollectionView) {
        self.parent = collectionView
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
    -> Bool {
        return true
    }

    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: parent.collectionView)
            // let collectionView = gestureRecognizer.view as! UICollectionView
        if gestureRecognizer.state == .began {
            if let indexPath = parent.collectionView.indexPathForItem(at: location) {
                UIView.animate(withDuration: 0.2) {
                    if let cell = self.parent.collectionView.cellForItem(at: indexPath) as? GridCell {
                        self.parent.currentLongPressedCell = cell
                        cell.layer.zPosition = 2
                        cell.layer.cornerRadius = 5
                        cell.clipsToBounds = true
                        cell.transform = .init(scaleX: 2, y: 2)
                        if indexPath.row % 5 == 0 {
                            cell.layer.frame.origin.x += 50
                        } else if indexPath.row % 5 == 4 {
                            cell.layer.frame.origin.x -= 50
                        }
                    }
                }
            }
            // 롱 프레스 터치가 시작될 떄
        } else if gestureRecognizer.state == .ended {
            // 롱 프레스 터치가 끝날 떄
            if let indexPath = parent.collectionView.indexPathForItem(at: location) {
                UIView.animate(withDuration: 0.2) {
                    if let cell = self.parent.collectionView.cellForItem(at: indexPath) as? GridCell {
                        self.parent.currentLongPressedCell = nil
                        cell.layer.zPosition = 1
                        cell.layer.cornerRadius = 0
                        cell.clipsToBounds = false
                        cell.transform = .init(scaleX: 1, y: 1)
                        if indexPath.row % 5 == 0 {
                            cell.layer.frame.origin.x -= 50
                        } else if indexPath.row % 5 == 4 {
                            cell.layer.frame.origin.x += 50
                        }
                    }
                }
            }
        } else {
            return
        }
    }
    
    @objc func didPan(toSelectCells panGesture: UIPanGestureRecognizer) {
        if parent.isSelectMode {
            if let collectionView = self.parent.collectionView {
                if panGesture.state == .began {
                    let startLocation: CGPoint = panGesture.location(in: collectionView)
                    if let startIndex: Int = collectionView.indexPathForItem(at: startLocation)?.row {
                        
                    }
                } else if panGesture.state == .changed {
                    
                }
            }
        }
        //        if let collectionView = self.parent.collectionView {
        
        //            if parent.isSelectMode {
        //                if panGesture.state == .began {
        ////                    collectionView.isUserInteractionEnabled = false
        ////                    collectionView.isScrollEnabled = false
        //                    let location: CGPoint = panGesture.location(in: collectionView)
        //                    if let indexPath: IndexPath = collectionView.indexPathForItem(at: location) {
        ////                        if indexPath != parent.lastSelectedCell {
        ////                            self.selectCell(indexPath, selected: true)
        ////                            collectionView.reloadItems(at: [indexPath])
        ////                            parent.lastSelectedCell = indexPath
        ////                        }
        //                        let startPoint = indexPath.row
        //                        if panGesture.state == .
        //                    }
        //                } else if panGesture.state == .changed {
        //                    let location: CGPoint = panGesture.location(in: collectionView)
        //                    if let indexPath: IndexPath = collectionView.indexPathForItem(at: location) {
        //                        if indexPath != parent.lastSelectedCell {
        //                            self.selectCell(indexPath, selected: true)
        //                            collectionView.reloadItems(at: [indexPath])
        //                            parent.lastSelectedCell = indexPath
        //                        }
        //                    }
        //                } else if panGesture.state == .ended {
        ////                    collectionView.isScrollEnabled = true
        ////                    collectionView.isUserInteractionEnabled = true
        //    //                swipeSelect = false
        //                }
        //            }
        //        }
    }
    
    func selectCell(startInt: Int, lastInt: Int! = nil) {
        if lastInt == nil {
            let _ = [startInt]
        } else {
            let _ = [startInt...lastInt]
        }
    }
    
    func selectCell(_ indexPath: IndexPath, selected: Bool) {
        if let _ = parent.collectionView.cellForItem(at: indexPath) {
            if parent.selectedItemsIndex.contains(indexPath.row) {
                parent.collectionView.deselectItem(at: indexPath, animated: true)
                
                if let index = parent.selectedItemsIndex.firstIndex(of: indexPath.row) {
                    parent.selectedItemsIndex.remove(at: index)
                }
                parent.collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: true)
            } else {
                parent.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionView.ScrollPosition.centeredVertically)
                parent.selectedItemsIndex.append(indexPath.row)
            }
            if let numberOfSelections = parent.collectionView.indexPathsForSelectedItems?.count {
                //                title = "\(numberOfSelections) items selected"
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        let album = self.parent.album
        let additional = self.parent.albumType == .album ? 1 : 0
        switch self.parent.filteringType {
        case .all:
            return parent.isHiddenAssets
            ? album.frCount(fr1: album.fetchResult, fr2: album.hiddenFetchResult)
            : album.fetchResult.count + additional
//        case .image:
//            return parent.isHiddenAssets
//            ? album.hiddenArray
//                .filter{ $0.mediaType == .image }
//                .count
//            : album.fetchResult
//                .objects(at: IndexSet(integersIn: 0..<album.fetchResult.count))
//                .filter{ $0.mediaType == .image }
//                .count
//                + additional
//        case .video:
//            return parent.isHiddenAssets
//            ? album.hiddenArray
//                .filter{ $0.mediaType == .video }
//                .count
//            : album.fetchResult
//                .objects(at: IndexSet(integersIn: 0..<album.fetchResult.count))
//                .filter{ $0.mediaType == .video }
//                .count
//                + additional
        case .favorite:
            return album.fetchResult
                .objects(at: IndexSet(integersIn: 0..<album.fetchResult.count))
                .filter { $0.isFavorite }
                .count
            + additional
        default: return 0
        }
//
//        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0,
                            bottom: tabbarHeight
                            + tabbarTopPadding
                            + tabbarBottomPadding
                            + tabbarTopPadding
                            + tabbarHeight,
                            right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let album = self.parent.album
        var array = parent.album.frObject(isHiddenAsset: parent.isHiddenAssets)
        var count: Int
        switch parent.filteringType {
        case .image:
            array = array.filter{ $0.mediaType == .image }
        case .video:
            array = array.filter{ $0.mediaType == .video }
        default: break
        }
        count = array.count
        
        // step 1. cell별 identifier 구분
        var identifier = String()
        switch indexPath.row {
        case 0..<count:
            if self.parent.indexToView == indexPath.row && self.parent.isExpanded {
                identifier = "SpaceCell"
            } else {
                switch self.parent.filteringType {
                case .image: identifier = "ImageCell"
                case .video: identifier = "VideoCell"
                default: identifier = array[indexPath.row]
                        .mediaType == .image ? "ImageCell" : "VideoCell"
                }
            }
        case count: identifier = self.parent.albumType == .album && self.parent.isSelectMode ? "SpaceCell" : "PickerCell"
        default: break
        }
        // step 2. 각 cell의 reusable 셀 생성 및 리로드
        guard let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: identifier,
                                 for: indexPath) as? GridCell
        else {
            return UICollectionViewCell()
        }
        // step 3. indexpath별 셀 구성
        if indexPath.row < count {
            var asset = array[indexPath.row]
            //            cell.cachingManger = self.parent.imageCachingManager
            cell.representedAssetIdentifier = asset.id
            cell.asset = asset
            cell.width = collectionView.contentSize.width
            
            let size = ((min(screenSize.width, screenSize.height) - 4) / 5) * scale
            let requestOptions = PHImageRequestOptions()
            requestOptions
                .deliveryMode = .opportunistic
            requestOptions.isSynchronous = true
            requestOptions.isNetworkAccessAllowed = true
            parent.imageCachingManager
                .requestImage(for: asset.phAsset,
                              targetSize: CGSize(width: size, height: size),
                              contentMode: .aspectFill,
                              options: requestOptions,
                              resultHandler: { image, _ in
                    if cell.representedAssetIdentifier == asset.id {
                        cell.thumbnailImage = image
                    }
                })
            
            let checkSelected = self.parent.isSelectMode
                                    && self.parent.selectedItemsIndex
                                        .contains(indexPath.row)
            
            if self.parent.indexToView == indexPath.row && self.parent.isExpanded {
                cell.settingSpaceCell()
            } else {
                cell.settingCell(isVideoCell: asset.mediaType == .video,
                                 isSelected: checkSelected)
            }
            cell.checkMarkView.alpha = checkSelected ? 1 : 0
            cell.imageView.alpha = checkSelected ? 0.4:1
        } else if self.parent.albumType == .album && indexPath.row == count {
            if !self.parent.isSelectMode {
                cell.settingPickerCell()
            } else {
                cell.settingSpaceCell()
            }
        }
        cell.animationID = self.parent.animationID
        
        cell.showsLargeContentViewer = true
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let album = self.parent.album
        var array = album.frObject(isHiddenAsset: self.parent.isHiddenAssets)
        var count: Int
        switch parent.filteringType {
        case .image:
            array = array.filter{ $0.mediaType == .image }
        case .video:
            array = array.filter{ $0.mediaType == .video }
        default: break
        }
        count = array.count
        
        switch indexPath.row {
        case 0..<count:
            if self.parent.isSelectMode {
                //                if !parent.isSelectingBySwipe {
                if self.parent.selectedItemsIndex.contains(indexPath.row) {
                    guard let index = self.parent.selectedItemsIndex.firstIndex(of: indexPath.row) else { return }
                    self.parent.selectedItemsIndex.remove(at: index)
                } else {
                    self.parent.selectedItemsIndex.append(indexPath.row)
                }
//                UIView.animate(withDuration: 0.25) {
//                    collectionView.reloadItems(at: [indexPath])
//                }
                //                } else {
                //                    if self.parent.selectedItemsIndex.contains(indexPath.row) {
                //                        guard let index = self.parent.selectedItemsIndex.firstIndex(of: indexPath.row) else { return }
                //                        self.parent.selectedItemsIndex.remove(at: index)
                //                    } else {
                //                        self.parent.selectedItemsIndex.append(indexPath.row)
                //                    }
                //                }
            } else {
                self.parent.indexToView = indexPath.row
//                self.parent.selectedIndex = indexPath
                withAnimation {
                    self.parent.isExpanded = true
                }
            }
        case count:
            if self.parent.albumType == .album {
                if !self.parent.isSelectMode {
                    self.parent.isShowingPhotosPicker = true
                }
            } else {
                break
            }
        default: break
        }
    }
    
    
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    //        let numberOfCell = device == .phone ? 4.0 : 10.0
    //        let width = (min(screenSize.width, screenSize.height) - (numberOfCell - 1)) / numberOfCell
    //        return CGSize(width: width, height: width)
    //    }
    
    //    func loadImage(asset: PHAsset) -> UIImage? {
    //        let imageManager = PHCachingImageManager()
    //        let size = ((min(screenSize.width, screenSize.height) - 4) / 5) * scale
    //        var image = UIImage()
    //        let requestOptions = PHImageRequestOptions()
    //        requestOptions.version = .current
    //        requestOptions.deliveryMode = .opportunistic
    //        requestOptions.resizeMode = .exact
    //        requestOptions.isSynchronous = true
    //            imageManager.requestImage(for: asset, targetSize: CGSize(width: size, height: size), contentMode: .aspectFill, options: requestOptions) { assetImage, _ in
    //                if let assetImage = assetImage {
    //                    image = assetImage
    //                }
    //            }
    //        return image
    //    }
    
}

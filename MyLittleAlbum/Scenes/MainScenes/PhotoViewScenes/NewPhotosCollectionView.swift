//
//  NewPhotosCollectionView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/3/25.
//

import SwiftUI
import Photos
import UIKit

struct NewPhotosCollectionView: UIViewRepresentable {
    @EnvironmentObject var photoData: MLPhotoData
    // 0. 앨범 정보
    var albumType: AlbumType = .album
    @ObservedObject var mlAlbum: MLAlbum
    var assetCollection: PHAssetCollection!
    var isHiddenAssets: Bool = false
    
    let assetArray: [MLAsset]
    @Binding var filteringType: FilteringType
    
    let geoProxy: GeometryProxy
    let cellWidth: CGFloat
    let imageCachingManager: PHCachingImageManager
    
    // 1. 콜렉션뷰
    @State var collectionView: UICollectionView!
    @State var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    // 2. 셀렉트 정보
    @Binding var isSelectMode: Bool
    @Binding var selectedItems: [MLAsset]
    @Binding var refreshItems: [MLAsset]
    // 2. 디테일뷰
    @Binding var indexToView: Int
    @Binding var isExpanded: Bool
    
    // 3.
    @Binding var edgeToScroll: EdgeToScroll
    @Namespace var nameSpace
    @Binding var reLoadingType: ReLoadingType
    @State var inited: Bool = false
    @State var longPressedCell: GridCell?
    
    func makeUIView(context: Context) -> some UIView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        layout.minimumInteritemSpacing = 1.0
        layout.minimumLineSpacing = 1.0
        
        let inset = UIEdgeInsets(top: 0, left: 0,
                                 bottom: cellWidth
                                         + tabbarHeight
                                         + tabbarTopPadding
                                         + tabbarBottomPadding,
                                 right: 0)
        layout.sectionInset = inset
        let collectionView = UICollectionView(
            frame: CGRect(origin: CGPoint(x: 0, y: 0), size: geoProxy.size),
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = UIColor(.fancyBackground)
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "VideoCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "PickerCell")
        
        collectionView.allowsMultipleSelection = false
        collectionView.delegate = context.coordinator
        
        let longPressedGesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(gestureRecognizer:))
        )
        longPressedGesture.minimumPressDuration = 0.6
        longPressedGesture.delegate = context.coordinator as any UIGestureRecognizerDelegate
        longPressedGesture.delaysTouchesBegan = true
        collectionView.addGestureRecognizer(longPressedGesture)

        DispatchQueue.main.async {
            UIView.animate(withDuration: 2) {
                settingDataSource(cellWidth: cellWidth,
                                  collectionView: collectionView)
            }
            self.collectionView = collectionView
        }
        return collectionView
    }
    
    func makeCoordinator() -> NewCoordinator {
        NewCoordinator(parent: self, filteringType: $filteringType)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if dataSource != nil {
            // 0. 체인지 업데이트
            switch reLoadingType {
            case .none: break
            case .selectedModeChange, .deselectAll, .selectAll, .itemChangedInside:
                selectedReload(reloadType: reLoadingType) {
                    mlAlbum.processingChange(bool: false)
                }
            case .belongingChange, .filterChange:
                fetchLoad(refetch: true) {
                    mlAlbum.processingChange(bool: false)
                }
            case .reFetchInside, .reFetchOutside:
                if reLoadingType == .reFetchInside {
                    // 1. selectMode change
                    if isSelectMode {
                        DispatchQueue.main.async {
                            isSelectMode = false
                            selectedItems.removeAll()
                        }
                    }
                } else if reLoadingType == .reFetchOutside {
                    // 2. selected items to REMOVE 체크
                    checkSelectedItems()
                }
                dispatchAnimation {
                    reLoadingType = .none
                }
                fetchLoad(refetch: true) {
                    dispatchAnimation {
                        mlAlbum.processingChange(bool: false)
                    }
                }
            case .itemChangedOutside:
                let items: [Item] = refreshItems.map{( .asset($0) )}
                reloadItems(items: items) {
                    mlAlbum.processingChange(bool: false)
                }
            }
            
//            switch reLoadingType {
//            case .reFetchInside, .reFetchOutside, .filterChange, .belongingChange:
//                if reLoadingType == .reFetchOutside {
//                    selectedItems.reversed().forEach { asset in
//                      if !assetArray
//                            .filter ({
//                                return switch filteringType {
//                                case .all: true
//                                case .favorite: $0.isFavorite
//                                default: FilteringType
//                                        .trueType(type: self.filteringType) == $0.mediaType
//                                }
//                            })
//                            .contains(asset) {
//                            if let index = selectedItems.firstIndex(of: asset) {
//                                dispatchAnimation {
//                                    selectedItems.remove(at: index)
//                                }
//                            }
//                        }
//                    }
//                }
//                dispatchAnimation {
//                    reLoadingType = .none
//                }
//                fetchLoad(refetch: true) {
//                    dispatchAnimation {
//                        mlAlbum.processingChange(bool: false)
//                    }
//                }
//            case .selectedModeChange, .selectAll, .deselectAll:
//                selectedReload(reloadType: reLoadingType) {
//                    mlAlbum.processingChange(bool: false)
//                }
//            default: break
//            }
//            
            // 1. scroll
            if !assetArray
                .filter({
                    return switch filteringType {
                    case .all: true
                    case .favorite: $0.isFavorite
                    default: FilteringType
                            .trueType(type: self.filteringType) == $0.mediaType
                    }
                })
                .isEmpty {
                switch edgeToScroll {
                case .top:
                    print("scroll Top")
                    DispatchQueue.main.async {
                        edgeToScroll = .none
                        UIView.animate(withDuration: 0.5) {
                            collectionView
                                .scrollToItem(at: IndexPath(item: 0, section: 0),
                                              at: .top,
                                              animated: true)
                        }
                        
                    }
                case .bottom:
                    print("scroll bottom")
                    DispatchQueue.main.async {
                        edgeToScroll = .none
                        UIView.animate(withDuration: 0.5) {
                            collectionView.scrollToItem(
                                at: IndexPath(item: collectionView
                                                    .numberOfItems(inSection: 0) - 1,
                                              section: 0),
                                at: .centeredVertically,
                                animated: true)
                        }
                    }
                case .none:
                    break
                }
            }
        }
    }
}

extension NewPhotosCollectionView {
    enum Section: Hashable {
        case main
    }
    enum Item: Hashable {
        case asset(_ asset: MLAsset)
        case btnAdd
    }

    func settingDataSource(cellWidth: CGFloat,
                           collectionView: UICollectionView) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .fastFormat
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        self.dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
                switch item {
                case let .asset(asset):
                    let isVideo = asset.mediaType == .video ? true : false
                    guard let cell = collectionView
                        .dequeueReusableCell(
                            withReuseIdentifier: isVideo ? "VideoCell" : "ImageCell",
                            for: indexPath) as? GridCell else {
                        return UICollectionViewCell()
                    }
                    // cell setting
                    cell.representedAssetIdentifier = asset.id
                    cell.asset = asset
                    cell.width = cellWidth
                    cell.imageManager = imageCachingManager
                    imageCachingManager
                        .requestImage(for: asset.phAsset,
                                      targetSize: CGSize(width: cellWidth,
                                                         height: cellWidth),
                                      contentMode: .aspectFill,
                                      options: requestOptions,
                                      resultHandler: { image, _ in
                            guard cell.representedAssetIdentifier == asset.id else { return }
                            dispatchAnimation {
                                cell.imageView.image = image
                            }
                        })
                        
                    let checkSelected = self.selectedItems.contains(cell.asset)
//                    if self.indexToView == indexPath.row && self.isExpanded {
//                        cell.settingSpaceCell()
//                    } else {
                        cell.settingCell(isVideoCell: isVideo, isSelected: checkSelected)
//                    }
//                    cell.clipsToBounds = true
                    return cell
                case .btnAdd:
                    guard let cell = collectionView
                        .dequeueReusableCell(withReuseIdentifier: "PickerCell",
                                             for: indexPath) as? GridCell else {
                        return UICollectionViewCell()
                    }
                    cell.width = cellWidth
                    cell.settingPickerCell()
                    cell.isHidden = isSelectMode
                    return cell
                }
        })
        fetchLoad {
            print("initial Loading done")
        }
    }
    func reloadItems(items: [Item], completion: @escaping () -> Void) {
        if let dataSource = self.dataSource {
            var snap = dataSource.snapshot()
            if let _ = snap.indexOfSection(.main) {
                snap.reloadItems(items)
                DispatchQueue.global().async {
                    self.dataSource.apply(snap, animatingDifferences: true)
                }
            }
        }
        completion()
    }
    func selectedReload(reloadType: ReLoadingType, completion: @escaping () -> Void) {
        var items: [Item] = []
        switch reloadType {
        case .selectAll:
            let toSelect = mlAlbum
                .operatedArray(isHiddenAsset: self.isHiddenAssets,
                               setOperation: .subtraction,
                               assets: selectedItems)
                .filter {
                    return switch filteringType {
                    case .all: true
                    case .favorite: $0.isFavorite
                    default: FilteringType
                            .trueType(type: self.filteringType) == $0.mediaType
                    }
                }
            items.append(contentsOf: toSelect.map( { .asset($0) }))
            DispatchQueue.main.async {
                self.selectedItems.append(contentsOf: toSelect)
            }
        case .deselectAll:
            items.append(contentsOf: selectedItems.map({ .asset($0) }))
            DispatchQueue.main.async {
                selectedItems.removeAll()
            }
        case .selectedModeChange:
            if !isSelectMode && !selectedItems.isEmpty {
                items.append(contentsOf: selectedItems.map({ .asset($0) }))
                DispatchQueue.main.async {
                    selectedItems.removeAll()
                }
            }
            if albumType == .album && !isHiddenAssets {
                items.append(.btnAdd)
            }
        default: break
        }
        reloadItems(items: items) {
            dispatchAnimation {
                self.reLoadingType = .none
            }
            completion()
        }
    }
    func fetchLoad(refetch: Bool = false, completion: @escaping () -> Void) {
        var snapshot = dataSource != nil
                        ? dataSource.snapshot()
                        : NSDiffableDataSourceSnapshot<Section, Item>()
        if snapshot.sectionIdentifiers.isEmpty {
            snapshot.appendSections([.main])
        }
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .main))
        var items: [Item] = assetArray
                .filter {
                    return switch filteringType {
                    case .all: true
                    case .favorite: $0.isFavorite
                    default: FilteringType
                            .trueType(type: self.filteringType) == $0.mediaType
                    }
                }
                .map { .asset($0) }
        if self.albumType == .album && !isHiddenAssets {
            items.append(.btnAdd)
        }
        snapshot.appendItems(items)
        if self.albumType == .album && !isHiddenAssets {
            snapshot.reloadItems([.btnAdd])
        }
        if snapshot.itemIdentifiers != dataSource?.snapshot().itemIdentifiers {
            DispatchQueue.global(qos: .background).async {
                self.dataSource?.apply(snapshot, animatingDifferences: true)
                completion()
            }
        } else {
            completion()
        }
    }
    func checkSelectedItems() {
        selectedItems.reversed().forEach { asset in
          if !assetArray
                .filter ({
                    return switch filteringType {
                    case .all: true
                    case .favorite: $0.isFavorite
                    default: FilteringType
                            .trueType(type: self.filteringType) == $0.mediaType
                    }
                })
                .contains(asset) {
                if let index = selectedItems.firstIndex(of: asset) {
                    dispatchAnimation {
                        selectedItems.remove(at: index)
                    }
                }
            }
        }
    }
}

class NewCoordinator: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    private let parent: NewPhotosCollectionView
    @Binding var filteringType: FilteringType
    
    init(parent: NewPhotosCollectionView, filteringType: Binding<FilteringType>) {
        self.parent = parent
        self._filteringType = filteringType
    }
    deinit {
        print("collectionview Deinited")
        parent.dataSource = nil
    }
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: parent.collectionView)
        if gestureRecognizer.state == .began && !parent.isSelectMode {
            let hapticManager = HapticManager.instance
            hapticManager.impact(style: .light)
            if let indexPath = parent.collectionView.indexPathForItem(at: location) {
                UIView.animate(withDuration: 0.2) {
                    if let cell = self.parent.collectionView.cellForItem(at: indexPath) as? GridCell {
                        self.parent.longPressedCell = cell
                        cell.layer.zPosition = 2
                        cell.layer.cornerRadius = 2
                        cell.clipsToBounds = true
                        cell.transform = .init(scaleX: 1.2, y: 1.2)
                        if let asset = cell.asset {
                            self.parent.selectedItems.append(asset)
                            self.parent.isSelectMode = true
                            
                            guard let item = self.parent.dataSource.itemIdentifier(for: indexPath) else { return }
                            var snap = self.parent.dataSource.snapshot()
                            snap.reloadItems([item])
                            DispatchQueue.global().async {
                                withAnimation {
                                    self.parent.dataSource
                                        .apply(snap, animatingDifferences: true)
                                }
                            }
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.2) {
                        if let cell = self.parent.collectionView.cellForItem(at: indexPath) as? GridCell {
                            self.parent.longPressedCell = nil
                            cell.layer.zPosition = 1
                            cell.layer.cornerRadius = 2
                            cell.clipsToBounds = false
                            cell.transform = .init(scaleX: 1, y: 1)
                        }
                    }
                }
            }
//        }
            // 롱 프레스 터치가 시작될 떄
//        } else if gestureRecognizer.state == .ended {
//            // 롱 프레스 터치가 끝날 떄
//            if let indexPath = parent.collectionView.indexPathForItem(at: location) {
//                UIView.animate(withDuration: 0.2) {
//                    if let cell = self.parent.collectionView.cellForItem(at: indexPath) as? GridCell {
//                        self.parent.longPressedCell = nil
//                        cell.layer.zPosition = 1
//                        cell.layer.cornerRadius = 0
//                        cell.clipsToBounds = false
//                        cell.transform = .init(scaleX: 1, y: 1)
////                        if indexPath.row % 5 == 0 {
////                            cell.layer.frame.origin.x -= 50
////                        } else if indexPath.row % 5 == 4 {
////                            cell.layer.frame.origin.x += 50
////                        }
//                    }
//                }
//            }
        } else {
            return
        }
    }
    // 뷰 맨 아래(최근 항목)에서 시작
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !parent.inited {
            let count = parent.assetArray.count
            
            let indexpath = IndexPath(row: count - 1, section: 0)
            DispatchQueue.main.async {
                self.parent.collectionView
                    .scrollToItem(at: indexpath, at: .top, animated: false)
            }
            parent.inited = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let item = parent.dataSource.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) as? GridCell
        else { return }
        if parent.isSelectMode {
            if let index = parent.selectedItems.firstIndex(of: cell.asset) {
                DispatchQueue.main.async {
                    self.parent.selectedItems.remove(at: index)
                }
            } else {
                self.parent.selectedItems.append(cell.asset)
            }
            parent.reloadItems(items: [item]) { }
        } else {
            switch item {
            case .asset(_):
                guard let cell = collectionView.cellForItem(at: indexPath) as? GridCell else { return }
                showDetailView(indexPath: indexPath,
                               image: cell.imageView.image,
                               identifier: cell.asset.id
                )
            case .btnAdd:
                let object = PickerObject(editToAlbum: self.parent.mlAlbum.id,
                                          imageManager: parent.imageCachingManager)
                DispatchQueue.main.async {
                    NotificationCenter.default
                        .post(name: .showPhotosPicker, object: object)
                }
            }
        }

    }
    func showDetailView(indexPath: IndexPath, image: UIImage!, identifier: String) {
        parent.indexToView = indexPath.row
        parent.isExpanded = true
    }
}

//#Preview {
//    NewPhotosCollectionView()
//}

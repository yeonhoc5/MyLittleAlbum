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
    
    @ObservedObject var stateChangeObject: StateChangeObject
    var albumType: AlbumType = .album

    @ObservedObject var album: Album
//     이미지/비디오 필터링 프라퍼티
//    @Binding var filteringType: FilteringType
    // 스크롤 관리 프라퍼티
    @State var scrollAtFirst: Bool = true
    @Binding var edgeToScroll: EdgeToScroll
    // 셀 셀렉트 모드 전환 프라퍼티
    @Binding var isSelectMode: Bool
    @Binding var selectedItemsIndex: [Int]
    @Binding var isShowingPhotosPicker: Bool

    @Binding var indexToView: Int
    @Binding var isExpanded: Bool
    @State var selectedIndex: IndexPath!
    
    
    @State var insertedIndex: [IndexPath]
    @State var removedIndex: [IndexPath]
    @State var changedIndex: [IndexPath]
    @State var currentCount: Int
    
    var animationID: Namespace.ID!
    
    @State var collectionView: UICollectionView!
    
    func makeUIView(context: Context) -> UICollectionView {
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = UIColor(Color.fancyBackground)
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "VideoCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "PickerCell")
        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "SpaceCell")
//        collectionView.register(GridCell.self, forCellWithReuseIdentifier: "ProgressCell")
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.isScrollEnabled = true
        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        
        // 1. 첫 진입시 : [나의 앨범]에서는 맨 위 / 그 외(나의사진/피커뷰/스마트앨범)에서는 첫 진입 시 맨 아래로 스크롤
        if albumType != .album && scrollAtFirst {
            scrollToBottomAtFirst(collectionView: collectionView)
            print("updated 1. scrolled to bottom First")
        }
        // 2. (공통) 스크롤 위/아래 이동
        if edgeToScroll != .none {
            moveToEdge(collectionView: collectionView)
            print("updated 2. scrolled to \(edgeToScroll) by Tab button")
        }
        // 3. 필터링 4 : (공통) 비디오 / 이미지 / 모두 보기 필터링
        if stateChangeObject.allPhotosChanged {
            reloadAllPhotos(collectionView: collectionView, caseNum: 3)
            print("updated 3. photos Are Filtered by you want are changed")
        }
        // 4. 개별 셀 선택시 리로드는 각 셀에서 처리 / 취소 버튼에 의한 선택된 셀들의 리로드와 전체 선택 토글이 이루어지면 여기서 전체 셀 리로드는 여기서 처리
        if stateChangeObject.selectToggleAllPhotos {
            reloadSelectedPhotos(all: true, collectionView: collectionView)
            print("updated 4-1. you pressed Cancel SelectMode at Selected All")
        } else if stateChangeObject.selectToggleSomePhotos {
            reloadSelectedPhotos(all: false, collectionView: collectionView)
            print("updated 4-2. you pressed Cancel SelectMode at Selected some")
        }
        
        // 6. detilaview 완료 후 indextoview 재로딩
        if stateChangeObject.isSlideShowEnded {
            collectionView.reloadItems(at: [IndexPath(item: indexToView, section: 0), selectedIndex])
            DispatchQueue.main.async {
                stateChangeObject.isSlideShowEnded = false
                selectedIndex = nil
            }
            print("updated 7. Detail View has Ended")
        }
        
        // 7. 사진 추가/삭제 후 리로딩
        if currentCount != album.count || stateChangeObject.assetRemoving {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                UIView.animate(withDuration: 1, animations: {
                    print("추가/삭제 리로드 감지")
                    if self.album.belongingType == .all || self.album.belongingType == .album {
                        selectedItemsIndex = []
                        self.isSelectMode = false
                        stateChangeObject.assetRemoving = false
                    }
                    reloadAllPhotos(collectionView: collectionView, caseNum: 7)
                })
            }
        }
        
        
//         5. 선택 모드 토글에 의 한 picker 버튼 노출
        if albumType == .album && stateChangeObject.showPickerButton {
            loadPickerButtonCell(collectionView: collectionView)
            DispatchQueue.main.async {
                stateChangeObject.showPickerButton = false
            }
            print("update 5-2. picker button are come home")
        }

        
        
//        if stateChangeObject.assetRemoving {
//            collectionView.reloadItems(at: selectedItemsIndex.map{IndexPath(row: $0, section: 0)})
//            print("step 1")
//            print("\(selectedItemsIndex)")
//            DispatchQueue.main.async {
//                stateChangeObject.assetRemoving = false
//                print("step 2")
//            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                reloadAllPhotos(collectionView: collectionView)
//            }
//
//        }
        
        
//        if currentCount !=
        
        // 앨범에 추가/삭제가 이뤄질 때마다 전체 리로드
//        func reloadAll() {
//        if currentCount != album.count {
//            print("진입 체크 바람")
//            DispatchQueue.main.async {
//                self.currentCount = album.count
////                let minIndex = selectedItemsIndex.sorted(by: {$0 < $1}).first!
////                let lastCount = album.filteringType == .all ? album.count : (album.filteringType == .image ? album.countOfImage : album.countOfVidoe)
////                let maxIndex = albumType == .album ? lastCount : lastCount - 1
//                self.isSelectMode = false
//                selectedItemsIndex = []
//
//                stateChangeObject.assetRemoving = false
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                    UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2) {
//    //                    collectionView.reloadItems(at: (minIndex...maxIndex).map{IndexPath(row: $0, section: 0)})
//                        reloadAllPhotos(collectionView: collectionView)
//                    }
//                }
//                album.removedIndexPath = []
//                album.changedIndexPath = []
//                album.insertedIndexPath = []
//            }
//            print("진입 체크 완료")
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
    func scrollToBottomAtFirst(collectionView: UICollectionView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            let contentSize = collectionView.contentSize
            if contentSize.height > collectionView.bounds.size.height {
                let targetContentOffset = CGPointMake(0.0, contentSize.height - collectionView.bounds.size.height )
                collectionView.setContentOffset(targetContentOffset, animated: false)
            }
        }
        DispatchQueue.main.async {
            self.scrollAtFirst = false
        }
    }
    // -> (2) scroll edge
    func moveToEdge(collectionView: UICollectionView) {
        let collecitonEdge: UICollectionView.ScrollPosition = edgeToScroll == .top ? .top : .bottom
        if collecitonEdge == .bottom {
            let contentSize = collectionView.contentSize
            if contentSize.height > collectionView.bounds.size.height {
                let targetContentOffset = CGPointMake(0.0, contentSize.height - collectionView.bounds.size.height )
                UIView.animate(withDuration: 0.3) {
                    collectionView.setContentOffset(targetContentOffset, animated: true)
                }
            }
        } else if collecitonEdge == .top {
            UIView.animate(withDuration: 0.3) {
                collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: collecitonEdge, animated: true)
            }
        }
        DispatchQueue.main.async {
            edgeToScroll = .none
        }
    }
    // -> (3) beloning filter
    func reloadAllPhotos(collectionView: UICollectionView, caseNum: Int) {
        UIView.animate(withDuration: 0.2) {
            collectionView.reloadData()
        }
        if caseNum == 3 {
            DispatchQueue.main.async {
                stateChangeObject.allPhotosChanged = false
            }
        } else if caseNum == 7 {
            DispatchQueue.main.async {
                self.currentCount = album.count
                if albumType == .album {
                    stateChangeObject.showPickerButton = false
                }
                selectedItemsIndex = []
                self.isSelectMode = false
                stateChangeObject.assetRemoving = false
//                self.isSelectMode = false
//                stateChangeObject.assetRemoving = false
//                stateChangeObject.showPickerButton = false
//                selectedItemsIndex = []
                
                album.removedIndexPath = []
                album.changedIndexPath = []
                album.insertedIndexPath = []
            }
        }
        
    }
    
    // -> (4) selectedCell change
    func reloadSelectedPhotos(all: Bool, collectionView: UICollectionView) {
        if all {
            UIView.animate(withDuration: 0.1) {
                collectionView.reloadData()
            }
            DispatchQueue.main.async {
                stateChangeObject.selectToggleAllPhotos = false
                if stateChangeObject.photosEdited == true {
                    stateChangeObject.photosEdited = false
                }
            }
        } else {
            var count: Int
            switch album.filteringType {
            case .all: count = album.count
            case .image: count = album.photosArray.filter{ $0.mediaType == .image }.count
            case .video: count = album.photosArray.filter{ $0.mediaType == .video }.count
            }
            
            let indexPaths = selectedItemsIndex.map{IndexPath(item: $0, section: 0)}
            UIView.animate(withDuration: 0.1) {
                collectionView.reloadItems(at: indexPaths )
                collectionView.reloadItems(at: [IndexPath(row: count, section: 0)])
            }
            DispatchQueue.main.async {
                stateChangeObject.selectToggleSomePhotos = false
                selectedItemsIndex.removeAll()
            }
        }
    }
    
    
    // -> (5) load pickeButton Cell
    func loadPickerButtonCell(collectionView: UICollectionView) {
        DispatchQueue.main.async {
            var count: Int
            switch album.filteringType {
            case .all: count = album.count
            case .image: count = album.photosArray.filter{ $0.mediaType == .image }.count
            case .video: count = album.photosArray.filter{ $0.mediaType == .video }.count
            }
            withAnimation {
                collectionView.reloadItems(at: [IndexPath(row: count, section: 0)])
            }
        }
    }
    
//    func changeAlbumFilter(collectionView: UICollectionView) {
//        DispatchQueue.main.async {
//            withAnimation(.easeInOut(duration: 0.35)) {
//                collectionView.reloadData()
//                stateChangeObject.allPhotosChanged = false
//            }
//        }
//    }
//
//    func changeMediaTypeFilter(collectionView: UICollectionView) {
//            UIView.animate(withDuration: 0.2) {
//                collectionView.reloadData()
//            }
//        DispatchQueue.main.async {
//            stateChangeObject.typeFilterChanged = false
//        }
//    }
    
//    func checkChange(albumType: AlbumType, collectionView: UICollectionView) {
//        if albumType == .home {
//            if photoData.changedIndexPath.count + photoData.insertedIndexPath.count + photoData.removedIndexPath.count > 0 {
//                UIView.animate(withDuration: 0.35, delay: 0) {
//                    collectionView.reloadData()
//                }
//                DispatchQueue.main.async {
//                    photoData.removedIndexPath = []
//                    photoData.changedIndexPath = []
//                    photoData.insertedIndexPath = []
//                }
//            }
//        } else {
//            if album.changedIndexPath.count + album.insertedIndexPath.count + album.removedIndexPath.count > 0 {
//        if album.albumAssetsChanged {
//                print("changed implement")
//                UIView.animate(withDuration: 0.35, delay: 0) {
//                    collectionView.reloadData()
//                }
//                DispatchQueue.main.async {
//                    album.albumAssetsChanged = false
//                    album.removedIndexPath = []
//                    album.changedIndexPath = []
//                    album.insertedIndexPath = []
//                }
//            }
//
//    }
    
    
    
}

class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let parent: PhotosCollectionView
    
    init(_ collectionView: PhotosCollectionView) {
        self.parent = collectionView
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let album = self.parent.album
        let additional = self.parent.albumType == .album ? 1 : 0
        switch self.parent.album.filteringType {
        case .all:
            return album.count + additional
        case .image:
            return album.photosArray.filter{ $0.mediaType == .image }.count + additional
        case .video:
            return  album.photosArray.filter{ $0.mediaType == .video }.count + additional
        }
        
    }
     
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 60, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let album = self.parent.album
        var count: Int
        switch album.filteringType {
        case .all:
            count = album.count
        case .image:
            count = album.photosArray.filter{ $0.mediaType == .image }.count
        case .video:
            count = album.photosArray.filter{ $0.mediaType == .video }.count
        }
        
        // step 1. cell별 identifier 구분
        var identifier = String()
        switch indexPath.row {
        case 0..<count:
            if self.parent.indexToView == indexPath.row && self.parent.isExpanded {
                identifier = "SpaceCell"
            } else {
                switch self.parent.album.filteringType {
                case .image: identifier = "ImageCell"
                case .video: identifier = "VideoCell"
                default: identifier = self.parent.album.photosArray[indexPath.row].mediaType == .image ? "ImageCell" : "VideoCell"
                }
            }
        case count: identifier = self.parent.albumType == .album && self.parent.isSelectMode ? "SpaceCell" : "PickerCell"
        default: break
        }
        // step 2. 각 cell의 reusable 셀 생성 및 리로드
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? GridCell else { return UICollectionViewCell() }
        // step 3. indexpath별 셀 구성
        if indexPath.row < count {
            var asset = PHAsset()
            switch self.parent.album.filteringType {
            case .all: asset = parent.album.photosArray[indexPath.row]
            case .image: asset = parent.album.photosArray.filter{ $0.mediaType == .image }[indexPath.row]
            case .video: asset = parent.album.photosArray.filter{ $0.mediaType == .video }[indexPath.row]
            }
            cell.representedAssetIdentifier = asset.localIdentifier
            cell.asset = asset
            cell.width = collectionView.contentSize.width
            
            let checkSelected = self.parent.isSelectMode && self.parent.selectedItemsIndex.contains(indexPath.row)
            
            cell.cellSelected = checkSelected
            if self.parent.indexToView == indexPath.row && self.parent.isExpanded {
                cell.settingSpaceCell()
            } else if asset.mediaType == .image {
                cell.settingImageCell()
            } else {
                cell.settingVideoCell()
                cell.duration = asset.duration
                cell.durationLabel.alpha = checkSelected ? 0 : 1
            }

            cell.checkMarkView.alpha = checkSelected ? 1 : 0
            cell.imageView.alpha = checkSelected ? 0.4:1
//            cell.activityIndicator.alpha = self.parent.stateChangeObject.assetRemoving && checkSelected ? 1 : 0
        } else if self.parent.albumType == .album && indexPath.row == count {
            if !self.parent.isSelectMode {
                cell.settingPickerCell()
            } else {
                cell.settingSpaceCell()
            }
        }
        cell.animationID = self.parent.animationID
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = parent.album
        var count: Int
        switch album.filteringType {
        case .all:
            count = album.count
        case .image:
            count = album.photosArray.filter{ $0.mediaType == .image }.count
        case .video:
            count = album.photosArray.filter{ $0.mediaType == .video }.count
        }
        switch indexPath.row {
        case 0..<count:
            if self.parent.isSelectMode {
                if self.parent.selectedItemsIndex.contains(indexPath.row) {
                    guard let index = self.parent.selectedItemsIndex.firstIndex(of: indexPath.row) else { return }
                    self.parent.selectedItemsIndex.remove(at: index)
                } else {
                    self.parent.selectedItemsIndex.append(indexPath.row)
                }
            } else {
                self.parent.indexToView = indexPath.row
                self.parent.selectedIndex = indexPath
                withAnimation {
                    self.parent.isExpanded = true
                }
            }
            UIView.animate(withDuration: 0.25) {
                collectionView.reloadItems(at: [indexPath])
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
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (min(screenSize.width, screenSize.height) - 4) / 5
        return CGSize(width: width, height: width)
    }
    
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

class GridCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String!
    var asset: PHAsset!
    var cellSelected: Bool = false
    var animationID: Namespace.ID!
    var width: CGFloat!
    
    lazy var imageView: UIImageView! = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    lazy var durationLabel: UILabel! = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold, width: .standard)
        label.textAlignment = .center
        label.textColor = .white
       return label
    }()
    
    var checkMarkView: UIImageView! = {
        let checkMark = "checkmark.circle.fill"
        let checkMarkView = UIImageView(image: UIImage(systemName: checkMark))
        checkMarkView.backgroundColor = .white
        return checkMarkView
    }()
    
    lazy var pickerButtonView: UIImageView! = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "plus")
        imageView.tintColor = UIColor(Color.white.opacity(0.5))
        return imageView
    }()
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    var duration: TimeInterval! {
        didSet {
            let duration: Int = Int(duration / 1.0)
            let hour: String = duration >= 3600 ? "\(duration / 3600):" : ""
            let minute: String = "\(((duration) % 3600) / 60):"
            let second: String = (duration) % 60 >= 10 ? "\((duration) % 60)" : "0\((duration) % 60)"
            durationLabel.text = hour + minute + second
        }
    }
    
//    lazy var activityIndicator: UIActivityIndicatorView = {
//        // Create an indicator.
//        let activityIndicator = UIActivityIndicatorView()
//        activityIndicator.center = self.center
//        activityIndicator.color = UIColor.white
//        activityIndicator.layer.shadowColor = UIColor.black.cgColor
//        activityIndicator.layer.shadowOffset = CGSize(width: 1, height: 1)
//        activityIndicator.layer.shadowRadius = 1
//        activityIndicator.layer.shadowOpacity = 0.8
//        // Also show the indicator even when the animation is stopped.
//        activityIndicator.hidesWhenStopped = false
//        activityIndicator.style = .medium
//        // Start animation.
//        activityIndicator.startAnimating()
//        return activityIndicator }()
    
    
    func settingImageCell() {
        let width = self.frame.width
        [imageView, checkMarkView].forEach {
            addSubview($0)
        }
        fetchingThumbnail(asset: asset)
        imageView.clipsToBounds = true
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: width)
        
        checkMarkView.frame = CGRect(x: width - (width / 3.5) , y: width - (width / 3.5), width: width / 4, height: width / 4)
        checkMarkView.layer.cornerRadius = checkMarkView.frame.width / 2
        checkMarkView.clipsToBounds = true
//        activityIndicator.frame = CGRect(x: 0, y: 0, width: width, height: width)
    }
    
    func settingVideoCell() {
        let width = self.frame.width
        [imageView, checkMarkView, durationLabel].forEach {
            addSubview($0)
        }
        fetchingThumbnail(asset: asset)
        imageView.clipsToBounds = true
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: width)
        
        durationLabel.frame = CGRect(x: width / 2, y: width - (width / 4), width: (width / 2), height: width / 5)
        durationLabel.layer.shadowColor = UIColor.black.cgColor
        durationLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        durationLabel.layer.shadowOpacity = 1
        durationLabel.layer.shadowRadius = 7
        checkMarkView.frame = CGRect(x: width - (width / 3.5) , y: width - (width / 3.5), width: width / 4, height: width / 4)
        checkMarkView.layer.cornerRadius = checkMarkView.frame.width / 2
        checkMarkView.clipsToBounds = true
//        activityIndicator.frame = CGRect(x: 0, y: 0, width: width, height: width)
    }
    
    func settingPickerCell() {
        let width = self.frame.width
        addSubview(pickerButtonView)
        pickerButtonView.frame = CGRect(x: width / 2 - width / 8, y: width / 2 - width / 8, width: width / 4, height: width / 4)
        self.backgroundColor = .gray.withAlphaComponent(0.15)
    }
    
    func settingSpaceCell() {
        self.backgroundColor = .clear
    }
    
//    func settingProgressCell() {
//        let width = self.frame.width
//        let progressRing = UIProgressView(frame: CGRect(x: 0, y: 0, width: width, height: width))
//        progressRing.progressViewStyle = .default
//        addSubview(progressRing)
//    }
    
    func fetchingThumbnail(asset: PHAsset) {
        let size = ((min(screenSize.width, screenSize.height) - 4) / 5) * scale
        let cachingImageManager = PHCachingImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .opportunistic
//        requestOptions.resizeMode = .exact
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        cachingImageManager.requestImage(for: asset, targetSize: CGSize(width: size, height: size), contentMode: .aspectFill, options: requestOptions, resultHandler: { image, _ in
            if self.representedAssetIdentifier == self.asset.localIdentifier {
                self.thumbnailImage = image
            }
        })

    }

    
}
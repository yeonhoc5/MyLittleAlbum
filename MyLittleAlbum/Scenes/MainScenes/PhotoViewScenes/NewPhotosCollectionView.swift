//
//  NewPhotosCollectionView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/3/25.
//

import SwiftUI
import Photos
import UIKit

enum CollectionSection: Hashable {
    case main
}
enum Item: Hashable {
    case asset(_ asset: MLAsset)
    case btnAdd
}

struct NewPhotosCollectionView: UIViewRepresentable, Equatable {
  @EnvironmentObject var photoData: MLPhotoData
  // 0. 앨범 정보
  @ObservedObject var mlAlbum: MLAlbum
  let albumType: AlbumType
  let isHiddenAssets: Bool
  let assetArray: [MLAsset]
  let imageManager: PHCachingImageManager
  @Binding var sampleImages: [String : UIImage]
  // 2. ui
  let geoProxy: GeometryProxy
  let cellWidth: CGFloat
  // 3. 콜렉션뷰
  let containerView = UIView()
  @State var collectionView: UICollectionView!
  @State var dataSource: UICollectionViewDiffableDataSource<CollectionSection, Item>!
  @State var panGesture: UIPanGestureRecognizer!
  // viewState
  @State var isCollectionViewInited: Bool = false
  @Binding var edgeToScroll: EdgeToScroll
  @Binding var isReadyVolumeSort: Bool
  // selectMode
  @Binding var isSelectMode: Bool
  @Binding var selectedItems: [MLAsset]
  @Binding var isSelectingBySwipe: Bool
  @Binding var isUnionMode: Bool
  @Binding var swipeSelectedItems: [MLAsset]
  // view Redraw
  @Binding var isShowingFilter: Bool
  @Binding var filtering: Filtering
  @State var compareFiltering = Filtering()
  @Binding var reLoadingType: ReLoadingType
  // detailView
  @Binding var isExpanded: Bool
  @Binding var indexToView: Int
  @Binding var isShowingPhotosPicker: Bool
  @Binding var refreshItems: [MLAsset]
  
  static func == (lhs: NewPhotosCollectionView,
                  rhs: NewPhotosCollectionView) -> Bool {
    return lhs.assetArray == rhs.assetArray
    && lhs.filtering == rhs.filtering
  }
  
  func makeUIView(context: Context) -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
    layout.minimumInteritemSpacing = 1.0
    layout.minimumLineSpacing = 1.0

    let ishome = albumType == .home || albumType == .picker
    let inset = UIEdgeInsets(
      top: ishome ? 0 : (safeAreaTopPadding + (photoData.premiumUser ? 0 : 120)),
      left: 0,
      bottom: (tabbarHeight * (device == .phone ? 2 : 1)) + 34 + cellWidth,
      right: 0
    )
    layout.sectionInset = inset
//    let collectionView = BottomBlurredCollectionView(
//      frame: CGRect(origin: CGPoint(x: 0, y: 0),size: geoProxy.size),
//      collectionViewLayout: layout,
//      blurHeight: tabbarHeight * 2 + 40)
    let collectionView = UICollectionView(
      frame: CGRect(origin: CGPoint(x: 0, y: 0),
                    size: geoProxy.size),
      collectionViewLayout: layout
    )
    
    ["ImageCell", "VideoCell", "PickerCell"].forEach { id in
      collectionView
        .register(GridCell.self, forCellWithReuseIdentifier: id)
    }
    collectionView.backgroundColor = UIColor(.clear)
    collectionView.allowsMultipleSelection = false
    collectionView.delegate = context.coordinator
    collectionView.alwaysBounceVertical = true // item 없어도 스크롤 작동
    // iOS 26에서 네비게이션바 위치에 자동 Padding이 들어가는 거 막기
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.scrollIndicatorInsets = UIEdgeInsets(
      top: albumType == .home ? navigationbarHeight : 0,
      left: 0,
      bottom: (2 * tabbarHeight - tabbarTopPadding),
      right: 0
    )
    
    // 롱 Press -> 셀 선택(선택모드 변경)
    let longPressedGesture = UILongPressGestureRecognizer(
      target: context.coordinator,
      action: #selector(NewCoordinator.handleLongPress(_ :)))
    longPressedGesture.minimumPressDuration = 0.6
    longPressedGesture.delegate = context.coordinator as any UIGestureRecognizerDelegate
    longPressedGesture.delaysTouchesBegan = true
    collectionView.addGestureRecognizer(longPressedGesture)
    
    // Swipe Selection
    let panGesture = UIPanGestureRecognizer(
      target: context.coordinator,
      action: #selector(NewCoordinator.handleSwipe(_ :)))
    panGesture.delegate = context.coordinator as any UIGestureRecognizerDelegate
    collectionView.addGestureRecognizer(panGesture)
    
    DispatchQueue.main.async {
      // swipe selecting
      self.panGesture = panGesture
      self.panGesture.isEnabled = albumType == .picker
      self.collectionView = collectionView
      context.coordinator.settingDataSource(cellWidth: cellWidth)
    }
    print("CollectionView initializing...\(assetArray.count)")
    return collectionView
  }
  
  func makeCoordinator() -> NewCoordinator {
    NewCoordinator(parent: self,
                   albumType: albumType,
                   cellWidth: cellWidth,
                   assetArray: assetArray)
  }
    
  func updateUIView(_ collecitonView: UICollectionView,
                    context: Context) {
    if albumType != .picker {
      switch isSelectMode{
      default:
        self.panGesture?.isEnabled = isSelectMode
      }
    }
    if dataSource != nil {
      if isReadyVolumeSort {
        fetchLoad {
          context.coordinator.assetArray = assetArray
          self.edgeToScroll = .top
        }
      }
      if filtering != compareFiltering
          && filtering.sort != .byVolume{
        DispatchQueue.main.async {
          compareFiltering = filtering
        }
        print("filter changed")
        fetchLoad(refetch: true) {
          dispatchAnimation {
            context.coordinator.assetArray = assetArray
          }
        }
      }
//      if isReadyVolumeSort {
//        fetchLoad(refetch: true) { }
//      }
      
      // fetch change 및 item update
      switch reLoadingType {
      case .selectedModeChange, .selectAll, .deselectAll, .itemChangedInside:
        selectedReload(reloadType: reLoadingType) {
          dispatchAnimation {
            mlAlbum.processingChange(bool: false)
          }
        }
      case .filterChange:
        dispatchAnimationDelay(delay: albumType == .album || albumType == .share ? 0.2 : 0.5) {
          reLoadingType = .none
          fetchLoad(refetch: true) {
            mlAlbum.processingChange(bool: false)
          }
        }
      case .reFetchInside:
        dispatchAnimation {
          reLoadingType = .none
          removeItems(type: .selected)
          self.isSelectMode = false
          fetchLoad(refetch: true) {
            mlAlbum.processingChange(bool: false)
          }
        }
      case .reFetchOutside:
        dispatchAnimation {
          self.reLoadingType = .none
          // 선택모드에서 선택한 아이템 있을 시 체크
          selectedItems.reversed().forEach { asset in
            if let index = selectedItems.firstIndex(of: asset) {
              DispatchQueue.main.async {
                withAnimation {
                  let _ = self.selectedItems.remove(at: index)
                }
              }
            } else {
              withAnimation {
                self.selectedItems.append(asset)
              }
            }
          }
          fetchLoad(refetch: true) {
            mlAlbum.processingChange(bool: false)
          }
        }
      case .itemChangedOutside:
        let items: [Item] = refreshItems.map({ .asset($0) })
        reloadItems(items: items)
        removeItems(type: .refreshed)
      default: break
      }
//
//    1. scroll 이동
      if edgeToScroll != .none {
        if !assetArray.isEmpty {
          scrollTo(edge: edgeToScroll)
        }
      }
    }
  }
  func doScroll(edge: EdgeToScroll) {
    DispatchQueue.main.async {
      withAnimation{
        self.edgeToScroll = edge
      }
    }
  }
  
}

extension NewPhotosCollectionView {
  
  func makeEmptyText() -> String {
     if albumType == .home || albumType == .picker {
      switch filtering.zero {
      case .allMedia: return "이 기기에는 미디어가 없습니다."
      case .allAlbums: return "모든 항목이 앨범에 있습니다."
      case .currentAlbum: return "모든 미디어가 이 앨범에 있습니다."
      }
    } else {
      if isHiddenAssets {
        return "이 \(albumType == .album ? "앨범" : "기기")에는 가린 항목이 없습니다."
      } else {
        return albumType == .album ? "앨범이 비었습니다." : "해당하는 항목이 없습니다."
      }
    }
  }
  
  func reloadItems(items: [Item]) {
    if let dataSource = self.dataSource {
      var snap = dataSource.snapshot()
      if let _ = snap.indexOfSection(.main) {
        snap.reloadItems(items)
        DispatchQueue.global().async {
          self.dataSource.apply(snap, animatingDifferences: true)
        }
      }
    }
  }
  func selectedReload(reloadType: ReLoadingType, completion: @escaping () -> Void) {
    var items: [Item] = []
    switch reloadType {
    case .selectedModeChange, .deselectAll, .itemChangedInside:
      if !selectedItems.isEmpty {
        let selected: [Item] = selectedItems.map { .asset($0) }
        items.append(contentsOf: selected)
        removeItems(type: .selected)
      }
      if self.albumType == .album && !isHiddenAssets {
        items.append(.btnAdd)
      }
    case .selectAll:
      let toSelect = assetArray
        .setSubtraing(by: Set(selectedItems))
      DispatchQueue.main.async {
        selectedItems.append(contentsOf: toSelect)
      }
      items.append(contentsOf: toSelect.map( { .asset($0) }))
    default: break
    }
//    viewState.changeReloadType(.none)
    dispatchAnimation {
      reLoadingType = .none
    }
    reloadItems(items: items)
    completion()
  }
  func fetchLoad(refetch: Bool = false, completion: @escaping () -> Void) {
    var snapshot = dataSource != nil
    ? dataSource.snapshot()
    : NSDiffableDataSourceSnapshot<CollectionSection, Item>()
    if snapshot.sectionIdentifiers.isEmpty {
      snapshot.appendSections([.main])
    }
    snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .main))
    var items: [Item] = assetArray.map { .asset($0) }
    if self.albumType == .album && !isHiddenAssets {
      items.append(.btnAdd)
    }
    snapshot.appendItems(items)
    if refetch && albumType == .album && !isHiddenAssets {
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
    
  func scrollTo(edge: EdgeToScroll) {
    let indexPath = switch edge {
    case .top: IndexPath(item: 0, section: 0)
    case .bottom: IndexPath(item: collectionView.numberOfItems(inSection: 0) - 1, section: 0)
    default: IndexPath(row: indexToView, section: 0)
    }
    if edge == .number {
      guard !collectionView
        .indexPathsForVisibleItems
        .map({ $0.row })
        .contains(indexToView) else { return }
    }
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.5) {
        collectionView.scrollToItem(
          at: indexPath,
          at: .centeredVertically,
          animated: true)
      }
      self.edgeToScroll = .none
    }
  }
  
  func removeItems(type: SelectedItems) {
    dispatchAnimation {
      switch type {
      case .selected:
        self.selectedItems.removeAll()
      case .swiped:
        self.swipeSelectedItems.removeAll()
      case .refreshed:
        self.refreshItems.removeAll()
      }
    }
  }
}

class NewCoordinator: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
  enum AutoScroll {
    case top1x, top2x, bottom1x, bottom2x, stop
  }
  
  private let parent: NewPhotosCollectionView
  let albumType: AlbumType
  
  // Swipe Select
  var startIndex: Int?
  var endIndex: Int?
  let cellWidth: CGFloat
  var autoScroll: AutoScroll = .stop
  var autoScrollTimer: Timer?
  var assetArray: [MLAsset]
  
  init(parent: NewPhotosCollectionView,
       albumType: AlbumType,
       cellWidth: CGFloat,
       assetArray: [MLAsset]) {
    self.parent = parent
    self.albumType = albumType
    self.cellWidth = cellWidth
    self.assetArray = assetArray
    super.init()
  }
  deinit {
    self.parent.dataSource?.supplementaryViewProvider = nil
    self.parent.dataSource = nil
    self.parent.collectionView = nil
    print("Collectionview Deinited")
  }
  // PanGesture Simultaneously with CollectionView Pangesture
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let panGesture = parent.collectionView?.panGestureRecognizer
    else { return false }
    if (gestureRecognizer is UIPanGestureRecognizer
        && otherGestureRecognizer == panGesture)
        || (otherGestureRecognizer is UIPanGestureRecognizer
            && gestureRecognizer == panGesture) {
      return !parent.isSelectingBySwipe
    } else {
      return false
    }
  }
  
  @objc func handleSwipe(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard let collectionView = parent.collectionView else { return }
    let location = gestureRecognizer.location(in: collectionView)
    
    switch gestureRecognizer.state {
    case .began:
      // 0. swipe select
      // 0-1. swipe Select 판단 결정
      decideSwipeSelect(recognizer: gestureRecognizer) { bool in
        guard bool else { return }
        self.parent.collectionView.isScrollEnabled = false
        self.parent.isSelectingBySwipe = true
        // 0-2. 첫번째 셀 지정
        guard let indexPath = collectionView
                          .indexPathForItem(at: location),
              indexPath.row < self.assetArray.count-1,
              let cell = collectionView
                      .cellForItem(at: indexPath) as? GridCell,
              let startAsset = cell.asset
        else { return }
        
        self.startIndex = indexPath.row
        self.endIndex = indexPath.row
        // 0-3. union 모드 결정 (추가 or 제외)
        self.checkUnionMode(asset: startAsset)
        self.parent
          .reloadItems(items: [startAsset].map{ .asset($0) })
      }
    case .changed:
      guard self.parent.isSelectingBySwipe
      else { return }
      // 1-1. selectmode에서 top / bottom으로 이동 시 AutoScroll
      checkAutoScroll(location: location,
                      isPicker: albumType == .picker)
      let indexPath = collectionView
                      .indexPathForItem(at: location)
      ?? IndexPath(row: location.y < safeAreaTopPadding
                   ? 0 : (assetArray.count-1), section: 0)
      let row = indexPath.row >= self.assetArray.count ? (self.assetArray.count-1) : indexPath.row
      guard let end = self.endIndex,
            row != end
      else { return }
      changeLastItem(selected: row) { selectedItems, toReload in
        // swipe selected 재지정
        let swipeItems = selectedItems
                        .map({ self.assetArray[$0] })
        let itemsToReload = toReload
                        .map({ self.assetArray[$0] })
        self.parent.swipeSelectedItems = swipeItems
        // 재 Reload할 것들 지정
        if !itemsToReload.isEmpty {
          let alreadySelected = self.parent.selectedItems
          let toReload = if self.parent.isUnionMode {
            Set(itemsToReload)
              .subtracting(Set(alreadySelected))
          } else {
            Set(itemsToReload)
              .intersection(Set(alreadySelected))
          }
          self.parent.reloadItems(
            items: toReload.map{( .asset($0) )}
          )
        }
      }
    case .ended:
      guard self.parent.isSelectingBySwipe
      else { return }
      endSwipeSelect()
    default:
      break
    }
  }
  func checkUnionMode(asset: MLAsset) {
    self.parent.isUnionMode = !self.parent.selectedItems.contains(asset)
    DispatchQueue.main.async {
      self.parent.swipeSelectedItems = [asset]
    }
  }
  func checkAutoScroll(location: CGPoint, isPicker: Bool) {
    guard let bounds = parent.collectionView?.bounds
    else { return }
    let topBoundary = bounds.origin.y
                  + (albumType == .album || albumType == .share
                     ? safeAreaTopPadding : 0)
                  - (cellWidth / 2)
    let bottomHeight = tabbarHeight * (device == .pad ? 1 : 2) + 25
    let bottomBoundary = bounds.maxY - bottomHeight
    switch location.y {
    case ...topBoundary :
      if self.autoScroll != .top2x {
        autoScroll(autoScroll: .top2x, edge: .top, speed: 2.0)
      }
    case topBoundary..<(topBoundary + cellWidth):
      if self.autoScroll != .top1x {
        autoScroll(autoScroll: .top1x, edge: .top)
      }
    case (bottomBoundary-(cellWidth/2))...(bottomBoundary + tabbarHeight):
      if self.autoScroll != .bottom1x {
        autoScroll(autoScroll: .bottom1x, edge: .bottom)
      }
    case (bottomBoundary + tabbarHeight)...:
      if self.autoScroll != .bottom2x {
        autoScroll(autoScroll: .bottom2x, edge: .bottom, speed: 2.0)
      }
    default:
      if self.autoScroll != .stop {
        self.autoScroll = .stop
        endAutoScroll()
      }
    }
  }
  func decideSwipeSelect(recognizer: UIPanGestureRecognizer, isStart: @escaping (Bool) -> Void) {
    guard let collectionView = parent.collectionView
    else { return }
    let translation = recognizer
                      .translation(in: collectionView)
    let velocity = recognizer.velocity(in: collectionView)
    // select Mode에서 "스크롤"을 할지 "셀렉팅"을 할지 결정
    if (abs(translation.x) > (3 * abs(translation.y))
        || abs(velocity.x) > (3 * abs(velocity.y))) {
      isStart(true)
      print("ok. swipe select start")
    } else {
      isStart(false)
    }
  }
  func changeLastItem(selected: Int,
                      resultSelected: @escaping ([Int], [Int]) -> Void) {
    var itemsToReload: [Int] = []
    let tempLast = selected
    
    guard let startIndex = self.startIndex,
          let endIndex = self.endIndex
    else { return }
    
    // 선택 영역 지정
    let start = min(startIndex, tempLast)
    let end = max(startIndex, tempLast)
    
    // 새로 추가 선택되는 셀들만 Reload 셀로 지정
    let smaller = min(endIndex, tempLast)
    let bigger = max(endIndex, tempLast)
    if tempLast >= startIndex {
      if endIndex >= startIndex {
        itemsToReload = Array( (smaller+1)...bigger )
      } else {
        itemsToReload = Array( smaller...(startIndex-1) )
        + Array( (startIndex+(startIndex == bigger ? 0 : 1))...bigger )
      }
    } else {
      if endIndex <= startIndex {
        itemsToReload = Array( smaller...(bigger-1) )
      } else {
        itemsToReload = Array( smaller...(startIndex-1) )
        + Array( (startIndex+1)...bigger )
      }
    }
    self.endIndex = tempLast
    resultSelected(Array(start...end), itemsToReload)
  }
  func autoScroll(autoScroll: AutoScroll, edge: EdgeToScroll, speed: CGFloat = 1) {
//    DispatchQueue.main.async {
      self.autoScroll = autoScroll
//    }
    if autoScrollTimer != nil {
      autoScrollTimer?.invalidate()
    }
    autoScrollTimer = Timer
      .scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
        guard let self = self,
              let collectionView = self.parent.collectionView
        else { return }
        let offset = collectionView.contentOffset
        let newOffset = CGPoint(
          x: offset.x,
          y: offset.y + ((edge == .top ? -5 : 5) * speed)
        )
        if edge == .top {
          guard collectionView.contentOffset.y > 0 else { return }
          UIView.animate(withDuration: 0.1 / speed) {
            collectionView.setContentOffset(newOffset, animated: false)
          }
        } else {
          guard collectionView.contentSize.height
                  - collectionView.contentOffset.y
                  > collectionView.bounds.height
          else { return }
          UIView.animate(withDuration: 0.1 / speed) {
            collectionView
              .setContentOffset(newOffset, animated: false)
          }
        }
      }
  }
  func endAutoScroll() {
    DispatchQueue.main.async {
      self.autoScroll = .stop
      if let timer = self.autoScrollTimer {
        timer.invalidate()
        self.autoScrollTimer = nil
      }
    }
  }
  func endSwipeSelect() {
    guard let collectionView = parent.collectionView
    else { return }
    if !parent.swipeSelectedItems.isEmpty {
      if parent.isUnionMode {
        DispatchQueue.main.async {
          self.parent.selectedItems = Array(
            Set(self.parent.selectedItems)
              .union(Set(self.parent.swipeSelectedItems))
          )
        }
      } else {
        DispatchQueue.main.async {
          self.parent.selectedItems = Array(
            Set(self.parent.selectedItems)
              .subtracting(Set(self.parent.swipeSelectedItems))
          )
        }
      }
    }
    startIndex = nil
    endIndex = nil
    self.parent.isSelectingBySwipe = false
    collectionView.isScrollEnabled = true
    parent.removeItems(type: .swiped)
    if autoScrollTimer != nil {
      endAutoScroll()
    }
    print("Swipe Select done")
  }
  // cell LongPress -> 해당 셀 선택과 함께 선택모드 시작 (선택모드 아닐 시에만 작동)
  @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
    guard let collectionVeiw = parent.collectionView
    else { return }
    let location = gestureRecognizer
                    .location(in: collectionVeiw)
    if gestureRecognizer.state == .began && !parent.isSelectMode {
      let hapticManager = HapticManager.instance
      hapticManager.impact(style: .light)
      guard let indexPath = collectionVeiw
                        .indexPathForItem(at: location),
            let cell = collectionVeiw
                        .cellForItem(at: indexPath) as? GridCell,
            let asset = cell.asset,
            let item = self.parent.dataSource
                        .itemIdentifier(for: indexPath)
      else { return }
      var snap = self.parent.dataSource.snapshot()
      cell.layer.zPosition = 2
      cell.layer.cornerRadius = 2
      cell.clipsToBounds = true
      cell.transform = .init(scaleX: 1.3, y: 1.3)
//      self.parent.viewState.toggleSelectMode(bool: true)
      self.parent.isSelectMode = true
      self.parent.selectedItems.append(asset)
      if self.parent.albumType == .album
          && !self.parent.isHiddenAssets {
        snap.reloadItems([item, .btnAdd])
      } else {
        snap.reloadItems([item])
      }
      DispatchQueue.global().async {
        withAnimation(.easeInOut(duration: 0.4)) {
          self.parent.dataSource
            .apply(snap, animatingDifferences: true)
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        withAnimation(.easeInOut(duration: 0.4)) {
          cell.layer.zPosition = 1
          cell.layer.cornerRadius = 2
          cell.clipsToBounds = false
          cell.transform = .init(scaleX: 1, y: 1)
        }
      }
    } else {
      return
    }
  }
  
  // 뷰 맨 아래(최근 항목)에서 시작
  func collectionView(_ collectionView: UICollectionView,
                      willDisplay cell: UICollectionViewCell,
                      forItemAt indexPath: IndexPath) {
    if !parent.isCollectionViewInited {
      let count = parent.assetArray.count
      let indexpath = IndexPath(row: count - 1, section: 0)
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.parent.collectionView
          .scrollToItem(at: indexpath, at: .top, animated: false)
        DispatchQueue.main.async {
          withAnimation{
            self.parent.isCollectionViewInited = true
          }
        }
      }
    }
  }
//  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//    print("touch ?????, ")
//    let bottomBoundary = parent.collectionView.bounds.maxY
//                        - (tabbarHeight * (albumType == .picker ? 1 : 2))
//                        - tabbarBottomPadding
//                        - (albumType == .picker ? 0 : 10)
//    let locaiton = gestureRecognizer.location(in: self.parent.collectionView)
//    print(locaiton.y, bottomBoundary)
//    if locaiton.y < bottomBoundary {
//      return true
//      
//    } else {
//      return false
//      
//    }
//  }
  func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: any UISpringLoadedInteractionContext) -> Bool {
    return true
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    if parent.isShowingFilter {
      DispatchQueue.main.async {
        withAnimation(.bouncy(duration: 0.3)) {
          self.parent.isShowingFilter = false
        }
      }
    } else {
      guard let item = parent.dataSource
                        .itemIdentifier(for: indexPath),
            let cell = collectionView
                        .cellForItem(at: indexPath) as? GridCell
      else { return }
      if parent.isSelectMode {
        if let index = self.parent.selectedItems.firstIndex(of: cell.asset) {
          DispatchQueue.main.async {
            let _ = self.parent.selectedItems.remove(at: index)
          }
        } else {
          self.parent.selectedItems.append(cell.asset)
        }
        parent.reloadItems(items: [item])
      } else {
        switch item {
        case .asset(_):
          guard let cell = collectionView.cellForItem(at: indexPath) as? GridCell else { return }
          showDetailView(indexPath: indexPath,
                         image: cell.imageView.image,
                         identifier: cell.asset.id)
        case .btnAdd:
          DispatchQueue.main.async {
//              self.parent.isShowingPhotosPicker = true
            NotificationCenter.default
              .post(name: .showPhotosPicker,
                    object: self.parent.mlAlbum.id)
          }
        }
      }
    }
  }
  func showDetailView(indexPath: IndexPath, image: UIImage!, identifier: String) {
    self.parent.indexToView = indexPath.row
    DispatchQueue.main.async {
        self.parent.isExpanded = true
    }
  }
  
  func settingDataSource(cellWidth: CGFloat) {
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .fastFormat
    requestOptions.resizeMode = .exact
    requestOptions.isSynchronous = true
    requestOptions.isNetworkAccessAllowed = true
    
    parent.dataSource = UICollectionViewDiffableDataSource<CollectionSection, Item>(
      collectionView: parent.collectionView ?? UICollectionView(),
      cellProvider: { [weak self] (collectionView, indexPath, item) ->
        UICollectionViewCell in
        guard let self = self else { return UICollectionViewCell() }
        switch item {
        case let .asset(asset):
          let isVideo = asset.mediaType == .video
          guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: isVideo ? "VideoCell" : "ImageCell",
            for: indexPath) as? GridCell
          else {
            return UICollectionViewCell()
          }
          // cell setting
          cell.settingCellBase(asset: asset,
                               cellWidth: cellWidth)
          
          cell.imageManager = parent.imageManager
          if let image = self.parent.sampleImages[asset.id] {
            DispatchQueue.main.async {
              cell.imageView.image = image
            }
          } else {
            parent.imageManager
              .requestImage(
                for: asset.phAsset,
                targetSize: CGSize(width: cellWidth * scale,
                                   height: cellWidth * scale),
                contentMode: .aspectFill,
                options: requestOptions,
                resultHandler: { image, _ in
                  guard cell.id == asset.id,
                        let image = image
                  else { return }
                  DispatchQueue.main.async {
                    withAnimation {
                      cell.imageView.image = image
                    }
  //                  self.parent.sampleImages
  //                    .updateValue(image, forKey: asset.id)
                  }
              })
          }
          let checkList: [MLAsset] = switch parent.isUnionMode {
          case true: Array(Set(self.parent.selectedItems)
            .union(Set(self.parent.swipeSelectedItems)))
          case false: Array(Set(self.parent.selectedItems)
            .subtracting(Set(self.parent.swipeSelectedItems)))
          }
          cell.settingCell(
            isVideoCell: isVideo,
            isSelected: checkList.contains(cell.asset),
            isVolumeView: parent.filtering.sort == .byVolume)
          return cell
        case .btnAdd:
          guard let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "PickerCell",
                                 for: indexPath) as? GridCell
          else {
            return UICollectionViewCell()
          }
          cell.settingPickerCell(
            cellWidth: cellWidth,
            isHidden: parent.isSelectMode)
          return cell
        }
      })
    parent.fetchLoad {
      print("[\(self.parent.mlAlbum.title)] CollectionView Initial Loading done")
    }
  }
}

//#Preview {
//    NewPhotosCollectionView()
//}

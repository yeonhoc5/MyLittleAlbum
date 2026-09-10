//
//  PhotosGridMenu.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos

enum LabelType {
  case text, image
}

enum FilterZero: Identifiable, Hashable, CaseIterable {
  var id: Int { return self.hashValue }
  case allMedia, allAlbums, currentAlbum
  
  static func string(type: Self) -> String {
    return switch type {
    case .allMedia: "모든 항목"
    case .allAlbums: "전체 앨범의 항목들 제외"
    case .currentAlbum: "현재 앨범의 항목들 제외"
    }
  }
}
enum FilterFirst: Identifiable, Hashable, CaseIterable {
  var id: Int { return self.hashValue }
  case allMedia, image, video
  
  static func trueType(type: Self) -> PHAssetMediaType {
    switch type {
    case .image: return .image
    case .video: return .video
    default: return .image
    }
  }
}
enum FilterSecond: Identifiable, Hashable, CaseIterable {
  var id: Int { return self.hashValue }
  case all, favorite, screenshot
}
enum SortType: Identifiable, Hashable, CaseIterable {
  var id: Int { return self.hashValue }
  case byVolume, byDate
  static func typeTitle(type: Self) -> String {
    switch type {
    case .byDate: return "날짜순"
    case .byVolume: return "용량순"
    }
  }
  static func typeImage(type: Self) -> String {
    switch type {
    case .byDate: return "calendar"
    case .byVolume: return "greaterthan.square.fill"
    }
  }
}
enum FilteringType: Identifiable, Hashable, CaseIterable {
  var id: Int { return self.hashValue }
  var titleText: String {
    return switch self {
    case .all: "전체 보기"
    case .favorite: "즐겨찾기만 보기"
    case .video: "동영상만 보기"
    case .image: "사진만 보기"
    case .byVolume: "용량순으로 보기"
    }
  }
  var imageText: String {
    return switch self {
    case .all: ""
    case .favorite: iconFavorite
    case .video: iconVideo
    case .image: iconImage
    case .byVolume: "arrowtriangle.down.fill"
    }
  }
  case all, video, image, favorite, byVolume // contextMenu에서 아래부터 순서대로
  
  static func trueType(type: Self) -> PHAssetMediaType {
    switch type {
    case .image: return .image
    case .video: return .video
    default: return .image
    }
  }
}
enum BelongingType: CaseIterable, Identifiable {
  case album, all, nonAlbum
  var id: Self { self }
  
  static func stringType(type: Self) -> String {
    switch type {
    case .nonAlbum: return "앨범에 없는 항목 모음"
    case .album: return "앨범에 있는 항목 모음"
    default: return "모든 항목"
    }
  }
}

struct PhotosGridMenu: View {
  @EnvironmentObject var photoData: MLPhotoData
  @ObservedObject var mlAlbum: MLAlbum
  @Binding var isShowingPhotosPicker: Bool
  let albumType: AlbumType
  let isHiddenAssets: Bool
  let assetArray: (all: [MLAsset], filtered: [MLAsset])
  // view State
  @Binding var edgeToScroll: EdgeToScroll
  @Binding var isShowingFilter: Bool
  @Binding var isReadyVolumeSort: Bool
  @Binding var isReadyHiddenAsset: Bool
  @Binding var showHiddenAssets: Bool
  // selectMode
  @Binding var isSelectMode: Bool
  @Binding var selectedItems: [MLAsset]
  @Binding var isSelectingBySwipe: Bool
  @Binding var isUnionMode: Bool
  @Binding var swipeSelectedItems: [MLAsset]
  // view Redraw
  @Binding var filtering: Filtering
  @Binding var reLoadingType: ReLoadingType
  
  @Binding var assetAlert: AssetAlert!
  @Binding var moveAssetObject: MoveAssetObject!
  @Binding var isShowingMoveAssetSheet: Bool
  @State var isShowingDigitalShow: Bool = false
  @Binding var showEmptyNoticeView: Bool
  @Binding var isPhotosView: Int
  let nameSpace: Namespace.ID
  let allPhotosNamespace: Namespace.ID
  let width: CGFloat
  let unitCount = 9.0
  let spacing: CGFloat = 8
  let opacity: CGFloat = 0.8
  let selectedRadius: CGFloat = 10
  
  let readyCount: Int
  let knockCount: Int
  let knocking: () -> Void
  let sortByVolume: () -> Void
  let completion: ([MLAsset]) -> Void
  @State var shareURL: [URL] = []
  
  
  var body: some View {
    let miniSize = ((width / ((device == .pad && albumType != .picker) ? 2 : 1)) - (2 * spacing)) / unitCount
    HStack(spacing: spacing, content: {
      // left mini
      VStack(alignment: .leading, spacing: spacing) {
        btnLeftTop(albumType: albumType,
                   isSelectMode: isSelectMode,
                   miniSize: miniSize)
        btnLeftBottom(albumType: albumType,
                      isSelectMode: isSelectMode,
                      miniSize: miniSize)
      }
      .frame(width: abs(miniSize))
      // center
      VStack(spacing: spacing) {
        centerTop(albumType: albumType,
                  isSelectMode: isSelectMode,
                  isHiddenAssets: isHiddenAssets,
                  mini: miniSize)
        btnCenterBottom(albumType: albumType,
                        isSelectMode: isSelectMode,
                        isHiddenAssets: isHiddenAssets)
      }
      // right mini
      VStack(spacing: spacing) {
        btnRightTop(albumType: albumType,
                    isSelectMode: isSelectMode,
                    miniSize: miniSize)
        .overlay(alignment: .bottomTrailing) {
          if isShowingFilter {
            filterView(width: width - (15 + miniSize + spacing))
              .matchedGeometryEffect(id: "filter",
                                     in: allPhotosNamespace)
              .offset(y: -(tabbarHeight + spacing) / 2)
          }
        }
        btnRightBottom(albumType: albumType,
                       isSelectMode: isSelectMode)
      }
      .frame(width: abs(miniSize))
    })
    .tabBarLayout(height: tabbarHeight,
                  screenWidth: width,
                  albumType: albumType,
                  isPhotosView: true,
                  sidePadding: true,
                  padEdge: .trailing)
    .onAppear(perform: {
      dispatchAnimation {
        isPhotosView += device != .phone ? 1 : 0
      }
    })
    .animation(.easeInOut, value: isSelectMode)
    .onReceive(NotificationCenter.default
      .publisher(for: .endDigitalShow)) { _ in
        dispatchAnimation {
          isShowingDigitalShow = false
        }
      }
      .opacity(isShowingDigitalShow ? 0 : 1)
  }
}

extension PhotosGridMenu {
  func filterView(width: CGFloat) -> some View {
    let albumType = albumType
    let count = albumType == .album || albumType == .share ? 0 : 1
    let isPad = device == .pad
    let defaultValue = filtering == Filtering()
    return ZStack {
      backgroundView(isPad: isPad)
      VStack(spacing: 20) {
        VStack(alignment: .leading) {
          filterTitle(title: "필터")
          Group {
            if albumType == .home || albumType == .picker {
              filterZeroView(albumType: albumType, count: count)
              Divider()
            }
            filterFirstView(count: count)
            Divider()
            filterSecondView(count: count)
          }
        }
        if albumType == .album {
          VStack {
            filterTitle(title: "정렬")
            sortView()
          }
        }
        btnDefaultFilter(isDefault: defaultValue)
          .padding(.top, 20)
          .opacity(defaultValue ? 0.4 : 1)
      }
      .padding(30)
    }
    .frame(width: width - (spacing * 2))
  }
  func filterSectionView(count: Int, string: String) -> some View {
    HStack(spacing: 1) {
      Text("Filter")
      Text(string).fontWeight(.heavy)
    }
    .font(.caption)
    .frame(height: 10)
    .padding(3)
    .background(content: {
      RoundedRectangle(cornerRadius: 2)
        .stroke(style: .init(lineWidth: 0.9,
                             lineCap: .round,
                             lineJoin: .round))
    })
    .foregroundStyle(Color.fancyBackground)
    .padding(.leading, 3)
  }
  func filterZeroView(albumType: AlbumType, count: Int) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      filterSectionView(count: count, string: "A")
      HStack(content: {
        customButtonView(image: "books.vertical.fill",
                         title1: "전체 앨범",
                         title2: "미디어 제외",
                         selected: filtering.zero == .allAlbums) {
          withAnimation {
            if filtering.zero != .allAlbums {
              changeFiltering(z: (true, .allAlbums))
            } else {
              changeFiltering(z: (true, .allMedia))
            }
          }
        }
        if albumType == .picker {
          customButtonView(image: "character.book.closed",
                           title1: "현재 앨범",
                           title2: "미디어 제외",
                           selected: filtering.zero == .currentAlbum) {
            withAnimation {
              if filtering.zero != .currentAlbum {
                changeFiltering(z: (true, .currentAlbum))
              } else {
                changeFiltering(z: (true, .allMedia))
              }
            }
          }
        }
      })
      .background {
        HStack {
          if albumType == .picker
              && filtering.zero == .currentAlbum {
            Rectangle().foregroundStyle(.clear)
          }
          selectedMark
            .opacity(filtering.zero != .allMedia
                     ? 1 : 0)
          if albumType == .picker && filtering.zero == .allAlbums {
            Rectangle().foregroundStyle(.clear)
          }
        }
      }
    }
  }
  func filterFirstView(count: Int) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      filterSectionView(count: count+1, string: "B")
      HStack {
        customButtonView(image: "photo",
                         title1: "사진만",
                         title2: "보기",
                         selected: filtering.first == .image) {
          dispatchAnimation {
            if filtering.first != .image {
              changeFiltering(f: (true, .image))
            } else {
              changeFiltering(f: (true, .allMedia))
            }
          }
        }
        customButtonView(image: "video.fill",
                         title1: "비디오만",
                         title2: "보기",
                         selected: filtering.first == .video) {
          dispatchAnimation {
            if filtering.first != .video {
              changeFiltering(f: (true, .video))
            } else {
              changeFiltering(f: (true, .allMedia))
            }
          }
        }
      }
      .background {
        HStack(spacing: 0) {
          if filtering.first == .video {
            Rectangle().foregroundStyle(.clear)
          }
          selectedMark
            .opacity(filtering.first != .allMedia ? 1 : 0)
          if filtering.first == .image {
            Rectangle().foregroundStyle(.clear)
          }
        }
      }
    }
  }
  func filterSecondView(count: Int) -> some View {
    let second = filtering.second
    return VStack(alignment: .leading, spacing: 5) {
      filterSectionView(count: count+2, string: "C")
      HStack {
        customButtonView(image: "star.fill",
                         title1: "즐겨찾기만",
                         title2: "보기",
                         selected: second == .favorite) {
          withAnimation {
            if second == .favorite {
              changeFiltering(s: (true, .all))
            } else {
              changeFiltering(s: (true, .favorite))
            }
          }
        }
        customButtonView(image: "camera.viewfinder",
                         title1: "스크린샷만",
                         title2: "보기",
                         selected: second == .screenshot) {
          withAnimation {
            if second == .screenshot {
              changeFiltering(s: (true, .all))
            } else {
              changeFiltering(s: (true, .screenshot))
            }
          }
        }
      }
      .background {
        HStack(spacing: 0) {
          if second == .screenshot {
            Rectangle().foregroundStyle(.clear)
          }
          selectedMark.opacity(second != .all ? 1 : 0)
          if second == .favorite {
            Rectangle().foregroundStyle(.clear)
          }
        }
      }
      
    }
  }
  func sortView() -> some View {
    HStack {
      ForEach(SortType.allCases) { sort in
        let ready = sort == .byDate ? true
        : (filtering.sort == .byDate ? true : isReadyVolumeSort)
        customButtonView(
          image: SortType.typeImage(type: sort),
          isReady: ready,
          title1: "\(SortType.typeTitle(type: sort))",
          title2: "보기",
          selected: filtering.sort == sort) {
            dispatchAnimation {
              if filtering.sort != sort {
                changeFiltering(t: (true, sort))
              }
              self.isShowingFilter = false
            }
            if sort == .byVolume {
              sortByVolume()
            }
          }
      }
    }
    .background {
      HStack(spacing: 0) {
        if filtering.sort == .byDate {
          Rectangle().foregroundStyle(.clear)
        }
        selectedMark
        if filtering.sort == .byVolume {
          Rectangle().foregroundStyle(.clear)
        }
      }
    }
  }
  func filterTitle(title: String) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 5)
        .foregroundStyle(Color.fancyBackground.opacity(0.8))
      Text(title)
        .foregroundStyle(.white)
    }
    .frame(height: 25)
    .padding(.bottom, 10)
  }
  var selectedMark: some View {
    Group {
      if #available(iOS 26, *) {
        RoundedRectangle(cornerRadius: selectedRadius)
          .foregroundStyle(.clear)
          .glassEffect26 { view in
            view
          }
      } else {
        RoundedRectangle(cornerRadius: selectedRadius)
          .foregroundStyle(.gray)
      }
    }
  }
  func backgroundView(isPad: Bool) -> some View {
    let radius: CGFloat = 15
    return RoundedRectangle(cornerRadius: radius)
      .availabeGlassEffect(cornerR: radius,
                           foreground: .ultraThinMaterial) { view in
        view
          .foregroundStyle(.ultraThinMaterial)
      }
  }
  
  func customButtonView(image: String,
                        isReady: Bool = true,
                        title1: String,
                        title2: String,
                        selected: Bool,
                        action: @escaping () -> Void) -> some View {
    Button {
      action()
    } label: {
      ZStack {
        Rectangle().foregroundStyle(.clear)
          .matchedGeometryEffect(id: title1, in: allPhotosNamespace)
          .frame(height: 45)
        HStack {
          if isReady {
            Image(systemName: image)
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)
          } else {
            ProgressView()
              .progressViewStyle(.circular)
          }
          VStack {
            Text(title1)
            if title2 != "" {
              Text(title2)
            }
          }
          .matchedGeometryEffect(id: title1+title2+"sort",
                                 in: nameSpace)
          .font(.caption)
        }
        .foregroundStyle(.white.opacity(selected ? 1 : 0.9))
        .padding(5)
      }
    }
  }
  
  func btnLeftTop(albumType: AlbumType,
                  isSelectMode: Bool,
                  miniSize: CGFloat) -> some View {
    Group {
      if albumType == .album && !isHiddenAssets {
        FlipViewTransitor(isModeChange: isSelectMode) {
          btnPlus
        } flipReverseView: {
          btnDelete
        }
      } else if albumType == .home {
        scaleTransitionView(condition: isSelectMode) {
          btnDelete
        }
      } else {
        emptySpace(size: .mini)
      }
    }
  }
  
  func scaleTransitionView(condition: Bool, btn: @escaping () -> some View, size: ButtonSize = .mini) -> some View {
    Group {
      if condition {
        btn()
          .transition(.scale)
      } else {
        emptySpace(size: size)
      }
    }
  }
  func btnLeftBottom(albumType: AlbumType, isSelectMode: Bool, miniSize: CGFloat) -> some View {
    Group {
      if albumType != .picker {
        FlipViewTransitor(isModeChange: isSelectMode) {
          btnDigitalShow(width: miniSize)
        } flipReverseView: {
          btnHideUnhide(!isHiddenAssets)
        }
      } else  {
        emptySpace(size: .mini)
      }
    }
  }
  func centerTop(albumType: AlbumType,
                 isSelectMode: Bool,
                 isHiddenAssets: Bool,
                 mini: CGFloat) -> some View {
    Group {
      switch albumType {
      case .picker:
        btnAddOnPhotosPicker()
      default:
        if !showEmptyNoticeView {
          centerMenuBar(isSelectMode: isSelectMode, mini: mini)
            .matchedGeometryEffect(id: "centerCardView",
                                   in: nameSpace)
            .onTapGesture(count: 3) {
              if !isSelectMode && !isHiddenAssets {
                knocking()
              }
            }
            .modify { view in
              if #available(iOS 18.0, *) {
                view
                  .matchedTransitionSource(id: "centerCardView",
                                           in: nameSpace)
              } else {
                view
              }
            }
        } else {
          emptySpace(size: .big)
        }
      }
    }
  }
  func btnDigitalShow(width: CGFloat) -> some View {
    let disable = isShowingFilter
                  || assetArray.filtered.isEmpty
    let color: Color = disable ? .gray.opacity(0.5) : .black
    var symbol: String = ""
    if #available(iOS 17, *) {
      symbol = "play.square.stack"
    } else {
      symbol = "play.square"
    }
    return ZStack {
      if !isShowingDigitalShow {
        roundedRectangleBG { radius in
          RoundedRectangle(cornerRadius: radius)
        }
        .matchedGeometryEffect(id: "digitalShow", in: nameSpace)
      }
      menuButton(type: .image,
                 image: symbol,
                 color: color,
                 bgColor: .clear,
                 disabled: disable) {
        let digitalShowObject = DigitalShowObject(
          digitalShowRandom: photoData.digitalShowRandom,
          transitionSecond: transitionRange[photoData.transitionIndex],
          assetArray: photoData.digitalShowRandom
          ? assetArray.filtered.shuffled()
          : assetArray.filtered,
          digitalShowTitle: mlAlbum.title,
          nameSpace: nameSpace)
        withAnimation {
          isShowingDigitalShow = true
        }
        NotificationCenter.default
          .post(name: .showDigitalShow, object: digitalShowObject)
      }
    }
  }
  func btnCenterBottom(albumType: AlbumType,
                       isSelectMode: Bool,
                       isHiddenAssets: Bool) -> some View {
    FlipViewTransitor(isModeChange: isSelectMode) {
      HStack(spacing: spacing) {
        btnScrollToEdge(edge: .bottom)
        btnScrollToEdge(edge: .top)
      }
    } flipReverseView: {
      HStack(spacing: spacing) {
        switch albumType {
        case .picker:
          btnScrollToEdge(edge: .bottom)
          btnScrollToEdge(edge: .top)
        default:
          if albumType == .album {
            btnTakeFrom()
          }
          if albumType != .share {
            btnMove(albumType: albumType) {
              let moveAssetObject = MoveAssetObject(
                albumType: albumType,
                currentAlbumID: mlAlbum.id,
                selectedItems: selectedItems,
                isHidden: isHiddenAssets
              )
              dispatchAnimation {
                self.moveAssetObject = moveAssetObject
                self.isShowingMoveAssetSheet = true
              }
            }
          }
          btnFavorite()
        }
      }
    }
  }
  
  func btnRightTop(albumType: AlbumType,
                   isSelectMode: Bool,
                   miniSize: CGFloat) -> some View {
    let modeChange = albumType == .picker
                    ? !selectedItems.isEmpty
                    : isSelectMode
    return FlipViewTransitor(isModeChange: modeChange) {
      btnFilter(miniSize: miniSize)
    } flipReverseView: {
      Group {
        if albumType == .home || albumType == .picker {
          btnDeselectInPicker
        } else {
          btnSelectAll(assetArray: assetArray.filtered)
        }
      }
    }
  }
  func btnRightBottom(albumType: AlbumType,
                      isSelectMode: Bool) -> some View {
    Group {
      if albumType == .picker {
        btnClose
      } else {
        FlipViewTransitor(isModeChange: isShowingFilter) {
          btnToggleSelectMode(assetArray: assetArray.filtered)
        } flipReverseView: {
          btnClose
        }
      }
    }
  }
}

// MARK: - 포토 그리드 공통 버튼
extension PhotosGridMenu {
  // 0. 가운데 라벨바
  func centerMenuBar(isSelectMode: Bool, mini: CGFloat) -> some View {
      GeometryReader { geo in
        ZStack {
          Capsule()
            .availabeGlassEffect(
              cornerR: geo.size.height / 2,
              foreground: .thinMaterial.opacity(0.85)) { view in
              view
                .foregroundStyle(.ultraThinMaterial)
            }
          if mlAlbum.innerProcessing || isReadyHiddenAsset {
            Capsule()
              .foregroundStyle(.blue.opacity(0.65))
          }
          if isReadyHiddenAsset {
            generatingMessage
              .onAppear {
                goHiddenAssets()
              }
          } else {
            contentView(isSelectMode: isSelectMode)
          }
        }
        .frame(width: geo.size.width, height: geo.size.height)
      }
  }
  func contentView(isSelectMode: Bool) -> some View {
    FlipViewTransitor(isModeChange: isSelectMode) {
      contentCounterView()
    } flipReverseView: {
      selectedCounterView()
    }
    .font(.system(.subheadline,
                  design: .rounded,
                  weight: .medium)
    )
    .foregroundColor(.white)
  }
  func contentCounterView() -> some View {
    let imageCount = assetArray.all
      .filter { $0.mediaType == .image }.count
    let videoCount = assetArray.all
      .filter { $0.mediaType == .video }.count
    return HStack(spacing: knockCount > 0 ? 10 : 5) {
      if isHiddenAssets {
        Text("가려진")
      }
      FlipViewTransitor(isModeChange: knockCount >= 2) {
        Text("사진 : \(imageCount)")
      } flipReverseView: {
        Text("Knock!")
          .foregroundStyle(Color.color1)
      }.fixedSize()
      ZStack {
        FlipViewTransitor(isModeChange: knockCount >= 1) {
          Text(" / ")
        } flipReverseView: {
          Text("Knock!")
            .foregroundStyle(Color.color1)
        }
        if mlAlbum.innerProcessing {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .padding(.horizontal, 7.5)
            .contentTransition(.interpolate)
        }
      }
      FlipViewTransitor(isModeChange: knockCount >= 3) {
        Text("비디오 : \(videoCount)")
      } flipReverseView: {
        Text("Knock!")
          .foregroundStyle(Color.color1)
      }
      .fixedSize()
    }
  }
  func selectedCounterView() -> some View {
    let selectedCount = Array(
      isUnionMode
      ? Set(selectedItems).union(Set(swipeSelectedItems))
      : Set(selectedItems).subtracting(Set(swipeSelectedItems))
    ).count
    return HStack(spacing: 0) {
      Text("\(selectedCount)")
        .font(.system(.subheadline,
                      design: .monospaced,
                      weight: .medium))
        .contentTransition(.numericText())
        .animation(.linear, value: selectedCount)
      Text("개의 항목 ")
      Group {
        if mlAlbum.innerProcessing {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .padding(.horizontal, 7.5)
        } else {
          Text("선택됨")
        }
      }
      .transition(.scale)
    }
  }
  
  var generatingMessage: some View {
    HStack {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)
      Text("Generating...")
        .foregroundStyle(.white)
    }
  }
  func goHiddenAssets() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      withAnimation {
        self.showHiddenAssets = true
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      self.isReadyHiddenAsset = false
    }
  }
  func makeShareURL() {
    let assets = selectedItems.map(\.phAsset)
    AssetShareManager.shared
      .prepareAssetForSharing(assets) { urls in
        self.shareURL = urls
      }
  }
  func changeFiltering(z: (Bool, FilterZero) = (false, .allAlbums),
                       f: (Bool, FilterFirst) = (false, .allMedia),
                       s: (Bool, FilterSecond) = (false, .all),
                       t: (Bool, SortType) = (false, .byDate)){
    if z.0 {
      self.filtering.zero = z.1
    }
    if f.0 {
      self.filtering.first = f.1
    }
    if s.0 {
      self.filtering.second = s.1
    }
    if t.0 {
      self.filtering.sort = t.1
    }
  }
  // 1. show PhotoPickerView : album
  var btnPlus: some View {
    let disable = isSelectMode || isShowingFilter
    return menuButton(type: .image,
                      image: "plus",
                      color: .white,
                      bgColor: disable ? .color6 : .blue,
                      disabled: disable) {
//      dispatchAnimation {
//        self.isShowingPhotosPicker = true
//      }
      DispatchQueue.main.async {
//              self.parent.isShowingPhotosPicker = true
        NotificationCenter.default
          .post(name: .showPhotosPicker,
                object: self.mlAlbum.id)
      }
    }
    .fontWeight(.medium)
  }
  func btnDefaultFilter(isDefault: Bool) -> some View {
    menuButton(type: .text,
               text: "기본값 보기",
               color: .fancyBackground,
               bgColor: .white,
               disabled: isDefault,
               disabledColor: .fancyBackground,) {
      dispatchAnimation {
        self.filtering = Filtering()
        self.isShowingFilter = false
      }
    }
   .frame(height: 40)
  }
  // 선택 모드 토글 버튼
  func btnToggleSelectMode(assetArray: [MLAsset]) -> some View {
    let text = isSelectMode ? "취소" : "선택"
    let disabled = assetArray.isEmpty || isShowingFilter
    return menuButton(type: .text, text: text, disabled: disabled) {
      dispatchAnimation {
        isSelectMode.toggle()
        self.reLoadingType = .selectedModeChange
      }
    }
  }
  // 전체 선택 / 해제 버튼
  func btnSelectAll(assetArray: [MLAsset]) -> some View {
    let disable = assetArray.isEmpty
    let isSelectedAll = selectedItems.count
                        == assetArray.count
    let text = "전체\n\(isSelectedAll ? "해제" : "선택")"
    return menuButton(type: .text,
                      text: text,
                      disabled: disable) {
      if isSelectedAll {
        dispatchAnimation {
          reLoadingType = .deselectAll
        }
      } else {
        dispatchAnimation {
          reLoadingType = .selectAll
        }
      }
    }
    .contentTransition(.numericText())
  }
  var btnDeselectInPicker: some View {
    let disable = selectedItems.isEmpty
    return menuButton(type: .text,
                      text: "선택\n해제",
                      color: disable ? .gray.opacity(0.5) : .black,
                      disabled: disable) {
//      viewState.changeReloadType(.deselectAll)
      dispatchAnimation {
        reLoadingType = .deselectAll
      }
    }
  }
  
  // 디지털 액자 버튼
  func btnDigitalShow(assetArray: [MLAsset]) -> some View {
    let disable = assetArray.isEmpty || isShowingFilter
    let color: Color = disable ? .gray.opacity(0.5) : .black
    var symbol: String = ""
    if #available(iOS 17, *) {
      symbol = "play.square.stack"
    } else {
      symbol = "play.square"
    }
    return menuButton(type: .image,
                      image: symbol,
                      color: color,
                      bgColor: isShowingDigitalShow ? .clear : .white,
                      disabled: disable) {
      let digitalShowObject = DigitalShowObject(
        digitalShowRandom: photoData.digitalShowRandom,
        transitionSecond: transitionRange[photoData.transitionIndex],
        assetArray: photoData.digitalShowRandom ? assetArray.shuffled() : assetArray,
        digitalShowTitle: mlAlbum.title,
        nameSpace: nameSpace)
      withAnimation {
        isShowingDigitalShow = true
      }
      NotificationCenter.default
        .post(name: .showDigitalShow, object: digitalShowObject)
    }
  }
  // 스크롤 버튼
  func btnScrollToEdge(edge: EdgeToScroll) -> some View {
    let image = edge == .top ? "chevron.left.to.line" : "chevron.right.to.line"
    return menuButton(type: .image, image: image, rotate: .pi/2) {
      dispatchAnimation {
        self.edgeToScroll = edge
      }
    }
  }
  func roundedRectangleBG<Content: View>(content: @escaping (CGFloat) -> Content) -> some View {
    GeometryReader { geometry in
      let radius = geometry.size.height / 2
      content(radius)
        .shadow(color: Color.fancyBackground.opacity(0.5),
                radius: 2, x: 0, y: 0)
        .foregroundStyle(.white.opacity(0.9))
    }
  }
  
  // 필터링
  func btnFilter(miniSize: CGFloat) -> some View {
    let disable = (!selectedItems.isEmpty)
    || (isHiddenAssets ? mlAlbum.hiddenArray.isEmpty
                      : mlAlbum.photosArray.isEmpty)
    let first = filtering.first
    let second = filtering.second
      return Button {
        DispatchQueue.main.async {
          withAnimation(.bouncy(duration: 0.3)) {
            self.isShowingFilter.toggle()
          }
        }
      } label: {
        let filterFirstImage = switch first {
          case .image: "photo.fill"
          case .video: "video.fill"
        default: "line.3.horizontal.decrease"
        }
        let filterSecondImage = switch second {
        case .favorite: "star.fill"
        case .screenshot: "viewfinder.rectangular"
        default: "line.3.horizontal.decrease"
        }
        ZStack(alignment: .center) {
          if !isShowingFilter {
            roundedRectangleBG { radius in
              RoundedRectangle(cornerRadius: radius)
                .matchedGeometryEffect(id: "filter", in: allPhotosNamespace)
            }
          } else {
            Capsule()
              .stroke(lineWidth: 1)
              .foregroundStyle(.white.opacity(0.2))
              .shadow(color: Color.fancyBackground.opacity(0.5),
                      radius: 2, x: 0, y: 0)
          }
          Group {
            imageWithScale(systemName: filterFirstImage)
              .imageScale(.medium)
              .contentTransition(.symbolEffect(.replace))
              .scaleEffect(second == .screenshot ? 0.8 : 1)
              .foregroundStyle(
                first != .allMedia
                ? .blue : (disable ? .gray.opacity(0.5)
                           : (isShowingFilter
                              ? .white : .black)))
              .opacity((first == .allMedia && second != .all) ? 0 : 1)
            imageWithScale(systemName: filterSecondImage)
              .matchedGeometryEffect(id: "star", in: nameSpace)
              .foregroundStyle(first == .allMedia
                               ? .blue
                               : (second == .favorite
                                  ? .white.opacity(0.8)
                                  : isShowingFilter ? .white : .lightGray))
              .fontWeight(second == .favorite ? .heavy : .regular)
              .scaleEffect(first == .allMedia
                           ? 1
                           : (second == .screenshot
                              ? 1.3 :  0.45))
              .opacity(second != .all ? 1 : 0)
              .offset(x: second == .favorite
                      ? (first == .allMedia
                         ? 0
                         : (first == .video ? -2 : -3.6)) : 0,
                      y: second == .favorite
                              ? ( first == .image ? -2 : 0) : 0)
          }
        }
      }
      .disabled(disable)
  }
  // 앨범명 수정
  func btnFavorite() -> some View {
    let disable = selectedItems.isEmpty
    let toFavorite = disable
                    || !selectedItems
                        .filter { !$0.isFavorite }
                        .isEmpty
    let icon = toFavorite ? iconFavorite : iconUnfavorite
    let assets = selectedItems
                  .filter { $0.isFavorite != toFavorite }
    return menuButton(type: .image, image: icon, disabled: disable ) {
      mlAlbum.favoriteAsset(toFavorite: toFavorite,
                            assets: assets,
                            isHiddenAsset: self.isHiddenAssets) { bool in
        if bool {
          dispatchAnimation {
            self.isSelectMode = false
            self.reLoadingType = .itemChangedInside
          }
        }
        mlAlbum.processingChange(bool: false)
      }
    }
  }
}

//MARK: - 선택한 사진 처리 버튼 정의
extension PhotosGridMenu {
  // 삭제
  var btnDelete: some View {
    let disable = selectedItems.isEmpty
    let bgColor: Color = disable ? .color4 : .red
    return menuButton(type: .image,
                      image: "trash",
                      color: .white,
                      bgColor: bgColor,
                      disabled: disable,
                      disabledColor: .white.opacity(0.5)) {
      deleteAsset(selected: selectedItems)
    }
  }
  // 앨범에서 빼기
  func btnTakeFrom() -> some View {
    let disable = selectedItems.isEmpty
    return menuButton(type: .text, text: "앨범에서 빼기", disabled: disable) {
      mlAlbum.processingChange(bool: true)
      let assetAlert = AssetAlert(alertCase: .subtract,
                                  assets: selectedItems,
                                  album: mlAlbum,
                                  isHiddenAsset: isHiddenAssets)
      dispatchAnimation {
        self.assetAlert = assetAlert
      }
      //            mlAlbum.processingChange(bool: true)
      //            let alertObject = AlertObject(alertCase: .mediaTakeFromAlbum,
      //                                          album: mlAlbum.phAssetCollection,
      //                                          folder: nil,
      //                                          selectedItems: selectedItems,
      //                                          isHiddenAsset: isHiddenAssets)
      //            DispatchQueue.main.async {
      //                NotificationCenter.default
      //                    .post(name: .showAlertInCollectionView, object: alertObject)
      //            }
    }
  }
  func btnShareImage(mini: CGFloat, height: CGFloat) -> some View {
    Image(systemName: "arrowshape.turn.up.right.fill")
      .foregroundStyle(.white)
      .frame(width: mini, height: height)
      .glassEffect26 { view in
        view
      }
  }
  
  // 공유 버튼
  func btnShare(mini: CGFloat, height: CGFloat) -> some View {
    ShareLink(items: shareURL) {
      btnShareImage(mini: mini, height: height)
      
      //      buttonLabel(type: .image,
      //                  image: "arrowshape.turn.up.right.fill",
      //                  font: .caption,
      //                  disabled: false)
      //    }
      //    .disabled(selectedItems.isEmpty)
    }
  }
  // 복구 버튼
  func btnRestore() -> some View {
    let disable = selectedItems.isEmpty
    return menuButton(type: .text,
                      text: "복구하기",
                      disabled: disable) {
      PHPhotoLibrary.shared().performChanges {
        
      }
    }
  }
  
  func assetsToShare(assets: [MLAsset]) -> [Photo] {
//    let imageManager = PHImageManager()
//    let images = assets.map {
//      imageManager.requestImage(for: $0.phAsset,
//                                targetSize: PHImageManagerMaximumSize,
//                                contentMode: .aspectFit,
//                                options: nil) { image, info in
//        if let image = image {
//          image
//        }
//      }
//    }
//    return images
    var assetsToShare: [Photo] = []
//    let imageManager = PHImageManager.default()
//    for photo in assets {
//      let asset = photo.phAsset
//      let resource = PHAssetResource.assetResources(for: asset)
//        let fileName = resource.first?.originalFilename
//        let options = PHImageRequestOptions()
//        options.isSynchronous = true
//        options.resizeMode = .none
//      getURL(ofPhotoWith: asset) { responseURL in
//            guard let url = responseURL?.absoluteURL else { return }
//            print(url)
//            imageManager
//          .requestImage(for: asset,
//                        targetSize: PHImageManagerMaximumSize,
//                        contentMode: .default,
//                        options: options) { image, info in
//                if let image = image {
//                    let photoAsset = Photo(
//                      image: Image(uiImage: image),
//                      caption: fileName ?? "",
//                      url: url )
//                    assetsToShare.append(photoAsset)
//                }
//            }
//            print("공유하려는 사진 info: \(assetsToShare.count)")
//        }
//    }
//    print(assetsToShare.count)
    return assetsToShare
  }
  
  // 1-1. album: 어셋 이동 시트 열기
  // 1-2. home: 어셋 이동 시트 열기
  // 2. picker: 현재 앨범에 넣기
  func btnAddOnPhotosPicker() -> some View {
    let notSelected = self.selectedItems.isEmpty
    let text = notSelected
    ? "선택한 항목 없음"
    : "\(self.selectedItems.count)개의 항목 이 앨범에 넣기"
    return menuButton(type: .text,
                      text: text,
                      color: .white,
                      bgColor: notSelected ? .addButton : .blue,
                      disabled: notSelected) {
      completion(selectedItems)
    }
    
  }
  func btnMove(albumType: AlbumType, onTapped: @escaping () -> Void) -> some View {
    let disable = selectedItems.isEmpty
    let textColor: Color
    let bgColor: Color
    let text = switch albumType {
    case .home: "앨범에 넣기"
    case .album: "다른 앨범으로 이동하기"
    default: selectedItems.isEmpty
      ? "선택한 항목 없음"
      : "\(selectedItems.count)개의 항목 이 앨범에 넣기"
    }
    switch albumType {
    case .home, .album:
      textColor = disable ? .gray.opacity(0.5) : .black
      bgColor = .white
    default:
      textColor = .white
      bgColor = disable ? .addButton : .blue
    }
    return menuButton(type: .text, text: text,
                      color: textColor, bgColor: bgColor,
                      disabled: disable) {
      onTapped()
    }
    .disabled(selectedItems.isEmpty)
  }
  // 가리기 & 해제
  func btnHideUnhide(_ toHide: Bool) -> some View {
    let disable = selectedItems.isEmpty
    return menuButton(type: .image,
                      image: toHide ? iconHide : iconUnhide,
                      disabled: disable) {
      hideOrUnhideAsset(assets: selectedItems)
    }
  }
  // pickerView 닫기 버튼
  var btnClose: some View {
    menuButton(type: .image, image: "xmark") {
      if isShowingFilter {
        DispatchQueue.main.async {
          withAnimation(.bouncy(duration: 0.3)) {
            self.isShowingFilter.toggle()
          }
        }
      } else {
        DispatchQueue.main.async {
          completion([])
        }
      }
    }
  }
}

//MARK: - 사진 처리 함수
extension PhotosGridMenu {
  // 기기에서 삭제
  func deleteAsset(selected: [MLAsset]) {
    mlAlbum.processingChange(bool: true)
    mlAlbum
      .deleteAssetFromDevice(albumType: albumType,
                             assets: selectedItems,
                             isHiddenAsset: isHiddenAssets,
                             isDetailView: false) { bool in
        if bool {
          reFetchInside(needOutside: true)
        }
    }
  }
  
  enum AssetChanged {
    case delete, hidden, subtract, move, favorite
  }
  
  // 사진 가리기
  func hideOrUnhideAsset(assets: [MLAsset]) {
    mlAlbum.processingChange(bool: true)
    if !isHiddenAssets {
      // hide
      mlAlbum.hideOrUnhideAsset(assets: selectedItems,
                                toHide: !isHiddenAssets) { bool in
        if bool {
          reFetchInside(needOutside: true)
        }
      }
    } else {
      // unHide
      let assetAlert = AssetAlert(alertCase: .unHide,
                                  assets: selectedItems,
                                  album: mlAlbum,
                                  isHiddenAsset: true)
      dispatchAnimation {
        self.assetAlert = assetAlert
      }
//      let alertObject = AlertObject(
//        alertCase: .mediaUnhide,
//        folderType: .userFolder,
//        albumType: self.albumType,
//        albumID: mlAlbum.id,
//        folderID: nil,
//        title: mlAlbum.title,
//        selectedItems: selectedItems,
//        isHiddenAsset: true,
//        isDetailView: false)
//      DispatchQueue.main.async {
//        NotificationCenter.default
//          .post(name: .showAlertInCollectionView,
//                object: alertObject)
//      }
    }
  }
  
  func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
    if mPhasset.mediaType == .image {
      let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
      options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
        return true
      }
      mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
        completionHandler(contentEditingInput!.fullSizeImageURL)
      })
    } else if mPhasset.mediaType == .video {
      let options: PHVideoRequestOptions = PHVideoRequestOptions()
      options.version = .current
      options.deliveryMode = .highQualityFormat
      options.isNetworkAccessAllowed = true
      PHImageManager.default()
        .requestAVAsset(forVideo: mPhasset,
                        options: options,
                        resultHandler: { (asset, audioMix, info) in
          if let urlAsset = asset as? AVURLAsset {
            let localVideoUrl = urlAsset.url
            completionHandler(localVideoUrl)
          } else {
            completionHandler(nil)
          }
        })
    }
  }
  func emptySpace(size: ButtonSize) -> some View {
    buttonLabel(type: .text)
      .opacity(0)
      .disabled(true)
  }
  
}
// common funcs
extension PhotosGridMenu {
  func reFetchInside(needOutside: Bool = false) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      reLoadingType = .reFetchInside
      if needOutside && (albumType == .album
                         || albumType == .share) {
        NotificationCenter.default
          .post(name: .outsideFetchChange, object: "myPhotos")
      }
    }
  }
}

// MARK: - 버튼 레이아웃
extension PhotosGridMenu {
  // 공용 백그라운드 바
  func colorBar(opacity: CGFloat! = 0.9,
                color: Color! = .white) -> some View {
    Capsule().foregroundStyle(color.opacity(opacity))
  }
  
  func menuButton(type: LabelType,
                  text: String! = "",
                  image: String! = "",
                  rotate: Double! = 0.0,
                  font: Font! = .caption,
                  color: Color! = .black,
                  bgColor: Color! = .white,
                  disabled: Bool! = false,
                  disabledColor: Color! = .gray.opacity(0.5),
                  action: @escaping () -> Void) -> some View {
    Button {
      action()
    } label: {
      buttonLabel(type: type, text: text, image: image,
                  rotate: rotate,
                  font: font,
                  color: color, bgColor: bgColor,
                  disabled: disabled,
                  disabledColor: disabledColor)
      .animation(.easeInOut, // 없애지 말 것 : 선택한 셀이 0인지에 따라 전체 버튼 애니메이션 효과
                 value: selectedItems.isEmpty)
      .contentTransition(.numericText())
    }
    .disabled(disabled)
    .buttonStyle(ClickScaleEffect(scale: 0.95))
  }
  
  func buttonLabel(type: LabelType,
                   text: String! = "",
                   image: String! = "",
                   rotate: Double! = 0.0,
                   font: Font! = .caption,
                   color: Color! = .black,
                   bgColor: Color! = .white,
                   disabled: Bool! = false,
                   disabledColor: Color! = .gray.opacity(0.5)) -> some View {
    return ZStack(alignment: .center) {
      colorBar(color: bgColor)
        .shadow(color: Color.fancyBackground.opacity(0.5),
                radius: 2, x: 0, y: 0)
      switch type {
      case .text: Text(text)
          .font(font)
          .multilineTextAlignment(.center)
      case .image: imageWithScale(systemName: image)
          .imageScale(.medium)
          .rotationEffect(.radians(rotate))
      }
    }
    .foregroundStyle(disabled ? disabledColor : color)
  }
}

//struct PhotoMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotosGridMenu(isHome: false, album: nil, allPhotos: nil, isSelectMode: .constant(true), selectedItemsIndex: .constant([]), scrollEdge: .constant(.none), isShowingAlert: .constant(false), editType: .constant(.none), isShowingSheet: .constant(false), isShowingShareSheet: .constant(false))
//    }
//}

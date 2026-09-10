//
//  AlbumView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos

enum AlbumBoolChange {
  case settingview, editingMode, firstAppear, expand
}

class AlbumViewState: ObservableObject, Observable {
  @Published var isShowingSettingView: Bool = false
  @Published var isEditingMode: Bool = false
  @Published var firstAppear: Bool = true
  @Published var isExpanded: Bool = false
  
  func boolChange(_ state: AlbumBoolChange, bool: Bool! = nil) {
    DispatchQueue.main.async {
      switch state {
      case .settingview:
        withAnimation {
          if let bool = bool {
            self.isShowingSettingView = bool
          } else {
            self.isShowingSettingView.toggle()
          }
        }
      case .editingMode:
        withAnimation {
          if let bool = bool {
            self.isEditingMode = bool
          } else {
            self.isEditingMode.toggle()
          }
        }
      case .firstAppear:
        DispatchQueue.main.async {
          if let bool = bool {
            self.firstAppear = bool
          } else {
            self.firstAppear = false
          }
        }
      case .expand:
        withAnimation {
          if let bool = bool {
            self.isExpanded = bool
          } else {
            self.isExpanded.toggle()
          }
        }
      }
    }
  }
}


// 앨범 뷰
struct AlbumView: View {
    // 사진 데이터 프라퍼티
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var photoData: MLPhotoData
  @ObservedObject var pageFolder: MLFolder
  @StateObject var state = AlbumViewState()
  @Binding var isPhotosView: Int
  // UI 프라퍼티
  var pageIndex: Int = 0
  // 추가 뷰 프라퍼티
  @Binding var isShowingMessageView: Bool
  @Binding var tutorialOn: Bool
  // 애니메이션 프라퍼티
  var nameSpace: Namespace.ID
  @Namespace var albumViewNameSpace
  
  var body: some View {
    GeometryReader(content: { geometry in
      let width = geometry.size.width
      scrollViewWidthReader(showIndicator: true,
                            scrollDisalble: state.isShowingSettingView) { proxy in
        VStack(alignment: .leading, spacing: 0) {
          if pageFolder.id == "shareTop" {
            shareMessageView()
              .padding([.top, .horizontal], 10)
          }
          sectionView(section: .album,
                      count: pageFolder.albumsArray.count)
          AlbumListView(pageFolder: pageFolder,
                        isPhotosView: $isPhotosView,
                        pageIndex: pageIndex,
                        screenWidth: width,
                        isEditingMode: state.isEditingMode,
                        nameSpace: nameSpace,
                        albumViewNameSpace: albumViewNameSpace,
                        isUnfolded: state.isExpanded)
          sectionView(section: .folder,
                      count: pageFolder.foldersArray.count)
          FolderListView(pageFolder: pageFolder,
                         isPhotosView: $isPhotosView,
                         pageIndex: pageIndex,
                         screenWidth: width,
                         isEditingMode: state.isEditingMode,
                         nameSpace: nameSpace,
                         albumViewNameSpace: albumViewNameSpace,
                         scrollProxy: proxy)
          // folder 추가시 스크롤을 위한 임시 뷰
          scrollHelperView(
            id: "FolderScrollItem",
            height: tabbarHeight + tabbarTopPadding
                                  + tabbarBottomPadding
          )
        }
        .padding(.top, photoData.premiumUser ? 0 : adsRegionSpacing)
        .onAppear(perform: {
          albumViewModeChange()
          
        })
        .onChange(of: pageFolder.albumsArray.count,
                  perform: { [oldValue = pageFolder.albumsArray.count] newValue in
          if oldValue > 0 && newValue > oldValue {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
              withAnimation {
                proxy.scrollTo("newAlbumSpaceForScroll")
              }
            }
          }
        })
        .onChange(of: pageFolder.foldersArray.count,
                  perform: { [oldValue = pageFolder.foldersArray.count] newValue in
          if newValue > oldValue && oldValue != 0 {
            withAnimation {
              proxy.scrollTo("FolderScrollItem")
            }
          }
        })
      }
      .modify({ view in
        if #available(iOS 17.0, *) {
          view
            .contentMargins(
              .bottom,
              tabbarHeight - geometry.safeAreaInsets.bottom / 2,
              for: .scrollIndicators)
        } else {
          view
        }
      })
      .overlay {
        // topFolder 비어있음 Text
        if pageFolder.inited {
          if pageFolder.albumsArray.isEmpty && pageFolder.foldersArray.isEmpty {
            emptyAlbumMessageView
          }
        }
      }
    })
    .navigationBarTitleDisplayMode(.inline)
    .overlay(alignment: .top, content: {
      navigationBlurView(height: safeAreaTopPadding)
        .ignoresSafeArea()
    })
    .toolbar {
      navigationTitleView(title: pageFolder.title)
      if !state.isShowingSettingView {
        rightToolbar()
      }
    }
    .foregroundColor(.secondary)
    .background { FancyBackground() }
    .edgesIgnoringSafeArea(.trailing)
    .onAppear(perform: {
      dispatchAnimation {
        isPhotosView = 0
      }
    })
  }
  func albumViewModeChange() {
    if state.firstAppear {
      dispatchAnimation {
        let unfold = self.pageFolder.foldersArray.isEmpty
        && pageFolder.albumsArray.count > listCount
        if unfold {
          state.boolChange(.firstAppear)
          state.boolChange(.expand, bool: unfold)
        }
      }
    }
  }
}

// MARK: - functions
extension AlbumView {
  func sectionView(section: CellType, count: Int) -> some View {
    HStack(alignment: .center) {
      Text("\(section == .folder ? "폴더" : "앨범") 리스트")
        .font(.headline)
        .foregroundColor(.white)
        .fontWeight(.heavy)
      Text("(\(count)개)")
        .font(.footnote)
        .foregroundColor(.gray)
        .contentTransition(.numericText())
      Spacer()
      // 앨범 리스트 펼쳐보기 / 한 줄 보기 버튼
      if section == .album && count > listCount {
        HStack(spacing: 5) {
          Group {
            if state.isExpanded {
              Text("펼쳐")
            } else {
              Text("한줄")
            }
          }
          .transition(state.isExpanded ? .flip : .flipReverse)
          Text("보기")
        }
        .font(.footnote)
        .foregroundStyle(.gray)
        .onTapGesture {
          DispatchQueue.global(qos: .userInteractive).async {
            withAnimation(.interactiveSpring(
              response: 0.35,
              dampingFraction: 0.8,
              blendDuration: 0)) {
//                self.isUnfolded.toggle()
                state.boolChange(.expand)
              }
          }
        }
      }
    }
    .padding([.top, .horizontal], 10)
    .background {
      FancyBackground()
    }
  }
  func navigationTitleView(title: String) -> some ToolbarContent {
    ToolbarItem(placement: .principal) {
      Text("\(title == "" ? "(No Title)" : title)")
        .foregroundStyle((title == "" || state.isShowingSettingView)
                          ? .gray : .white)
        .contentTransition(.numericText())
    }
  }
  
  func rightToolbar() -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      rightToolbarAlbumView
        .offset(x: state.isShowingSettingView ? 100 : 0)
    }
  }
  var emptyAlbumMessageView: some View {
    let text = pageFolder.id == "topFolder" ? "사진첩의 카테고리가" : (pageFolder.id == "shareTop" ? "공유 앨범이 " : "폴더가 ")
    return VStack(alignment: .leading, spacing: 15) {
      Text(text + "비었습니다.")
      if pageFolder.folderType == .userFolder {
        Text("위 메뉴에서 폴더 / 앨범을 추가할 수 있습니다.")
      }
    }
    .foregroundStyle(.gray.opacity(0.5))
    .offset(y: -navigationbarHeight / 2)
    .modify { view in
      if #available(iOS 26, *) {
        view
          .transition(.blurReplace)
      } else {
        view
          .transition(.opacity)
      }
    }
  }
  var popOffCurrentPage: some Gesture {
    DragGesture(minimumDistance: 10, coordinateSpace: .global)
      .onEnded({ value in
        if pageFolder.phCollectionList != nil {
          if value.translation.width > 50 {
            dismiss()
          }
        }
      })
  }
  func shareMessageView() -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .foregroundStyle(.gray.opacity(0.5))
        .frame(maxWidth: 600)
      VStack(alignment: .leading, spacing: 10) {
        Text("❶ 현재 공유 앨범은 <보기 모드>만 지원합니다.")
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 2) {
            Text("❷ ")
            Text("<폴더 기능>")
              .foregroundStyle(.blue)
            Text("을 사용할 수 있습니다.")
          }
          Group {
            Text("- 일반 앨범처럼 폴더를 편집할 수 있습니다.")
            Text("- [공유 앨범]의 폴더는 사진앱과 동기화하지 않습니다.")
            Text("- 앱 삭제시 [공유 앨범]의 폴더 정보는 사라집니다.")
          }
          .font(.subheadline)
          .padding(.leading, 20)
        }
      }
      .padding(20)
    }
  }
  func scrollHelperView(id: String, height: CGFloat) -> some View {
    Rectangle()
      .foregroundStyle(Color.fancyBackground)
      .frame(height: height)
      .id(id)
  }
}

// MARK: - [툴바] 아이템 / context 메뉴
extension AlbumView {
  // Trailing 툴바 아이텝 (2개)
  @ViewBuilder
  var rightToolbarAlbumView: some View {
    let iconWidth: CGFloat = 45
    Group {
      if state.isEditingMode {
        Button {
          withAnimation(.easeInOut(duration: 0.25)) {
//            isEditingMode = false
            state.boolChange(.editingMode)
          }
        } label: {
          ZStack {
            Rectangle().foregroundColor(.clear)
            Text("Done")
          }
          .foregroundStyle(.gray)
        }
        .frame(width: iconWidth, height: 20, alignment: .center)
        .buttonStyle(ClickScaleEffect())
      } else {
        Menu {
          EditCollectionMenuView(
            pageFolder: pageFolder,
            processing: .constant(nil),
            isEditMode: $state.isEditingMode,
            subCollection: pageFolder.subCollection(id: pageFolder.id, type: .folder),
            isSecondary: false,
            index: 0,
            nameSpace: nameSpace) { sub in
              
            }
//          contextMenu
        } label: {
          imageWithScale(
            systemName: iconFolderSetting,
            scale: .large)
          .foregroundStyle(.gray)
        }
        .menuStyle(.borderlessButton)
        .frame(width: iconWidth, height: 20, alignment: .center)
      }
    }
  }
  // Leading 툴바 아이텝 (1개) - Home에서만 출현
  var leftHomeToolBarItem: some View {
    Button {
//      dispatchAnimation {
//        self.isShowingSettingView.toggle()
//      }
      state.boolChange(.settingview)
    } label: {
      Label("Setting", systemImage: iconSetting)
        .labelStyle(.iconOnly)
        .foregroundStyle(.gray)
        .rotationEffect(
          .degrees(state.isShowingSettingView ? -180 : 0)
        )
        .matchedGeometryEffect(id: "settingBack",
                               in: nameSpace)
    }
    .buttonStyle(ClickScaleEffect())
  }
  // 툴바 아이템 (Trailing) - contextMenu
  var contextMenu: some View {
    return VStack {
      Text(pageFolder.title)
      Divider()
      controllGroup17HStack {
        Group {
          if pageFolder.folderType != .shareCategory {
            Button {
//              withAnimation {
//                isEditingMode = true
//              }
              state.boolChange(.editingMode)
            } label: {
              Label("지우기 모드", systemImage: iconEraser)
                .symbolRenderingMode(.multicolor)
            }
          }
          Button {
            let reorderObject = ReorderObject(
              localIdentifier: pageFolder.id,
              folderType: pageFolder.folderType
            )
            NotificationCenter.default
              .post(name: .showReorderSheet,
                    object: reorderObject)
          } label: {
            Label("순서 조정하기", systemImage: iconReorder)
          }
        }
      }
      if pageFolder.id != "topFolder" && pageFolder.id != "shareTop" {
        Divider()
        Button {
          let alertObject = AlertObject(
            alertCase: .folderNameChange,
            folderType: pageFolder.folderType,
            albumID: nil,
            folderID: pageFolder.id)
          NotificationCenter.default
            .post(name: .showAlert, object: alertObject)
        } label: {
          Label("타이틀 수정하기", systemImage: iconModify).bold()
        }
      }
      Divider()
      Button {
        let alertObject = AlertObject(
          alertCase: .addFolderToFolder,
          folderType: pageFolder.folderType,
          albumID: nil,
          folderID: pageFolder.id)
        NotificationCenter.default
          .post(name: .showAlert, object: alertObject)
      } label: {
        Label("폴더 추가하기", systemImage: iconAddFolder)
      }
      if pageFolder.folderType != .shareCategory {
        Button {
          let alertObject = AlertObject(
            alertCase: .addAlbumToFolder,
            albumID: nil,
            folderID: pageFolder.id)
          NotificationCenter.default
            .post(name: .showAlert, object: alertObject)
        } label: {
          Label("앨범 추가하기", systemImage: iconAddAlbum)
        }
      }
    }
  }
}

struct AlbumView_Previews: PreviewProvider {
  static var previews: some View {
    AlbumView(pageFolder: MLFolder(collectionList: nil),
              isPhotosView: .constant(0),
              pageIndex: 0,
//              isShowingSettingView: .constant(false),
              isShowingMessageView: .constant(false),
              tutorialOn: .constant(false),
              nameSpace: Namespace().wrappedValue)
    .environmentObject(MLPhotoData())
  }
}

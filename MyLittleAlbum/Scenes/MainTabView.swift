//
//  MainTabView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 5/21/25.
//

import SwiftUI

struct MainTabView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @State var selectedTab: Tabs = .album
  @State var isPhotosView: Int = 0
  @State var isShowingHome: Bool = false
  @State var animationEnded: Bool = false
  @State var isShowingSettingView: Bool = false
  @Namespace var nameSpace
  // for tutorial
  let helloHeight: CGFloat = 100
  @State var isShowingMessageView: Bool = false
  @State var tutorialOn: Bool = false
  @State var tutorialSelectedInt: Int = 0
  // for opening Animation
  @ObservedObject var launchScreenManger: LaunchScreenManager
  @Binding var isOpen: Bool
  @Binding var maskingScale: CGFloat
  @State var openMLAlbumID: String? = nil
  
  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottomLeading, content: {
        contentView(geoProxy: geometry) {
          SettingView(isShowing: $isShowingSettingView,
                      tutorialOn: $isShowingMessageView)
        } adsRegion: {
          adsView()
        }
        tabView(geometry: geometry)
      })
    }
    .ignoresSafeArea()
    .onChange(of: photoData.loadingState) { newValue in
      loadContents(state: newValue)
    }
    .onReceive(NotificationCenter.default
      .publisher(for: .showPhotosPicker)) { output in
      if let albumID = output.object as? String {
        DispatchQueue.main.async {
          print(albumID)
          self.openMLAlbumID = albumID
          withAnimation(.bouncy(duration: 0.2)) {
            isShowingHome = true
          } completion: {
            DispatchQueue.main.async {
              withAnimation {
                self.animationEnded = true
              }
            }
          }
        }
      }
    }
  }
}

extension MainTabView {
  func loadContents(state: LoadingStep) {
    if photoData.loadingState != .loadingComplete {
      switch state {
      case .videoDone:
        photoData.loadAlbumData(step: .loadTopFolder)
      case .doneTopFolder:
        photoData.loadAlbumData(step: .loadSecondaryLines)
      case .loadAllAlbums:
        DispatchQueue.global(qos: .background).async {
          photoData.loadAlbumData(step: .loadAllAlbums)
        }
      case .doneAllAlbums:
        if !photoData.existingUser {
          dispatchAnimation {
            self.isShowingMessageView = true
          }
        }
        DispatchQueue.global(qos: .background)
          .asyncAfter(deadline: .now() + 1.5) {
            photoData.loadAlbumData(step: .loadHomeAlbum)
          }
      case .loadingComplete:
        print("complete")
        photoData.loadShareCategories()
      default: break
      }
    }
  }
  
  @ViewBuilder
  private func contentView(
          geoProxy: GeometryProxy,
          settingViewRegion: @escaping () -> some View,
          adsRegion: @escaping () -> some View) -> some View {
    TabView(selection: $selectedTab) {
      Group {
//        NavigationStack {
//          AllPhotosView(mlAlbum: photoData.homeAlbum
//                                  ?? MLAlbum( isHome: true),
//                        isHiddenAsset: false,
//                        nameSpace: nameSpace,
//                        isPhotosView: $isPhotosView) { _ in }
//            .transition(.opacity)
//        }
//        .tag(Tabs.photo)
        NavigationStack {
          AlbumView(pageFolder: photoData.folders["topFolder"] ??
                    MLFolder(folderType: .userFolder),
                    isPhotosView: $isPhotosView,
//                    isShowingSettingView: $isShowingSettingView,
                    isShowingMessageView: $isShowingMessageView,
                    tutorialOn: $tutorialOn,
                    nameSpace: nameSpace)
          .toolbar(id: "setting") {
            ToolbarItem(id: "setting", placement: .topBarLeading) {
              toolbarSettingView(showing: $isShowingSettingView)
            }
          }
        }
        .tag(Tabs.album)
        NavigationStack {
          if let shareTop = photoData.shareFolders["shareTop"] {
            AlbumView(pageFolder: shareTop,
                      isPhotosView: $isPhotosView,
//                      isShowingSettingView: $isShowingSettingView,
                      isShowingMessageView: $isShowingMessageView,
                      tutorialOn: $tutorialOn,
                      nameSpace: nameSpace)
            .onAppear {
              if photoData.shareAlbums.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                  photoData.registShareAlbums()
                  print("load shares")
                }
              }
            }
          } else {
            EmptyView()
          }
        }
        .tag(Tabs.share)
//        NavigationStack {
//          SmartAlbumView(isShowingSettingView: $isShowingSettingView,
//                         isPhotosView: $isPhotosView,
//                         nameSpace: nameSpace)
//        }
//        .tag(Tabs.other)
      }
      .overlay(content: {
        ZStack(alignment: .leading) {
          backgroundBlurView
          settingViewRegion()
            .frame(maxWidth: 450)
            .offset(x: isShowingSettingView
                    ? 0 : -geoProxy.size.width - 50)
        }
        .ignoresSafeArea()
        .padding(.top, navigationbarHeight)
      })
      .modify({ view in
        if #available(iOS 18.0, *) {
          view.toolbarVisibility(.hidden, for: .tabBar)
        } else {
          view.toolbar(.hidden, for: .tabBar)
        }
      })
    }
    .toolbar(content: {
      toolbarSettingView
    })
    .modify({ view in
      if photoData.premiumUser {
        view
      } else {
        view
          .overlay(alignment: .top) {
            adsRegion()
              .padding(.vertical, 5)
              .offset(y: statusBarHeight + navigationbarHeight)
          }
      }
    })
  }
  func tabView(geometry: GeometryProxy) -> some View {
    let spacing: CGFloat = 30
    let width: CGFloat = geometry.size.width
    let albumType: AlbumType = openMLAlbumID == nil
                              ? .home : .picker
    return CustomTabBarView(
       selectedTab: $selectedTab,
       launchScreenManager: launchScreenManger,
       width: width,
       spacing: spacing,
       isOpen: $isOpen,
       maskingScale: $maskingScale,
       albumTabTapped: .constant(false),
       isPhotosView: isPhotosView,
       nameSpace: nameSpace,
       actionTab1: { showLaunchVideo() },
       actionTab2: {
          dispatchAnimation {
            photoData.getRandomNum()
          }
       },
       actionTab3: { },
       actionTab4: { },
       isShowingHome: $isShowingHome,
       animationEnded: $animationEnded,
       photosView: {
         CustomPhotosPicker(
          isShowingPhotosPicker: $isShowingHome,
          animationEnded: $animationEnded,
          openedMLAlbumID: openMLAlbumID,
          albumType: albumType,
          nameSpace: nameSpace) { assets in
            addAssetsIntoAlbum(addedAssets: assets,
                               id: openMLAlbumID)
          }
       }, closePhtosView: {
         closePhotosView()
       }
    )
    .offset(y: isShowingSettingView ? 150 : 0)
  }
  func addAssetsIntoAlbum(addedAssets: [MLAsset], id: String?) {
    guard let albumID = id,
          let album = photoData
                    .mlAlbum(type: .userFolder, albumID)
    else {
      closePhotosView()
      return
    }
    closePhotosView()
    album.addAsset(assets: addedAssets) { bool in
      if bool {
        dispatchAnimationDelay(delay: 0.5) {
          NotificationCenter.default
            .post(name: .outsideFetchChange, object: albumID)
        }
      }
      album.processingChange(bool: false)
    }
  }
  func closePhotosView() {
    DispatchQueue.main.async {
      withAnimation(.bouncy(duration: 0.3)) {
        isShowingHome = false
      } completion: {
        self.animationEnded = false
        self.openMLAlbumID = nil
      }
    }
  }
  var toolbarSettingView: some View {
    Button {
      dispatchAnimation {
        self.isShowingSettingView.toggle()
      }
    } label: {
      Label("Setting", systemImage: iconSetting)
        .labelStyle(.iconOnly)
        .foregroundStyle(.gray)
        .rotationEffect(
          .degrees(isShowingSettingView ? -180 : 0)
        )
    }
    .buttonStyle(ClickScaleEffect())
  }
  func showLaunchVideo() {
    if photoData.useOpeningAni {
      withAnimation(.easeInOut(duration: 0.3)) {
        isOpen = false
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
        launchScreenManger.state = .ready
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        withAnimation(.easeIn(duration: 0.2)) {
          maskingScale = device == .phone ? 0.8 : 0.6
        }
      }
    }
  }
  func adsView() -> some View {
    ZStack {
      Rectangle()
        .foregroundStyle(.yellow.opacity(0.4))
        .frame(height: 100)
      Image(systemName: "star")
    }
  }
  
  var backgroundBlurView: some View {
    Rectangle()
      .foregroundStyle(.ultraThinMaterial)
      .opacity(isShowingSettingView ? (device == .pad ? 1 : 1) : 0)
      .ignoresSafeArea()
      .onTapGesture {
        withAnimation {
          // 아이패드에서 외부 터치 시 저장없이 닫기
          isShowingSettingView = false
        }
      }
  }
}

#Preview {
  MainTabView(launchScreenManger: LaunchScreenManager(),
              isOpen: .constant(true),
              maskingScale: .constant(0))
}

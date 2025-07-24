//
//  MainTabView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 5/21/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @State var selection: Tabs = .album
    @State var isPhotosView: Int = 0
    @State var isShowingSettingView: Bool = false
    @Namespace var nameSpace
    
    let launchScreenManger: LaunchScreenManager
    @Binding var isOpen: Bool
    @Binding var maskingScale: CGFloat
    
    var body: some View {
        // 메인 뷰 - 각 탭뷰 별도의 네비게이션 스타일(extension) 적용
        // (For 탭1에 네비게이션바 가림)
        ZStack(alignment: device == .phone
               ? .bottom
               : (isPhotosView != 0 ? .bottomLeading : .bottom), content: {
            TabView(selection: $selection) {
                NavigationStack(root: {
                    AllPhotosView(albumType: .home,
                                  assetCollection: nil,
                                  isHiddenAsset: false,
                                  isPhotosView: $isPhotosView,
                                  nameSpace: nameSpace)
                })
                .tag(Tabs.photo)
                NavigationStack(root: {
                    AlbumView(pageFolder: photoData.folders["topFolder"] ?? MLFolder(collectionList: nil),
                              phCollectionList: nil,
                              isPhotosView: $isPhotosView,
                              nameSpace: nameSpace,
                              isShowingSettingView: $isShowingSettingView)
                })
                .tag(Tabs.album)
//                NavigationStack(root: {
//                    AlbumView(phCollectionList: nil,
//                              isPhotosView: $isphotosView,
//                              nameSpace: nameSpace,
//                              isShowingSettingView: $isShowingSettingView,
//                              isHome: true)
//                })
//                .tag(Tabs.share)
                NavigationStack(root: {
                    SmartAlbumView(isPhotosView: $isPhotosView,
                                   nameSpace: nameSpace)
                })
                .tag(Tabs.other)
            }
            .environment(\.horizontalSizeClass, .compact)
            // ipad 탭바 기존으로 유지
            CustomTabBarView(selectedTab: $selection,
                             launchScreenManager: launchScreenManger,
                             isOpen: $isOpen,
                             maskingScale: $maskingScale,
                             albumTabTapped: .constant(false),
                             isPhotosView: isPhotosView,
                             actionTab1: {
                showLaunchVideo()
            }, actionTab2: {
                dispatchAnimation {
                    photoData.getRandomNum()
                }
            }, actionTab3: { }, actionTab4: { })
            .offset(y: isShowingSettingView ? 150 : 0)
        })
        .ignoresSafeArea()
    }
    
    func showLaunchVideo() {
        if photoData.useOpeningAni {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOpen = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                launchScreenManger.state = .first
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeIn(duration: 0.2)) {
                    maskingScale = device == .phone ? 0.8 : 0.6
                }
            }
        }
    }
}

#Preview {
    MainTabView(launchScreenManger: LaunchScreenManager(),
                isOpen: .constant(true),
                maskingScale: .constant(0))
}

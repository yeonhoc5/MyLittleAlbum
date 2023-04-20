//
//  TabBarView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI
import Photos

struct TabBarView: View {
    @EnvironmentObject var photoData: PhotoData
    @StateObject var launchScreenManger: LaunchScreenManager = LaunchScreenManager()
    @StateObject var topFolder: Folder = Folder(isHome: true, colorIndex: 0)
    @State var selection: Tabs = .album
    @State var isOpen: Bool = false
    @State var maskingScale: CGFloat = 4
    @Environment(\.scenePhase) var scenePhase
    
    @State var isShowingSettingView: Bool = false
    
    var body: some View {
        // custom Tabbar 사용
        let appearance = UITabBar.appearance()
        appearance.isHidden = true
        
        return ZStack {
        // 0. 백그라운드 설정 없을 시 런치스크린과 메인 뷰 사이에 블랙 스크린 나타남
            FancyBackground()
            
        // 1. 사진 권한에 따라 - 메인뷰 / 권한 안내 뷰 : 권한 설정 시 런치스크린부터 재시작
            switch photoData.status {
            case .authorized:
                GeometryReader { proxy in
                    mainView
                    SettingView(isShowingSettingView: $isShowingSettingView)
                        .position(x: isShowingSettingView ? proxy.size.width / 2 : -proxy.size.width,
                                  y: proxy.size.height / 2)
                }
            default: NonAuthorizedView()
            }
            
        // 2. background 스크린 (state == inactive로 설정하면 알럿 창 나타날 때도 이 화면이 나타나므로 background로 지정해야 함)
            if scenePhase == .background {
                BackgroudStateView()
            }
            
        // 3. 런치 스크린
            if launchScreenManger.state != .complete {
                LaunchScreenView(launchScreenManger: launchScreenManger,
                                 maskingScale: $maskingScale,
                                 isOpen: $isOpen)
            }
        }
        .environmentObject(launchScreenManger)
    }
}


extension TabBarView {
    // 런치 스크린 종류 후, 메인 뷰 트랜지션 마스크 뷰
    func maskCircle(manager: LaunchScreenManager, startSize: CGFloat, endSize: CGFloat) -> some View {
        FancyBackground()
            .clipShape(Circle())
            .scaleEffect(isOpen == true ? endSize : startSize)
            .offset(y: -90)
    }
    
    // 메인 뷰 - 각 뷰에 별도의 네비게이션 스타일(extension) 적용 (For 탭1에 네비게이션바 가림)
    var mainView: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
            // Tab 1 : 앨범없는 사진첩
                viewWithNavigation(type: .photo,
                                   isShowingSettingView: .constant(false))
                    .tag(Tabs.photo)
            // Tab 2 : 유저 앨범
                viewWithNavigation(type: .album, title: "마이 리틀 앨범",
                                   isShowingSettingView: $isShowingSettingView)
                    .tag(Tabs.album)
            // Tab 3 : 스마트앨범 (사진 관리)
                viewWithNavigation(type: .other, title: "사진 관리",
                                   isShowingSettingView: .constant(false))
                    .tag(Tabs.smart)
            }
            CustomTabBarView(launchScreenManager: launchScreenManger,
                             selectedTab: $selection,
                             isOpen: $isOpen,
                             maskingScale: $maskingScale)
        }
        .ignoresSafeArea()
        .mask { maskCircle(manager: launchScreenManger, startSize: 0.0001, endSize: 4) }
    }
}


extension TabBarView {
    // 네비게이션 스타일 설정
    func viewWithNavigation(type: TypeView,
                            album: PHAssetCollection! = nil,
                            title: String! = "",
                            isShowingSettingView: Binding<Bool>) -> some View {
        let appearanceScroll = UINavigationBarAppearance()
        let appearanceStandard = UINavigationBarAppearance()
        [appearanceStandard, appearanceScroll].forEach {
            $0.shadowColor = UIColor(patternImage: UIImage())
            $0.shadowImage = UIImage()
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        appearanceScroll.backgroundColor = UIColor(Color.fancyBackground)
        appearanceStandard.backgroundColor = UIColor(Color.fancyBackground).withAlphaComponent(0.7)
        UINavigationBar.appearance().standardAppearance = appearanceStandard
        UINavigationBar.appearance().scrollEdgeAppearance = appearanceScroll
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).overrideUserInterfaceStyle = .dark
        
        return NavigationStack(root: {
            if type == .photo {
                AllPhotosView(albumType: .home, settingDone: false)
            } else if type == .album {
                AlbumView(stateChangeObject: StateChangeObject(),
                          pageFolder: topFolder,
                          title: title,
                          isShowingSettingView: isShowingSettingView)
            } else {
                SmartAlbumView()
            }
        })
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(selection: .album, isOpen: true).mainView
            .environmentObject(PhotoData())
    }
}

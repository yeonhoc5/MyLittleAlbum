//
//  ContentView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//
import SwiftUI
import Photos

struct ContentView: View {
    @EnvironmentObject var photoData: PhotoData
    @StateObject var topFolder = Folder(isHome: true, colorIndex: 0)
    @State var selection: Tabs = .album
    @Namespace var nameSpace
    // 런치스크린 프라퍼티
    @StateObject var launchScreenManger = LaunchScreenManager()
    @State var isOpen = false
    @State var maskingScale: CGFloat = 4
    // 세팅뷰 프라퍼티
    @State var isShowingSettingView: Bool = false
    @State var isphotosView: Bool = false
    
    var body: some View {
        ZStack {
            // 0. 백그라운드 설정 없을 시 런치스크린과 메인 뷰 사이에 블랙 스크린 나타남
            FancyBackground()
            // 1. 사진 권한에 따라 - [메인뷰] / [권한 안내 뷰] : (권한 설정 시 런치스크린부터 재시작)
            switch photoData.status {
            case .authorized:
                mainView(selection: $selection, isPhotosView: $isphotosView)
            default:
                NonAuthorizedView(topFolder: topFolder)
            }
            // 2. 디지털 액자 뷰
            if photoData.isShowingDigitalShow {
                DigitalShowView(nameSpace: nameSpace)
            }
            // 3. 런치 스크린
            if photoData.useOpeningAni
                && launchScreenManger.state != .complete {
                LaunchScreenView(launchScreenManger: launchScreenManger,
                                 maskingScale: $maskingScale,
                                 isOpen: $isOpen)
            }
            // 4. 프로그레스 뷰 - 스킨 체인지 시 프로그레스 뷰
            if photoData.uiModeChanged {
                CustomProgressView(stateChangeObject: StateChangeObject(),
                                   color: photoData.uiMode == .classic
                                   ? .orange : colorSet[0])
            }
        }
        .environmentObject(launchScreenManger)
        .onAppear {
            // 오프닝 애니메이션 (비사용 -> 사용)으로 변경시 오프닝 자동 실행되지 않도록
            if !photoData.useOpeningAni {
                launchScreenManger.state = .complete
                isOpen = true
            }
        }
    }
}

extension ContentView {
    // 메인 뷰 - 각 탭뷰 별도의 네비게이션 스타일(extension) 적용
    // (For 탭1에 네비게이션바 가림)
    func mainView(selection: Binding<Tabs>, isPhotosView: Binding<Bool>) -> some View {
        ZStack(alignment: device == .phone
               ? .bottom
               : (isPhotosView.wrappedValue ? .bottomLeading : .bottom), content: {
            TabView(selection: selection) {
                NavigationStack(root: {
                    AllPhotosView(albumType: .home,
                                  settingDone: false,
                                  isPhotosView: $isphotosView,
                                  nameSpace: nameSpace)
                })
                .tag(Tabs.photo)
                NavigationStack(root: {
                    AlbumView(
                        pageFolder: topFolder,
                        title: "마이 리틀 앨범",
                        isPhotosView: $isphotosView,
                        nameSpace: nameSpace,
                        isShowingSettingView: $isShowingSettingView,
                        stateChangeObject: StateChangeObject())
                })
                .tag(Tabs.album)
                NavigationStack(root: {
                    SmartAlbumView(isPhotosView: $isphotosView,
                                   nameSpace: nameSpace)
                })
                .tag(Tabs.other)
            }
            CustomTabBarView(selectedTab: selection,
                             launchScreenManager: launchScreenManger,
                             isOpen: $isOpen,
                             maskingScale: $maskingScale,
                             isPhotosView: isphotosView
            )
                .offset(y: isShowingSettingView ? 150 : 0)
        })
        .ignoresSafeArea()
        .mask {
            if photoData.useOpeningAni {
                maskCircle(manager: launchScreenManger,
                           startSize: 0.0001,
                           endSize: 4)
            } else {
                Rectangle()
                    .ignoresSafeArea()
            }
        }
    }
    
    // 런치 스크린 종류 후, 메인 뷰 트랜지션 마스크 뷰
    func maskCircle(manager: LaunchScreenManager, startSize: CGFloat, endSize: CGFloat) -> some View {
        FancyBackground()
            .clipShape(Circle())
            .scaleEffect(isOpen == true ? endSize : startSize)
            .offset(y: -90)
    }
}

extension ContentView {
    // 오디오 리턴
    func pauseBackgroundAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print(error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selection: .album, isOpen: true)
            .environmentObject(PhotoData())
    }
}

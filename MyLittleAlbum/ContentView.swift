//
//  ContentView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//
import SwiftUI
import Photos

//로딩 순서
//1. 앨범 카테고리
//2. 전체 사진
//3. 앨범에 없는 사진 모음 로딩

struct ContentView: View {
  @Environment(\.scenePhase) var scenePhase
  @EnvironmentObject var photoData: MLPhotoData
  @State var selection: Tabs = .album
  // 런치스크린 프라퍼티
  @StateObject var launchScreenManger = LaunchScreenManager()
  @State var isOpen = false
  @State var maskingScale: CGFloat = 4
  
  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      // 1. [메인뷰] or [권한 안내 뷰] : 권한 설정 시 런치스크린부터 재시작
      Group {
        if photoData.phAuthorization == .authorized {
          MainTabView(selectedTab: photoData.startView,
                      launchScreenManger: launchScreenManger,
                      isOpen: $isOpen,
                      maskingScale: $maskingScale)
        } else {
          NonAuthorizedView()
        }
      }
      .transition(.opacity)
//      .mask {
//        GeometryReader { geoproxy in
//          animationMaskView(geoproxy: geoproxy)
//        }
//      }
      // 2. 런치 스크린
//      if photoData.useOpeningAni && launchScreenManger.state != .complete {
//        LaunchScreenView(launchScreenManger: launchScreenManger,
//                         maskingScale: $maskingScale,
//                         isOpen: $isOpen) {
//          dispatchAnimation {
//            photoData.loadingState = .videoDone
//          }
//        }
//      }
//      centerCheckerView
    }
    .modifier(InAppDigitalShowModifier())   // 디지털 쇼 뷰
    .modifier(InAppSheetModifier())   // 앨범,폴더 순서 / 이동 sheet
    .modifier(CollectionAlertModifier(notificationName: .showAlert,
                                      isHiddenAsset: false))         // 알럿 통합
    .modifier(InAppProgressView(notificationName: .showProgressingView))   // 프로그레스 뷰
    .modifier(InAppInfoView()) // info 뷰
    //        .environmentObject(launchScreenManger)
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
  // 런치 스크린 종류 후, 메인 뷰 트랜지션 마스크 뷰
  func maskCircle(startSize: CGFloat,
                  endSize: CGFloat) -> some View {
    FancyBackground()
      .clipShape(Circle())
      .scaleEffect(isOpen == true ? endSize : startSize)
      .offset(y: -90)
  }
  var centerCheckerView: some View {
    Group {
      VStack(spacing: 0) {
        Rectangle()
          .foregroundStyle(.yellow)
        Rectangle()
          .foregroundStyle(.red)
      }
      HStack(spacing: 0) {
        Rectangle()
          .foregroundStyle(.blue)
        Rectangle()
          .foregroundStyle(.green)
      }
    }
    .opacity(0.3)
    .ignoresSafeArea()
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
  func animationMaskView(geoproxy: GeometryProxy) -> some View {
    Group {
      if photoData.useOpeningAni {
        maskCircle(startSize: 0.0001, endSize: 4)
      } else {
        BackgroudStateView(size: geoproxy.size)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(selection: .album, isOpen: true)
      .environmentObject(MLPhotoData())
  }
}

//
//  SettingView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/09.
//

import SwiftUI

struct SettingView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @Binding var isShowing: Bool
  @Binding var tutorialOn: Bool
  // 기능 설정 프라퍼티
  @State var starView: Tabs = .album
  @State var uiMode: UIMode = .modern
  @State var useOpeningAni: Bool = true
  @State var useKnock: Bool = true
  @State var isRandomPlay: Bool = true
  @State var transitionIndex: Int = 2
  // 가이드 프라퍼티
  @State var settingList: SettingList = .opening
  @State var isShowingSettingGuide: Bool = false
  @State var butonText: String = ""
  let btnSize: CGFloat = 58
  let btnPadding: CGFloat = 15
  
  var body: some View {
    VStack(alignment: device == .phone ? .leading : .center, spacing: 0, content: {
      titleView
        .padding(.horizontal, 16)
      Form(content: {
        SectionFundamentalView(header: {
          headerText(str: "1. 기본 설정")
        }, startView: $starView,
           uiMode: $uiMode,
           useOpeningAni: $useOpeningAni,
           settingList: $settingList,
           useKnock: $useKnock,
           isShowingSettingGuide: $isShowingSettingGuide)
        SectionDigitalView(header: {
          headerText(str: "2. 디지털 액자 설정")
        }, isRandom: $isRandomPlay,
           randomChanged: photoData.digitalShowRandom != self.isRandomPlay,
           currentIndex: photoData.transitionIndex,
           changedIndex: $transitionIndex)
      })
      .foregroundStyle(Color.fancyBackground)
      .scrollContentBackground(.hidden)
      .clipped()
      .shadow(radius: 3)
      .modify({ view in
        if #available(iOS 17.0, *) {
          view.contentMargins(.bottom, 100, for: .scrollContent)
        } else {
          view
        }
      })
    })
    .conditionalModifier(device == .pad, transform: { view in
      view
        .background {
          RoundedRectangle(cornerRadius: 20)
            .foregroundStyle(.white)
        }
    })
    .padding(.top,photoData.premiumUser ? 10 : adsRegionSpacing)
    .ignoresSafeArea()
    .padding(.bottom, device == .phone ? 0 : btnSize + (btnPadding * 2))
    .overlay(alignment: .bottom, content: {
      btnDone
        .opacity(isShowingSettingGuide ? 0 : 1)
        .padding(device == .phone ? .all : .vertical, btnPadding)
    })
    .padding([.horizontal, .top], device == .phone ? 0 : 30)
    .padding(.bottom, 15)
    .onAppear {
      loadPreviousSetting()
    }
  }
}

// subViews
extension SettingView {
  var btnTutorial: some View {
    Button {
      withAnimation {
        isShowing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation {
            tutorialOn = true
          }
        }
      }
    } label: {
      Text("튜토리얼")
        .font(.caption)
        .underline()
        .foregroundStyle(.gray)
    }
  }
  var titleView: some View {
    let color = device == .phone ? Color.white : Color.black
    return VStack(alignment: device == .phone ? .leading : .center,
                  spacing: 0) {
      Text("설정")
        .font(.title)
        .bold()
        .foregroundStyle(color)
        .contentTransition(.numericText())
        .padding(.vertical, 10)
      Rectangle()
        .foregroundStyle(color.opacity(0.3))
        .frame(height: 1)
    }
    .overlay(alignment: .trailing) {
      btnTutorial
    }
  }
  
  func headerText(str: String) -> some View {
    Text(str)
      .foregroundStyle(device == .phone ? Color.white : Color.black)
      .font(.caption )
      .offset(x: -10)
  }
  
  var btnDone: some View {
    let state = changeChecker(self.starView,
                              self.uiMode,
                              self.useOpeningAni,
                              self.useKnock,
                              self.isRandomPlay,
                              self.transitionIndex)
    return ZStack(alignment: .trailing) {
      // 저장 버튼
      Button {
        saveSetting()
      } label: {
        Capsule()
          .foregroundStyle(state ? .blue : .white)
          .frame(height: btnSize)
          .frame(maxWidth: state ? widthLimit : 58)
          .shadow(radius: 3)
          .overlay {
            Text("저장하기")
              .opacity(state ? 1 : 0)
              .foregroundStyle(.white)
          }
      }
      .shadow(radius: 10)
      .disabled(!state)
      // 취소, 닫기 버튼
      Button {
        withAnimation {
          isShowing = false
        }
      } label: {
        ZStack {
          Circle()
            .foregroundStyle(.white)
            .frame(width: btnSize - 8, height: btnSize - 8)
            .shadow(color: state ? .gray : .clear ,radius: state ? 3 : -1)
          imageScaledFit(systemName: "xmark", width: 20, height: 20)
            .foregroundStyle(.gray)
            .fontWeight(.light)
            .rotationEffect(
              .degrees(state ? 270 : 0)
            )
        }
      }
      .buttonStyle(ClickScaleEffect())
      .offset(x: -4)
    }
    .animation(.interpolatingSpring, value: state)
  }
}

// functions
extension SettingView {
  func loadPreviousSetting() {
    DispatchQueue.main.async {
      starView = photoData.startView
      uiMode = photoData.uiMode
      useOpeningAni = photoData.useOpeningAni
      useKnock = photoData.useKnock
      isRandomPlay = photoData.digitalShowRandom
      transitionIndex = photoData.transitionIndex
    }
  }
  
  func saveSetting() {
    // progressView는 ui
    let userDefaults = UserDefaults.standard
    // -1. startView 설정
    if photoData.startView != self.starView {
      userDefaults.set(starView.rawValue,
                       forKey: UserDefaultsKey.startView.rawValue)
      photoData.startView = self.starView
    }
    // 0. uimode 설정 확인 및 뷰 전환
    if photoData.uiMode != self.uiMode {
      // step 0-0. 프로그레스뷰 띄우기
      NotificationCenter.default
        .post(name: .showProgressingView, object: nil)
      // step 0-1. 변경값 저장하기
      userDefaults
        .set(uiMode.rawValue,
             forKey: UserDefaultsKey.uimode.rawValue)
      // step 0-2. ui 변경하기
      DispatchQueue.main
        .asyncAfter(deadline: .now() + 0.4) {
          withAnimation {
            photoData.uiMode = self.uiMode
          }
        }
    }
    // 1. 오프닝애니 사용 설정 체크
    if photoData.useOpeningAni != self.useOpeningAni {
      userDefaults.setValue(
        self.useOpeningAni,
        forKey: UserDefaultsKey.useOpeningAni.rawValue)
      photoData.useOpeningAni = self.useOpeningAni
    }
    // 2. 노크 기능 사용 설정 체크
    if photoData.useKnock != self.useKnock {
      userDefaults.setValue(
        self.useKnock,
        forKey: UserDefaultsKey.useKnock.rawValue)
      photoData.useKnock = self.useKnock
    }
    // 3. 디지털 액자 랜덤 플레이 체크
    if photoData.digitalShowRandom != self.isRandomPlay {
      userDefaults.setValue(
        self.isRandomPlay,
        forKey: UserDefaultsKey.digitalShowRandom.rawValue)
      photoData.digitalShowRandom = self.isRandomPlay
    }
    // 4. 디지털 액자 전환 시간 체크
    if photoData.transitionIndex != self.transitionIndex {
      userDefaults.setValue(
        self.transitionIndex,
        forKey: UserDefaultsKey.transitionIndex.rawValue)
      photoData.transitionIndex = self.transitionIndex
    }
    // 5. 최신 공지 체크
    if !photoData.userReadDone {
      userDefaults.setValue(
        true,
        forKey: UserDefaultsKey.userReadDone.rawValue)
      photoData.userReadDone = true
    }
    withAnimation {
      isShowing = false
    }
  }
  
  func changeChecker(_ checker0: Tabs,
                     _ checker1: UIMode,
                     _ checker2: Bool,
                     _ checker3: Bool,
                     _ checker4: Bool,
                     _ checker5: Int) -> Bool {
    let checker0 = checker0 != photoData.startView
    let checker1 = checker1 != photoData.uiMode
    let checker2 = checker2 != photoData.useOpeningAni
    let checker3 = checker3 != photoData.useKnock
    let checker4 = checker4 != photoData.digitalShowRandom
    let checker5 = checker5 != photoData.transitionIndex
    return checker0 || checker1 || checker2 || checker3 || checker4 || checker5
  }
}

enum SettingList: String {
  case opening = "오프닝 애니메이션"
  case knock = "노크 기능"
}
enum GuideList: String, CaseIterable {
  case iphonPhoto = "아이폰 사진첩"
  case myLittleAlbum = "마이리틀앨범"
  case hiddenAssets = "가려진 사진 설정"
  case recentlyUpdated = "최근 업데이트된 기능"
}

#Preview {
  SettingView(isShowing: .constant(true),
              tutorialOn: .constant(false))
    .environmentObject(PhotoData())
}

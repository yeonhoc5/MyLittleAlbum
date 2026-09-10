//
//  MyLittleAlbumApp.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

@main
struct MyLittleAlbum: App {
  
  init() {
    // 1. User setting 초기값 세팅
    configUserSetting()
    // 2. hide native Tabbar for Custom tabbar
    settingTabbar()
    // 3. 네비게이션 설정
    settingNavigationBar()
    // 4. detailView 하단 Toolbar 설정
    settingDetailViewToolBar()
    // 5. textField clear button
    settingTextField()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(MLPhotoData())
        .environment(\.horizontalSizeClass, .compact)
        .modify { view in
          if #available(iOS 18.0, *) {
            view.preferredColorScheme(.dark)
          } else {
            view
          }
        }
    }
  }
}

// MARK: - setting functions
extension MyLittleAlbum {
  // 1. 유저 세팅 정보 로딩 - 디폴트값 세팅
  func configUserSetting() {
    let userDefaults: UserDefaults = .standard
    let existingUser = userDefaults.bool(forKey: "existingUser")
    print("0. existing User? : \(existingUser ? "Yes" : "No")")
//    print("1. premium User? : \(photoData.isPremium ? "Yes" : "No")")
    if !existingUser {
      userDefaults
        .register(defaults: [UserDefaultsKey.startView.rawValue: Tabs.album.rawValue])
      userDefaults
        .register(defaults: [UserDefaultsKey.uimode.rawValue: UIMode.modern.rawValue])
      userDefaults
        .register(defaults: [UserDefaultsKey.useOpeningAni.rawValue: false])
      userDefaults
        .register(defaults: [UserDefaultsKey.useKnock.rawValue: true])
      userDefaults  // 5초
        .register(defaults: [UserDefaultsKey.transitionIndex.rawValue: 2])
      userDefaults
        .register(defaults: [UserDefaultsKey.digitalShowRandom.rawValue: true])
      userDefaults
        .register(defaults: [UserDefaultsKey.userReadDone.rawValue: true])
    }
  }
  
  // 2. 탭바 - 커스텀 탭바 사용 위해 숨김
  func settingTabbar() {
    let tabBarAppearance = UITabBar.appearance()
    tabBarAppearance.isHidden = true
    tabBarAppearance.frame = .zero
  }
  
  // 3. 네비게이션 - 컬러 FancybackgroundColor
  func settingNavigationBar() {
    let appearanceScroll = UINavigationBarAppearance()
    let appearanceStandard = UINavigationBarAppearance()
    
    appearanceScroll.configureWithTransparentBackground()
    appearanceStandard.configureWithTransparentBackground()
    [appearanceScroll, appearanceStandard].forEach {
//      if #available(iOS 26, *) {
        $0.backgroundColor = UIColor(Color.clear)
//      } else {
//        $0.backgroundColor = UIColor(Color.fancyBackground)
//      }
      $0.shadowColor = UIColor.clear
      $0.titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    let naviAppearance = UINavigationBar.appearance()
    naviAppearance.standardAppearance = appearanceStandard
    naviAppearance.scrollEdgeAppearance = appearanceScroll
  }
  
  // 4. 미디어 디테일뷰 툴바 배경 - 투명
  func settingDetailViewToolBar() {
    let appearance = UIToolbarAppearance()
    appearance.configureWithTransparentBackground()
    let toolBarAppearance = UIToolbar.appearance()
    toolBarAppearance.standardAppearance = appearance
  }
  
  // 5. textField에 클리어 버튼
  func settingTextField() {
    UITextField.appearance().clearButtonMode = .whileEditing
  }
}

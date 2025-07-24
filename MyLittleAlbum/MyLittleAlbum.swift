//
//  MyLittleAlbumApp.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

@main
struct MyLittleAlbum: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MLPhotoData())
        }
    }
    
    init() {
        // 1. User setting 초기값 세팅
        configUserSetting()
        // 2. custom Tabbar 설정
        settingTabbar()
        // 3. 네비게이션 설정
        settingNavigationBar()
        // 4. detailView 하단 Toolbar 설정
        settingDetailViewToolBar()
        // 5. textField clear button
        settingTextField()
    }
}

// MARK: - setting functions
extension MyLittleAlbum {
    // 1. 유저 세팅 정보 로딩 - 디폴트값 세팅
    func configUserSetting() {
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.startView.rawValue: Tabs.album.rawValue])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.uimode.rawValue: UIMode.modern.rawValue])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.useOpeningAni.rawValue: true])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.useKnock.rawValue: true])
        UserDefaults.standard  // 5초
            .register(defaults: [UserDefaultsKey.transitionIndex.rawValue: 2])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.digitalShowRandom.rawValue: true])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.userReadDone.rawValue: false])
    }
    
    // 2. 탭바 - 커스텀 탭바 사용 위해 숨김
    func settingTabbar() {
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.isHidden = true
    }
    
    // 3. 네비게이션 - 컬러 FancybackgroundColor
    func settingNavigationBar() {
        let appearanceScroll = UINavigationBarAppearance()
        let appearanceStandard = UINavigationBarAppearance()
        
        appearanceScroll.configureWithTransparentBackground()
        appearanceStandard.configureWithTransparentBackground()
        [appearanceScroll, appearanceStandard].forEach {
            $0.backgroundColor = UIColor(Color.fancyBackground)
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
        UITextField.appearance()
            .clearButtonMode = .whileEditing
    }
}

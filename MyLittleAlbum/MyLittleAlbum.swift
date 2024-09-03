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
        // User setting 초기값 세팅
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.uimode.rawValue: UIMode.modern.rawValue])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.useOpeningAni.rawValue: true])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.useKnock.rawValue: true])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.transitionIndex.rawValue: 2]) // 5초
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.digitalShowRandom.rawValue: true])
        UserDefaults.standard
            .register(defaults: [UserDefaultsKey.userReadDone.rawValue: false])
        
        // custom Tabbar 사용 설정
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.isHidden = true
        
        // 네비게이션 설정
        let appearanceScroll = UINavigationBarAppearance()
        let appearanceStandard = UINavigationBarAppearance()
        [appearanceStandard, appearanceScroll].forEach {
            $0.shadowColor = UIColor(patternImage: UIImage())
            $0.shadowImage = UIImage()
            $0.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
        appearanceScroll.backgroundColor = UIColor(Color.fancyBackground)
        appearanceStandard.backgroundColor = UIColor(Color.fancyBackground).withAlphaComponent(0.7)
        let naviAppearance = UINavigationBar.appearance()
        naviAppearance.standardAppearance = appearanceStandard
        naviAppearance.scrollEdgeAppearance = appearanceScroll
        
        // 알럿 컬러 설정 : dark로
        UIView
            .appearance(whenContainedInInstancesOf: [UIAlertController.self])
            .overrideUserInterfaceStyle = .dark
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(PhotoData())
                .preferredColorScheme(.dark)
        }
    }
}

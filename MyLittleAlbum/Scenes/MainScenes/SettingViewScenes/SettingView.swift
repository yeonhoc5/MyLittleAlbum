//
//  SettingView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/09.
//

import SwiftUI

enum SettingList: String {
    case opening = "오프닝 애니메이션"
    case knock = "노크 기능"
}
enum GuideList: String, CaseIterable {
    case iphonPHoto = "아이폰 사진첩"
    case myLittleAlbum = "마이리틀앨범"
    case hiddenAssets = "가려진 사진 설정"
    case recentlyUpdated = "최근 업데이트된 기능"
}

struct SettingView: View {
    @EnvironmentObject var photoData: PhotoData
    @State var uiMode: UIMode = .modern
    @State var useOpeningAni: Bool = false
    @State var useKnock: Bool = false
    
    @Binding var isShowingSettingView: Bool
    
    @State var transitionIndex: Int = 2
    @State var isShowingSettingGuide: Bool = false
    @State var settingList: SettingList = .opening
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0, content: {
                FunctionSettingView(header: {
                    headerText(str: "1. 기능 설정")
                },
                    uiMode: $uiMode,
                    useOpeningAni: $useOpeningAni,
                    settingList: $settingList,
                    useKnock: $useKnock,
                    transitionIndex: $transitionIndex,
                    isShowingSettingGuide: $isShowingSettingGuide
                )
            })
//            .navigationTitle("나의 앨범 세팅하기")
            .navigationBarTitleDisplayMode(.inline)
            .background {
                Color.fancyBackground
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        saveSetting()
                    }
                }
            }
        }
        .onAppear {
            loadPreviousSetting()
        }
        .onChange(of: photoData.uiModeChanged) { newValue in
            if newValue == true {
                withAnimation {
                    isShowingSettingView = false
                }
                DispatchQueue.main.async {
                    saveUIMode(uiMode: uiMode)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            photoData.uiModeChanged = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingView(isShowingSettingView: .constant(true))
        .environmentObject(PhotoData())
}


extension SettingView {
    
    func loadPreviousSetting() {
        uiMode = photoData.uiMode
        useOpeningAni = photoData.useOpeningAni
        useKnock = photoData.useKnock
        transitionIndex = photoData.transitionIndex
    }
    
    func saveSetting() {
        let userDefaults = UserDefaults.standard

        // 2. uimode 설정 체크
        if photoData.useOpeningAni != self.useOpeningAni {
            userDefaults.setValue(self.useOpeningAni,
                                  forKey: UserDefaultsKey.useOpeningAni.rawValue)
        }
//        // 3. 오프닝애니 사용 설정 체크
        if photoData.useKnock != self.useKnock {
            userDefaults.setValue(self.useKnock, forKey: UserDefaultsKey.useKnock.rawValue)
            photoData.useKnock = self.useKnock
        }
//        // 4. 노크 기능 사용 설정 체크
        if photoData.transitionIndex != self.transitionIndex {
            userDefaults.setValue(self.transitionIndex,
                                  forKey: UserDefaultsKey.transitionIndex.rawValue)
            photoData.transitionIndex = self.transitionIndex
        }
//        // 5. 최신 공지 체크
        if !photoData.userReadDone {
            userDefaults.setValue(true, forKey: UserDefaultsKey.userReadDone.rawValue)
            photoData.userReadDone = true
        }
        
        // 1. uimode 설정 확인 및 뷰 전환
        if photoData.uiMode != self.uiMode {
            photoData.uiModeChanged = true
        } else {
            withAnimation {
                isShowingSettingView = false
            }
        }
        
    }
    
    func saveUIMode(uiMode: UIMode) {
        DispatchQueue.main.async {
            photoData.setUIMode(uimode: uiMode)
        }
    }
    
    func headerText(str: String) -> some View {
        Text(str)
            .foregroundStyle(Color.white)
            .font(.caption )
            .offset(x: -10)
    }
}

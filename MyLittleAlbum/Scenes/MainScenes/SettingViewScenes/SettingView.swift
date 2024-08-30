//
//  SettingView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/09.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var photoData: PhotoData
    @Binding var isShowingSettingView: Bool
    // 기능 설정 프라퍼티
    @State var uiMode: UIMode = .modern
    @State var useOpeningAni: Bool = true
    @State var useKnock: Bool = true
    @State var isRandomPlay: Bool = true
    @State var transitionIndex: Int = 2
    // 가이드 프라퍼티
    @State var settingList: SettingList = .opening
    @State var isShowingSettingGuide: Bool = false
    
    var body: some View {
        VStack(spacing: 0, content: {
//            if device != .phone {
                titleViewForPAD
//            }
            Form(content: {
                SectionFundamentalView(header: {
                    headerText(str: "1. 기본 설정")
                },
                    uiMode: $uiMode,
                    useOpeningAni: $useOpeningAni,
                    settingList: $settingList,
                    useKnock: $useKnock,
                    isShowingSettingGuide: $isShowingSettingGuide
                )
                SectionDigitalView(header: {
                    headerText(str: "2. 디지털 액자 설정")
                },
                    isRandom: $isRandomPlay,
                    transitionIndex: $transitionIndex)
            })
            .foregroundStyle(Color.fancyBackground)
            .scrollContentBackground(.hidden)
            .clipped()
            .shadow(radius: 3)
        })
        .overlay(alignment: .bottom, content: {
            btnDone
                .opacity(isShowingSettingGuide ? 0 : 1)
        })
        .background {
            switch device {
            case .phone:  Color.fancyBackground
                    .ignoresSafeArea()
            default:
                ZStack(content: {
                    Color.fancyBackground
                    Color.white.opacity(0.7)
                })
                .cornerRadius(20)
            }
        }
        .onAppear {
            loadPreviousSetting()
        }
        .onChange(of: photoData.uiModeChanged) { newValue in
            saveAndApplyUIChange(newValue)
        }
    }
}

#Preview {
    SettingView(isShowingSettingView: .constant(true))
        .environmentObject(PhotoData())
}

// subViews
extension SettingView {
    
    var titleViewForPAD: some View {
        Text("앨범 세팅")
            .font(.title2)
            .foregroundStyle(device == .phone ? Color.white : Color.black)
            .padding(.top, 20)
    }
    
    func headerText(str: String) -> some View {
        Text(str)
            .foregroundStyle(device == .phone ? Color.white : Color.black)
            .font(.caption )
            .offset(x: -10)
    }
    
    var btnDone: some View {
        Button {
            saveSetting()
        } label: {
            Capsule()
                .fill(.white)
                .frame(height: 50)
                .frame(maxWidth: 600)
                .padding(20)
                .overlay {
                    Text("완료")
                        .foregroundStyle(changeChecker(
                            self.uiMode,
                            self.useOpeningAni,
                            self.useKnock,
                            self.isRandomPlay,
                            self.transitionIndex)
                                         ? .blue : .black)
                }
                .clipped()
                .shadow(radius: 3)
        }
    }
}

// functions
extension SettingView {
    
    func loadPreviousSetting() {
        uiMode = photoData.uiMode
        useOpeningAni = photoData.useOpeningAni
        useKnock = photoData.useKnock
        isRandomPlay = photoData.digitalShowRandom
        transitionIndex = photoData.transitionIndex
    }
    
    func saveSetting() {
        let userDefaults = UserDefaults.standard
        // 1. 오프닝애니 사용 설정 체크
        if photoData.useOpeningAni != self.useOpeningAni {
            userDefaults
                .setValue(self.useOpeningAni,
                          forKey: UserDefaultsKey.useOpeningAni.rawValue)
            photoData.useOpeningAni = self.useOpeningAni
        }
        // 2. 노크 기능 사용 설정 체크
        if photoData.useKnock != self.useKnock {
            userDefaults
                .setValue(self.useKnock,
                          forKey: UserDefaultsKey.useKnock.rawValue)
            photoData.useKnock = self.useKnock
        }
        // 3. 디지털 액자 랜덤 플레이 체크
        if photoData.digitalShowRandom != self.isRandomPlay {
            userDefaults
                .setValue(self.isRandomPlay,
                          forKey: UserDefaultsKey.digitalShowRandom.rawValue)
            photoData.digitalShowRandom = self.isRandomPlay
        }
        // 4. 디지털 액자 전환 시간 체크
        if photoData.transitionIndex != self.transitionIndex {
            userDefaults
                .setValue(self.transitionIndex,
                          forKey: UserDefaultsKey.transitionIndex.rawValue)
            photoData.transitionIndex = self.transitionIndex
        }
        // 5. 최신 공지 체크
        if !photoData.userReadDone {
            userDefaults
                .setValue(true,
                          forKey: UserDefaultsKey.userReadDone.rawValue)
            photoData.userReadDone = true
        }
        
        //  uimode 설정 확인 및 뷰 전환
        if photoData.uiMode != self.uiMode {
            photoData.uiModeChanged = true
        }
        withAnimation {
            isShowingSettingView = false
        }
    }
    
    func saveAndApplyUIChange(_ changed: Bool) {
        if changed {
            DispatchQueue.main.async {
                photoData.setUIMode(uimode: uiMode)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        photoData.uiModeChanged = false
                    }
                }
            }
        }
    }
    
    func changeChecker(_ checker1: UIMode,
                       _ checker2: Bool,
                       _ checker3: Bool,
                       _ checker4: Bool,
                       _ checker5: Int) -> Bool {
        let checker1 = checker1 != photoData.uiMode
        let checker2 = checker2 != photoData.useOpeningAni
        let checker3 = checker3 != photoData.useKnock
        let checker4 = checker4 != photoData.digitalShowRandom
        let checker5 = checker5 != photoData.transitionIndex
        return checker1 || checker2 || checker3 || checker4 || checker5
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

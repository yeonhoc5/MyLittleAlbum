//
//  SettingView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/09.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var photoData: PhotoData
    @State var uiMode: UIMode = .modern
    @State var uiModeChanged: Bool = false
    @Binding var isShowingSettingView: Bool
    
    var body: some View {
        let isVertical: Bool = screenSize.width < screenSize.height
        let currentUI: UIMode = photoData.uiMode
        let verticalWidth = min(screenSize.width, screenSize.height) - 40
        let horizontalWidth = (screenSize.width - 40) / 2
        NavigationView {
            ZStack {
                // 1. 백그라운드 뷰
                FancyBackground()

                // 2. 메인 - 세로모드 / 가로모드 뷰
                if isVertical {
                    VStack {
                        formView
                            .frame(width: verticalWidth - 50, height: 100)
                        sampleView
                            .frame(width: verticalWidth, height: screenSize.height / 2.5)
                        settingDoneButton(currentUI: currentUI, verticalWidth: verticalWidth)
                            .frame(width: verticalWidth - 50, height: 50)
                    }
                } else {
                    HStack(spacing: 50) {
                        sampleView
                            .frame(width: verticalWidth, height: screenSize.height - 40)
                        VStack {
                            formView
                                .frame(width: horizontalWidth - 50, height: 150)
                            settingDoneButton(currentUI: currentUI, verticalWidth: verticalWidth)
                            .frame(width: horizontalWidth, height: 50)
                        }
                    }
                }
                
                // 3. 저장 시 프로그래스 뷰
                if uiModeChanged {
                    CustomProgressView(stateChangeObject: StateChangeObject(),
                                       color: uiMode == .classic ? .orange : colorSet[0])
                        .onAppear {
                            saveUIMode(uiMode: uiMode)
                        }
                }
            }
            .navigationTitle("UI 세팅")
            .navigationBarTitleDisplayMode(.inline)
        }
        .edgesIgnoringSafeArea(.trailing)
        .onAppear {
            uiMode = photoData.uiMode
        }
        .onChange(of: currentUI) { newValue in
            if newValue == uiMode {
                uiModeChanged = false
                withAnimation {
                    isShowingSettingView = false
                }
            }
        }
    }
    
    
    
}
    

extension SettingView {
    // subView 1. 선택 버튼 뷰
    var formView: some View {
        VStack(alignment: .leading) {
            Section("레이아웃 선택") {
                Picker("UI", selection: $uiMode) {
                    ForEach(UIMode.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .background(content: {
                    Color.white
                })
                .onAppear{
                    UISegmentedControl.appearance().backgroundColor = .clear
                    UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.fancyBackground)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.fancyBackground)], for: .normal)
                }
            }
            .cornerRadius(6)
            .foregroundColor(.white)
        }
    }
    // subView 2. 샘플 뷰
    var sampleView: some View {
        VStack(spacing: 10) {
            if uiMode == .fancy {
                HStack {
                    FancyCell(cellType: .album, title: "앨범1", colorIndex: 0, rprstPhoto1: nil, rprstPhoto2: nil, sampleCase: .overTwo)
                    FancyCell(cellType: .album, title: "앨범2", colorIndex: 1, rprstPhoto1: nil, rprstPhoto2: nil, sampleCase: .one)
                    FancyCell(cellType: .album, title: "앨범2", colorIndex: 2, rprstPhoto1: nil, rprstPhoto2: nil)
                }
                HStack(alignment: .bottom) {
                    FancyCell(cellType: .folder, title: "폴더", colorIndex: 0, rprstPhoto1: nil, rprstPhoto2: nil)
                    Group {
                        FancyCell(cellType: .miniAlbum, title: "미니앨범1", colorIndex: 4, rprstPhoto1: nil, rprstPhoto2: nil, sampleCase: .one)
                        FancyCell(cellType: .miniAlbum, title: "미니앨범2", colorIndex: 8, rprstPhoto1: nil, rprstPhoto2: nil)
                    }
                    .frame(height: 100)
                }
            } else if uiMode == .modern {
                HStack {
                    ModernCell(cellType: .album, title: "앨범1", sampleCase: .one)
                    ModernCell(cellType: .album, title: "앨범2")
                }
                HStack(alignment: .bottom) {
                    ModernCell(cellType: .folder, title: "폴더")
                    Group {
                        ModernCell(cellType: .miniAlbum, title: "미니앨범1", sampleCase: .one)
                        ModernCell(cellType: .miniAlbum, title: "미니앨범2")
                    }
                    
                }
            } else if uiMode == .classic {
                HStack {
                    ClassicCell(cellType: .album, width: 100, height: 100, sampleCase: .one)
                    ClassicCell(cellType: .album, width: 100, height: 100)
                }
                HStack {
                    ClassicCell(cellType: .folder)
                    ClassicCell(cellType: .album, width: 80, height: 60, sampleCase: .one)
                    ClassicCell(cellType: .album, width: 80, height: 60)
                }
            }
        }
        .padding(.bottom, 20)
    }
    // subView 3. 저장 / 돌아가기 버튼 뷰
    func settingDoneButton(currentUI: UIMode, verticalWidth: CGFloat) -> some View {
        Button {
            if currentUI != uiMode {
                uiModeChanged = true
                DispatchQueue.main.async {
                    saveUIMode(uiMode: uiMode)
                }
            } else {
                withAnimation {
                    isShowingSettingView = false
                }
            }
        } label: {
            BackButton(changed: uiMode == currentUI)
        }
        .buttonStyle(ClickScaleEffect())
    }
    
    // function - ui 저장하기
    func saveUIMode(uiMode: UIMode) {
        DispatchQueue.main.async {
            photoData.setUIMode(uimode: uiMode)
        }
    }
    
}

struct BackButton: View {
    var changed: Bool
    
    var body: some View {
        Capsule()
            .foregroundColor(.white)
            .overlay {
                Text(changed ? "돌아가기" : "레이아웃 바꾸기")
                    .foregroundColor(.fancyBackground)
            }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView(isShowingSettingView: .constant(false))
            .environmentObject(PhotoData())
    }
}

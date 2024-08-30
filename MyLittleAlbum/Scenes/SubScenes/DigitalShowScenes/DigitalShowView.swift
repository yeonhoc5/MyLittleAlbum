//
//  DigitalShowView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/11/23.
//

import SwiftUI
import Photos

enum DigitalShowStatus {
    case ready
    case playing
    case ended
}

struct DigitalShowView: View {
    @EnvironmentObject var photoData: PhotoData
    @State var title: String = ""
    @State var photosArray: [PHAsset] = []
    @State var digitalShowNumber: Int = 0
    @State var timer: Timer!
    var nameSpace: Namespace.ID
    @State var isShowingDigitalShowGuide: Bool = false
    
    @State var guideScale = 1.0
    @State var guideOpacity = 1.0
    @State var showStatus: DigitalShowStatus = .ready
    @State var startString = "의 디지털 액자 모드를 실행합니다."
    @State var endString = "디지털 액자 모드를 종료합니다."
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            backgroundView(nameSpace: nameSpace)
            if showStatus == .playing {
                DigitalImageView(asset: self.photosArray[digitalShowNumber],
                                 showStatus: showStatus)
                    .onAppear(perform: {
                        self.startDigitalShow()
                        self.showDigitalShowGuide()
                    })
            }
            if showStatus != .ended {
                startMessageView
            }
        }
        .overlay(alignment: .bottom) {
            guideView
                .padding(.bottom, device == .phone ? 20 : 30)
                .offset(y: isShowingDigitalShowGuide ? 0 : 200)
        }
        .gesture(TapGesture(count: 2).onEnded({ _ in
            if showStatus != .ended {
                withAnimation {
                    self.endDigitalShow()
                }
            }
        }))
        .onTapGesture {
            self.showDigitalShowGuide()
        }
        .overlay(alignment: .topTrailing, content: {
            btnEndShow
                .padding(.trailing, 20)
                .padding(.top, device == .phone ? 0 : 20)
                .offset(y: isShowingDigitalShowGuide ? 0 : -100)
        })
        .onChange(of: scenePhase) { newValue in
            if newValue != .active {
                if let timer = self.timer {
                    timer.invalidate()
                }
            } else {
                startDigitalShow()
            }
        }
    }
}

extension DigitalShowView {
    func backgroundView(nameSpace: Namespace.ID) -> some View {
        RoundedRectangle(cornerRadius: 20.0)
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .matchedGeometryEffect(id: "digitalShow", in: nameSpace)
            .overlay {
                if showStatus == .ended {
                    Text(endString)
                        .foregroundStyle(.white)
                }
            }
    }
    
    var btnEndShow: some View {
        Button {
            if showStatus != .ended {
                withAnimation {
                    self.endDigitalShow()
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThickMaterial)
                    .frame(width: 50, height: 40)
                Text("종료")
                    .foregroundStyle(.white)
            }
        }
    }
    
    @ViewBuilder
    var startMessageView: some View {
        Group {
            if device == .phone {
                VStack(alignment: .leading, spacing: 20) {
                    Text("ALBUM")
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\"\(photoData.digitalShowTitle)\"")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(showStatus == .ready ? startString : endString)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                HStack(alignment: .bottom, spacing: 5) {
                    HStack(alignment: .top, spacing: 10) {
                        Text("ALBUM")
                            .foregroundStyle(.white.opacity(0.7))
                        Text("\"\(photoData.digitalShowTitle)\"")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Text(showStatus == .ready ? startString : endString)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .scaleEffect(guideScale)
        .opacity(guideOpacity)
        .onAppear {
            makePhotosArray()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    if showStatus == .ready {
                        guideScale = 5.0
                        guideOpacity = 0
                        showStatus = .playing
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                guideScale = 1.0
                guideOpacity = 0.0
            }
        }
    }
    
    var guideView: some View {
        VStack(alignment: .leading, spacing: 10, content: {
            Text("1. 디지털액자 사용 시 화면 자동 꺼짐이 해제됩니다.")
            if device == .phone {
                Text("2. 디지털액자를 종료하려면 [종료] 버튼을 누르거나\n화면을 2번 탭해주세요.")
            } else {
                Text("2. 디지털액자를 종료하려면 [종료] 버튼을 누르거나 화면을 2번 탭해주세요.")
            }
        })
        .padding(20)
        .background(content: {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
        })
    }
    
    func makePhotosArray() {
        self.photosArray = photoData.digitalPhotoAlbums.compactMap {
            photoData.isHiddenAsset
            ? $0.hiddenAssetsArray : $0.photosArray
        }.flatMap { $0 }
        if photoData.digitalShowRandom {
            self.photosArray = self.photosArray.shuffled()
        }
    }
}

extension DigitalShowView {
    func startDigitalShow() {
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(transitionRange[photoData.transitionIndex]),
                                          repeats: true) { _ in
            if self.photosArray.count > 1 {
                withAnimation {
                    self.digitalShowNumber
                    = (self.digitalShowNumber + 1)
                    % self.photosArray.count
                }
            }
        }
    }
    
    func endDigitalShow() {
        DispatchQueue.main.async {
            withAnimation {
                self.showStatus = .ended
                self.isShowingDigitalShowGuide = false
                self.title = ""
                self.photosArray = []
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                photoData.endDisitalShow()
            }
        }
        
        if timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
        self.digitalShowNumber = 0
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    func showDigitalShowGuide() {
        withAnimation {
            self.isShowingDigitalShowGuide.toggle()
        }
        if isShowingDigitalShowGuide == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    if isShowingDigitalShowGuide == true {
                        self.isShowingDigitalShowGuide = false
                    }
                }
            }
        }
    }
    
    func slideGesture() -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                if value.translation.width < -100 {
                    withAnimation {
                        self.digitalShowNumber
                        = (self.digitalShowNumber + 1)
                        % self.photosArray.count
                    }
                } else if value.translation.width > 100 {
                    if self.digitalShowNumber > 0 {
                        withAnimation {
                            self.digitalShowNumber -= 1
                        }
                    } else {
                        withAnimation {
                            self.digitalShowNumber = self.photosArray.count - 1
                        }
                    }
                }
                self.timer = nil
                startDigitalShow()
            }
    }
}

#Preview {
    DigitalShowView(nameSpace: Namespace().wrappedValue)
        .environmentObject(PhotoData())
}

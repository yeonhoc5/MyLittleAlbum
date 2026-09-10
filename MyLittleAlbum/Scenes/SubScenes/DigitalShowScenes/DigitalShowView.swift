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
  case paused
}

struct DigitalShowView: View {
  @State var title: String
  @State var assetArray: [MLAsset]
  @State var digitalShowNumber: Int = 0
  @State var timer: Timer!
  var transitionSecond: Int
  var nameSpace: Namespace.ID
  @State var isShowingDigitalShowGuide: Bool = false
  
  @State var guideScale = 1.0
  @State var guideOpacity = 1.0
  @State var showStatus: DigitalShowStatus = .ready
  @State var startString = "의 디지털 액자 모드를 실행합니다."
  @State var endString = "디지털 액자 모드를 종료합니다."
  let imageManger = PHCachingImageManager()
  
  @Environment(\.scenePhase) var scenePhase
  
  var body: some View {
    ZStack {
      backgroundView(nameSpace: nameSpace)
      if showStatus == .playing {
        GeometryReader { geoProxy in
          DigitalImageView(
            asset: self.assetArray[digitalShowNumber],
            animationDirection: animationDirection(number: digitalShowNumber),
            showStatus: showStatus,
            cachingManager: imageManger,
            geometry: geoProxy
          )
          .onChange(of: digitalShowNumber, perform: { int in
            phImageQueue.async {
              imageManger.startCachingImages(
                for: [assetArray[(int + 1) % assetArray.count].phAsset],
                targetSize: geoProxy.size,
                contentMode: .aspectFit,
                options: nil)
              if int > 1 {
                imageManger.stopCachingImages(
                  for: [assetArray[int-2].phAsset],
                  targetSize: geoProxy.size,
                  contentMode: .aspectFit,
                  options: nil)
              }
            }
          })
        }
        .onAppear(perform: {
          self.startDigitalShow()
          self.showDigitalShowGuide()
        })
      }
      if showStatus != .ended {
        startMessageView
      }
    }
    .matchedGeometryEffect(id: "digitalShow", in: nameSpace, isSource: false)
    .overlay(alignment: .bottom) {
      guideView
        .padding(.bottom, device == .phone ? 20 : 30)
        .offset(y: isShowingDigitalShowGuide ? 0 : 220)
    }
    .gesture(TapGesture(count: 2)
      .onEnded({ _ in
        if showStatus != .ended {
          withAnimation {
            self.endDigitalShow()
          }
        }
      })
    )
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
          .availabeGlassEffect(cornerR: 20,
                               foreground: .ultraThinMaterial) { view in
            view.fill(.ultraThinMaterial)
          }
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
          Text("\"\(title)\"")
            .font(.system(size: 30, weight: .heavy))
            .foregroundStyle(Color.color3)
            .shadow(color: .black, radius: 4, x: 1, y: 1)
          Text(showStatus == .ready ? startString : endString)
            .foregroundStyle(.white.opacity(0.7))
        }
      } else {
        HStack(alignment: .bottom, spacing: 5) {
          HStack(alignment: .top, spacing: 10) {
            Text("ALBUM")
              .foregroundStyle(.white.opacity(0.7))
            Text("\"\(title)\"")
              .font(.system(size: 30, weight: .heavy))
              .foregroundStyle(Color.color3)
              .shadow(color: .black, radius: 4, x: 1, y: 1)
          }
          Text(showStatus == .ready ? startString : endString)
            .foregroundStyle(.white.opacity(0.7))
        }
      }
    }
    .scaleEffect(guideScale)
    .opacity(guideOpacity)
    .onAppear {
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
      Text("1. 디지털액자 사용 시 기기 자동 잠금이 해제됩니다.")
      if device == .phone {
        Text("2. 디지털액자를 종료하려면 [종료] 버튼을 누르거나\n화면을 2번 탭해주세요.")
      } else {
        Text("2. 디지털액자를 종료하려면 [종료] 버튼을 누르거나 화면을 2번 탭해주세요.")
      }
    })
    .padding(20)
    .foregroundStyle(.white)
    .background(content: {
      RoundedRectangle(cornerRadius: 20)
        .fill(.ultraThinMaterial)
    })
  }
}

extension DigitalShowView {
  func startDigitalShow() {
    self.timer = Timer.scheduledTimer(withTimeInterval: Double(transitionSecond),
                                      repeats: true) { _ in
      if self.assetArray.count > 1 {
        withAnimation {
          self.digitalShowNumber
          = (self.digitalShowNumber + 1)
          % self.assetArray.count
        }
      }
    }
    UIApplication.shared.isIdleTimerDisabled = true
  }
  
  func endDigitalShow() {
    DispatchQueue.main.async {
      withAnimation {
        self.showStatus = .ended
        self.isShowingDigitalShowGuide = false
        self.title = ""
        self.imageManger.stopCachingImagesForAllAssets()
        self.assetArray = []
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      withAnimation {
        NotificationCenter.default
          .post(name: .endDigitalShow, object: nil)
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
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
      withAnimation {
        if isShowingDigitalShowGuide == true {
          self.isShowingDigitalShowGuide = false
        }
      }
    }
  }
  
  func animationDirection(number: Int) -> [Edge] {
    switch number % 4 {
    case 0: return [.top, .leading]
    case 1: return [.trailing, .trailing]
    case 2: return [.leading, .top]
    default: return [.bottom, .bottom]
    }
  }
  
  func slideGesture() -> some Gesture {
    DragGesture(minimumDistance: 10)
      .onEnded { value in
        if value.translation.width < -100 {
          withAnimation {
            self.digitalShowNumber
            = (self.digitalShowNumber + 1)
            % self.assetArray.count
          }
        } else if value.translation.width > 100 {
          if self.digitalShowNumber > 0 {
            withAnimation {
              self.digitalShowNumber -= 1
            }
          } else {
            withAnimation {
              self.digitalShowNumber = self.assetArray.count - 1
            }
          }
        }
        self.timer = nil
        startDigitalShow()
      }
  }
}

#Preview {
  DigitalShowView(title: "디지털뷰",
                  assetArray: [],
                  transitionSecond: 5,
                  nameSpace: Namespace().wrappedValue)
  .environmentObject(PhotoData())
}

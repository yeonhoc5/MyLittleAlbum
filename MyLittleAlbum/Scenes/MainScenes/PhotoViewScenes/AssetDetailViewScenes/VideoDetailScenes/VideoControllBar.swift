//
//  VideoControllBar.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 8/20/25.
//

import SwiftUI
import AVKit

struct VideoControllBar: View {
  let isVideo: Bool
  let isPad: Bool
  let innerPadding = 10.0
  
  let duration: Double
  @Binding var playStatus: VideoState
  @Binding var videoMove: VideoMove
  @Binding var currentTime: Double
  @State var sliderValue: CFloat = 0
  @State var tempSliderPosition: CFloat = 0
  @Binding var mute: Bool
  let play2x: Bool
  @Binding var landscapePlay: Bool
  
  @Binding var userGesture: DetailViewGesture
  @Namespace var namespace
  let text = "2x"
  
  var body: some View {
    let iconSize: CGFloat = isPad ? 30 : 20
    conditionalStackView(condition: landscapePlay,
                         spacing: innerPadding) {
      Group {
        if device == .phone {
          btnRotationToggle(height: vcHeight,
                            iconSize: iconSize,
                            padding: innerPadding)
        }
        GeometryReader { geometry in
          let width = landscapePlay ? geometry.size.height : geometry.size.width
          ZStack {
            // 0. 백그라운드 슬라이더
            sliderBar(width: width / (device == .pad ? 3 : 1))
            conditionalStackView(condition: landscapePlay,
                                 spacing: 0) {
              Group {
                Spacer(minLength: 0)
                Group {
                  // 1. 중지 버튼
                  btnStopPlay(iconSize: iconSize,
                              padding: 5,
                              disabled: playStatus == .stop)
                  .rotationEffect(landscapePlay ? .degrees(90) : .zero)
                  Spacer(minLength: 0)
                  // 2. 뒤로 5초 버튼
                  btnBackward(iconSize: iconSize,
                              padding: 5,
                              disabled: currentTime == 0)
                  .rotationEffect(landscapePlay ? .degrees(90) : .zero)
                  Spacer(minLength: 1.0)
                  // 3. 플레이 / 중지 버튼
                  btnPlayToggle(iconSize: iconSize,
                                padding: 5)
                  .rotationEffect(landscapePlay ? .degrees(90) : .zero)
                  .overlay {
                    speedNoticeView
                      .scaleEffect(x: play2x ? 1 : 0)
                      .animation(
                        .spring(response: 0.2,
                                dampingFraction: play2x ? 0.4  : 1,
                                blendDuration: 0.9),
                        value: play2x)
                      .rotationEffect(landscapePlay
                                      ? .degrees(90) : .zero)
                  }
                  Spacer(minLength: 0)
                  // 4. 앞으로 5초 버튼
                  btnForward(iconSize: iconSize,
                             padding: 5,
                             disabled: currentTime == duration)
                  .opacity(userGesture == .videoSeeking ? 0 : 1)
                  .transition(.opacity)
                  .animation(.linear,
                             value: userGesture == .videoSeeking)
                  .rotationEffect(landscapePlay
                                  ? .degrees(90) : .zero)
                  Spacer(minLength: 0)
                }
              }
            }
            .padding(.horizontal, 5)
            .disabled(userGesture == .videoSeeking)
          }
          .simultaneousGesture(
            seekGesture(width: width / (device == .pad ? 3 : 1))
          )
        }
        .background(alignment: landscapePlay
                              ? .topTrailing : .topLeading) {
          HStack(alignment: .lastTextBaseline, spacing: 3) {
            let entireTime = Double(duration.rounded())
            // 1-1. 재생 시간
            processingText(
              time: durationString(entire: entireTime,
                                   time: currentTime),
              needAnimation: true)
            // 1-2. 영상 전체 시간
            processingText(needSlash: true,
                           time: durationString(entire: entireTime,
                                                time: entireTime))
          }
          .offset(x: 5, y: isVideo ? -20 : 0)
          .rotationEffect(landscapePlay ? .degrees(90) : .zero)
        }
        btnMuteToggle(mute: mute,
                      height: vcHeight,
                      iconSize: iconSize,
                      padding: 5)
        .rotationEffect(landscapePlay ? .degrees(90) : .zero)
      }
    }
    .foregroundColor(.white)
    .onChange(of: currentTime) { newValue in
      if newValue < duration {
        DispatchQueue.main.async {
          if newValue == 0 {
            self.sliderValue = 0
          } else {
            withAnimation {
              self.sliderValue = Float(newValue / duration)
            }
          }
        }
      } else {
        DispatchQueue.main.async {
          if duration == 0 {
            self.sliderValue = 0.00
          } else {
            withAnimation {
              self.sliderValue = 1.00
              self.playStatus = .stop
            }
          }
        }
      }
    }
  }
}

//#Preview {
//    VideoControllBar()
//}


extension VideoControllBar {
  var speedNoticeView: some View {
    HStack {
      Text("2x")
        .bold()
        .fixedSize(horizontal: true, vertical: false)
      Image(systemName: "forward.fill")
    }
    .foregroundStyle(.white)
    .modify { content in
      if #available(iOS 18.0, *) {
        content
          .symbolEffect(.bounce)
      }
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 15)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .foregroundStyle(Color.color6)
    }
  }
  func sliderBar(width: CGFloat) -> some View {
    ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 10)
        .fill(.ultraThinMaterial)
      Rectangle()
        .fill(Color.white.opacity(0.2))
        .frame(width: landscapePlay
               ? vcHeight : (width * CGFloat(sliderValue)))
        .frame(height: landscapePlay
               ? width * CGFloat(sliderValue) : vcHeight)
    }
    .mask(
      RoundedRectangle(cornerRadius: 10)
    )
  }
  // 버튼 1/4. 재생 토글
  func btnPlayToggle(iconSize: CGFloat, padding: CGFloat) -> some View {
    return Button {
      if userGesture != .videoSeeking {
        if sliderValue == 1.0 {
          sliderValue = 0
        }
        // play & pasue by button
        withAnimation(.interactiveSpring()) {
          playStatus = playStatus != .play ? .play : .pause
        }
      }
    } label: {
      LabelPlayAndPause(
        isPlaying: .constant(playStatus == .play),
        iconSize: iconSize
      )
      .modify { content in
        if #available(iOS 17.0, *) {
          content
            .contentTransition(.symbolEffect)
        }
      }
      .padding(.vertical, padding)
      .padding(.horizontal, padding / 2)
    }
  }
  func btnStopPlay(iconSize: CGFloat,
                   padding: CGFloat,
                   disabled: Bool = false) -> some View {
    Button {
      withAnimation {
        playStatus = .stop
      }
      setCurrentState(current: 0)
    } label: {
      imageScaledFit(systemName: "stop.fill", width: iconSize, height: iconSize)
        .padding(.vertical, padding)
        .padding(.horizontal, padding / 2)
    }
    .disabled(disabled)
    .opacity(disabled ? 0.2 : 1)
  }
  // 버튼 2/4. 뒤로 5초
  func btnBackward(iconSize: CGFloat,
                   padding: CGFloat,
                   disabled: Bool) -> some View {
    Button {
      if userGesture != .videoSeeking {
        currentTime = currentTime <= 5 ? 0 : (currentTime - 5)
        dispatchAnimation {
          videoMove = .backward
        }
      }
    } label: {
      ZStack(alignment: .center) {
        imageScaledFit(systemName: "gobackward", width: iconSize, height: iconSize)
          .offset(y: -1.5)
          .rotationEffect(videoMove == .backward
                          ? .degrees(-360.0) : .degrees(0))
        Text("5")
          .font(.caption2)
          .modify { view in
            if #available(iOS 16.1, *) {
              view
                .fontDesign(.rounded)
            }
          }
      }
      .padding(.vertical, padding)
      .padding(.horizontal, padding / 2)
    }
    .disabled(disabled)
    .opacity(disabled ? 0.2 : 1)
  }
  // 버튼 3/4. 앞으로 5초
  func btnForward(iconSize: CGFloat,
                  padding: CGFloat,
                  disabled: Bool) -> some View {
    Button {
      if userGesture != .videoSeeking {
        currentTime = (duration - currentTime <= 5) ? duration : (currentTime + 5)
        dispatchAnimation {
          videoMove = .forward
        }
      }
    } label: {
      ZStack(alignment: .center) {
        imageScaledFit(systemName: "goforward", width: iconSize, height: iconSize)
          .offset(y: -1.5)
          .rotationEffect(videoMove == .forward
                          ? .degrees(360.0) : .degrees(0))
        Text("5")
          .font(.caption2)
          .modify { view in
            if #available(iOS 16.1, *) {
              view
                .fontDesign(.rounded)
            }
          }
      }
      .padding(.vertical, padding)
      .padding(.horizontal, padding / 2)
    }
    .disabled(disabled)
    .opacity(disabled ? 0.2 : 1)
  }
  // 버튼 4/4. 뮤트 토글
  func btnMuteToggle(mute: Bool,
                     height: CGFloat,
                     iconSize: CGFloat,
                     padding: CGFloat) -> some View {
    let muteIcon = mute ? "speaker.slash.fill" : "speaker.wave.2.fill"
    return Button {
      if userGesture != .soundAdjusting
          && userGesture != .videoSeeking {
        withAnimation(.interactiveSpring()) {
          self.mute.toggle()
        }
      }
    } label: {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(.ultraThinMaterial)
        imageScaledFit(systemName: muteIcon,
                       width: iconSize,
                       height: iconSize)
        .padding(padding)
        .matchedGeometryEffect(id: "mute", in: namespace)
        .modify { content in
          if #available(iOS 17.0, *) {
            content
              .contentTransition(.symbolEffect(.replace))
          }
        }
      }
    }
    .frame(width: height, height: height)
  }
  // 버튼 4/4. 뮤트 토글
  func btnRotationToggle(height: CGFloat,
                         iconSize: CGFloat,
                         padding: CGFloat) -> some View {
    let rotateIcon = landscapePlay
          ? "arrow.up.right.and.arrow.down.left.rectangle.fill"
          : "arrow.down.left.and.arrow.up.right.rectangle.fill"
    return Button {
      dispatchAnimation {
        self.landscapePlay.toggle()
      }
    } label: {
      ZStack {
        RoundedRectangle(cornerRadius: 10)
          .fill(.ultraThinMaterial)
        imageScaledFit(systemName: rotateIcon,
                       width: iconSize,
                       height: iconSize)
        .id("rotationIcon")
        .contentTransition(.interpolate)
        .padding(padding)
      }
    }
    .frame(width: height, height: height)
  }
  func processingText(needSlash: Bool = false, time: String, needAnimation: Bool = false) -> some View {
    HStack(spacing: 3) {
      if needSlash {
        Text("/")
      }
      Text(time)
    }
    .font(.system(.subheadline, design: .monospaced))
    .modify({ view in
      if needAnimation {
        view
          .contentTransition(.numericText())
      } else {
        view
      }
    })
    .foregroundStyle(.gray)
  }
  
  // video seek Gestrue
  func seekGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 1)
      .onChanged { newValue in
        if userGesture != .videoSeeking {
          userGesture = .videoSeeking
          tempSliderPosition = sliderValue
        }
        let movedWidth = CGFloat(
          (landscapePlay ? newValue.translation.height
                          : newValue.translation.width)
                                 / (width * 0.5))
        let movePercent = tempSliderPosition + Float(movedWidth)
        let value = movePercent < 0 ? 0 : (movePercent > 1 ? 1 : movePercent)
        dispatchAnimation {
          currentTime = duration * Double(value)
        }
      }
      .onEnded { newValue in
        tempSliderPosition = 0
        userGesture = .none
      }
  }
  // 3-2. 재생시간
  // 비디오 재생시간 All Cases
  //    시간     case 1.  0:00:02 / 11:05:05
  //    시간     case 2.  0:00:02 / 1:05:10
  //    분      case 3.    00:02 / 11:04
  //    분      case 4.     0:02 / 5:14
  //    초      case 5.     0:02 / 0:05
  func durationString(entire: Double, time: Double) -> String {
    guard !(time.isNaN || time.isInfinite) else { return "illegal value" }
    let duration: Int = Int(time / 1.0)
    let hour: String = entire < 3600 ? "" : (duration >= 3600 ? "\(duration / 3600):" : "0:")
    let minute: String = ((entire >= 600 && ((duration) % 3600) / 60 < 10) ? "0" : "") + "\(((duration) % 3600) / 60):"
    let second: String = (duration) % 60 >= 10 ? "\((duration) % 60)" : "0\((duration) % 60)"
    return hour + minute + second
  }
  func setCurrentState(current: Double) {
    DispatchQueue.main.async {
      self.currentTime = current
    }
  }
}

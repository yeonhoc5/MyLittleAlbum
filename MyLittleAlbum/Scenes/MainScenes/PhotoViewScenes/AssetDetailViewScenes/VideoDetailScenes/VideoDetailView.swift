//
//  VideoDetailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/31.
//

import SwiftUI
import Photos
import AVKit
import CoreHaptics
import MediaPlayer
import LottieUI

enum VideoState {
  case play, pause, stop, processPause
}
enum VideoMove {
  case none, backward, forward
}
enum VideoNeeds {
  case none, offset, opacity
}
struct VideoDetailView<TempView: View>: View {
  var isDigitalShow: Bool = false
  @Environment(\.scenePhase) var scenePhase
  let offsetIndex: Int
  let asset: MLAsset
  let imageManager: PHCachingImageManager
  let geometry: GeometryProxy
  @Namespace var nameSpace
  
  // video properties
  @State var avPlayer: AVPlayer!
  @Binding var playStatus: VideoState
  @Binding var videoMove: VideoMove
  let videoNeeds: VideoNeeds
  @State var videoPadding: CGFloat = 0
  let play2x: Bool
  @State var mute: Bool = false
  let landscapeVideo: Bool
  let hideTools: Bool
  @State var timeObserver: Any!
  
  @Binding var userGesture: DetailViewGesture
  @Binding var currentTime: Double
  @State var tempSliderPosition: Float = 0
  @State var isLandscape: Bool = false
  let tempView: () -> TempView
  
  var body: some View {
    let size = CGSize(
      width: landscapeVideo ? geometry.size.height : geometry.size.width,
      height: landscapeVideo ? geometry.size.width : geometry.size.height)
    Group {
      if let player = self.avPlayer {
        AVPlayerController(player: player)
          .frame(width: size.width, height: size.height)
          .rotationEffect(landscapeVideo ? .degrees(90) : .zero)
          .offset(y: hideTools ? -videoPadding : 0)
          .onAppear(perform: {
            if isDigitalShow {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                player.play()
              }
            } else {
              if videoNeeds == .offset {
                self.videoPadding = videoOffset(
                  size: size,
                  asset: asset.phAsset
                )
              }
            }
          })
      } else {
        tempView()
          .onAppear {
            DispatchQueue.main.async {
              fetchingVideo(asset: asset.phAsset)
            }
          }
      }
    }
    .onDisappear {
      if offsetIndex == 0 || isDigitalShow {
        resetVideo(isFullEnded: true)
        removeObserver()
        if self.avPlayer != nil {
          print("video scene out")
          DispatchQueue.main.async {
            self.avPlayer = nil
          }
        }
      }
    }
    .onChange(of: play2x, perform: { newValue in
      if let player = self.avPlayer {
        if newValue == true {
          if playStatus != .play {
            addObserverToPlayer()
          }
          player.rate = 2
        } else {
          if playStatus == .play {
            player.rate = 1
          } else {
            player.pause()
            removeObserver()
          }
        }
      }
    })
    .onChange(of: mute, perform: { newValue in
      avPlayer.isMuted = newValue
    })
    .onChange(of: offsetIndex) { newValue in
      // 페이지 넘어가면 스탑 & 리셋
      if newValue != 0 {
        removeObserver()
        resetVideo(isFullEnded: true)
      } else {
        if playStatus == .play {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.timeObserver == nil {
              addObserverToPlayer()
            }
            // play & pasue by button
            if avPlayer.status == .readyToPlay {
              avPlayer.play()
            }
          }
        }
      }
    }
    .onChange(of: playStatus) { newValue in
      if let player = self.avPlayer {
        switch newValue {
        case .play:
          if self.timeObserver == nil {
            addObserverToPlayer()
          }
          player.play()
        case .pause, .processPause:
          player.pause()
        case .stop:
          DispatchQueue.main.async {
            resetVideo(isFullEnded: false)
            removeObserver()
          }
        }
      }
    }
    .onChange(of: videoMove, perform: { newValue in
      switch newValue {
      case .backward, .forward:
        if let player = avPlayer {
          player.seek(
            to: CMTime(seconds: currentTime, preferredTimescale: 1))
        }
      default: break
      }
      DispatchQueue.main.async {
        videoMove = .none
      }
    })
    .onChange(of: userGesture) { [oldValue = userGesture] newValue in
      if newValue == .videoSeeking {
        if let player = self.avPlayer {
          player.pause()
          if let item = player.currentItem {
            guard !(item.duration.seconds.isNaN || item.duration.seconds.isInfinite)
            else {
              return
            }
          }
        }
      } else if oldValue == .videoSeeking {
        if let player = avPlayer {
          if playStatus == .play {
            DispatchQueue.main.async {
              player.play()
            }
          }
        }
      }
    }
    .onChange(of: currentTime) { newValue in
      if userGesture == .videoSeeking {
        if let player = self.avPlayer {
          player
            .seek(to: CMTime(seconds: newValue,
                             preferredTimescale: 1))
        }
      }
    }
  }
}

// MARK: - 2. subViews
extension VideoDetailView {
  var soundSlider: some View {
    ZStack {
      Rectangle()
        .foregroundStyle(.thinMaterial)
        .frame(height: 150)
      Rectangle()
        .foregroundStyle(.white)
        .frame(height: 150 * MPVolumeView.catchVolume())
    }
    .mask(RoundedRectangle(cornerRadius: 10))
    .frame(width: 20)
    .padding(.top, navigationbarHeight + statusBarHeight + 10)
    .padding(.trailing, 10)
  }
  func soundGesture() -> some Gesture {
    LongPressGesture(minimumDuration: 1)
      .onChanged { value in
        print(value.description)
      }
  }
  
  func adjustSound() -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged({ value in
        if abs(value.translation.height) > 3 {
          userGesture = .soundAdjusting
          print("ok")
          MPVolumeView.setVolume(0.7)
        } else {
          print("no", AVAudioSession.sharedInstance().outputVolume)
        }
      })
      .onEnded { _ in
        userGesture = .none
      }
  }
  func videoOffset(size: CGSize, asset: PHAsset) -> CGFloat {
    let assetHeight = size.width * CGFloat(asset.pixelHeight)
    / CGFloat(asset.pixelWidth)
    let bottomSpace = (size.height - assetHeight) / 2
    return bottomSpace - statusBarHeight + 10
  }
}

// MARK: - 3. Vedeo functions
extension VideoDetailView {
  // 3-1. get 비디오
  func fetchingVideo(asset: PHAsset) {
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    imageManager.requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
      if let avAsset = asset as? AVURLAsset {
        DispatchQueue.main.async {
          withAnimation {
            avPlayer = AVPlayer(url: avAsset.url)
          }
        }
      }
    }
  }
  
  // Reset 비디오 재생
  func resetVideo(isFullEnded: Bool = true) {
    if let player = avPlayer {
      DispatchQueue.main.async {
        player.pause()
        player.seek(to: .zero)
      }
    }
  }
  
  // 사운드 조정
  func pauseBackgroundAudio() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.soloAmbient, mode: .default)
      try audioSession.setActive(true)
    } catch {
      print(error)
    }
  }
  
  func resumeBackgroundAudio() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
      print("audiosession return to System")
    } catch {
      print(error)
    }
    resetAudiosession()
  }
  
  func resetAudiosession() {
    let audioSession = AVAudioSession.sharedInstance()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      do {
        try audioSession.setCategory(.ambient, mode: .default)
        try audioSession.setActive(true)
      } catch {
        print(error)
      }
    }
  }
  
  
}

// MARK: - 4. avplayer Observer functions
extension VideoDetailView {
  func addObserverToPlayer() {
    let time = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    let runningTime = asset.duration
    print("옵저버 ADDed")
    guard let _ = self.avPlayer.currentItem else { return }
    self.timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
      if videoMove == .none {
        let remain = runningTime - time.seconds
        withAnimation {
          if remain >= 0.1 {
            currentTime = time.seconds
          } else {
            currentTime = runningTime
          }
        }
      }
    }
  }
  
  func removeObserver() {
    if let observer = self.timeObserver,
       let player = avPlayer {
      player.removeTimeObserver(observer)
      timeObserver = nil
      print("옵저버 removed")
    }
  }
}

// MARK: - 5. Gestrues
extension VideoDetailView {
  // 비디오 커스텀 컨트롤러 hidden 토글 Gesture
  //    private var hideGesture: some Gesture {
  //        TapGesture(count: 1)
  //            .onEnded { _ in
  //                if userGesture == .none {
  //                    DispatchQueue.main.async {
  //                        withAnimation(.easeOut(duration: 0.1)) {
  //                            self.hideTools.toggle()
  //                        }
  //                    }
  //                }
  //            }
  //    }
  
  
  // sound adjust Gestrue
  func soundGesture(current: Binding<Double>, geoProxy: GeometryProxy) -> some Gesture {
    var movedHeight: CGFloat = 0
    return DragGesture(minimumDistance: 1)
      .onChanged { newValue in
        userGesture = .videoSeeking
        avPlayer?.pause()
        //                self.offsetX = 0
        //                self.offsetY = 0
        if let item = avPlayer.currentItem {
          guard !(item.duration.seconds.isNaN || item.duration.seconds.isInfinite)
          else {
            return
          }
          movedHeight = CGFloat(newValue.translation.width / (geoProxy.size.width * 0.7))
          let movePercent = tempSliderPosition + Float(movedHeight)
          
          avPlayer?
            .seek(to: CMTime(seconds: currentTime,
                             preferredTimescale: 1))
        }
      }
      .onEnded { newValue in
        tempSliderPosition = 0
        DispatchQueue.main.async {
          if playStatus == .play {
            avPlayer?.play()
          }
        }
        userGesture = .none
      }
  }
  
}

//struct VideoDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoDetailView(offsetIndex: 0,
//                        asset: MLAsset(phAsset: PHAsset()),
//                        imageManager: PHCachingImageManager(),
//                        geometry: GeometryProxy(),
//                        play: .constant(.play),
//                        hideTools: .constant(false),
//                        userGesture: .constant(.none),
//                        offsetY: .constant(0),
//                        offsetX: .constant(0),
//                        tempView: {
//            EmptyView()
//        },
//                        zoomGesture: TapGesture())
//        .preferredColorScheme(.dark)
//    }
//}

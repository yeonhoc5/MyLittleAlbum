//
//  VideoDetailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/31.
//

import SwiftUI
import Photos
import AVKit

struct VideoDetailView: View {
    @Environment(\.scenePhase) var scenePhase
    @Binding var isExpanded: Bool
    var offsetIndex: Int
    var asset: PHAsset
    let navigationTitle: String
    @State var avPlayer: AVPlayer!
    @Binding var offsetY: CGFloat
    @State var play: Bool = false
    @State var mute: Bool = false
    @Binding var hidden: Bool
    @Binding var isSeeking: Bool
    @State var value: Float = 0
    @Binding var offsetX: CGFloat
    
    @State var slider: UISlider = UISlider()
    @State var current: Double = 0
    
    let imageManager = PHCachingImageManager()
    
    var body: some View {
        if avPlayer == nil {
            ProgressView()
                .onAppear {
                    let options = PHVideoRequestOptions()
                    options.isNetworkAccessAllowed = true
                    imageManager.requestAVAsset(forVideo: asset, options: options) { asset, audioMix, _ in
                        let avAsset = asset as! AVURLAsset
                        DispatchQueue.main.async {
                            avPlayer = AVPlayer(url: avAsset.url)
                        }
                    }
                }
        } else {
            AVPlayerController(player: avPlayer, title: navigationTitle)
                .simultaneousGesture(hideGesture)
                .overlay(alignment: .bottom) {
                    customPlayBack
                        .padding(.bottom, 80)
                        .opacity(self.hidden ? 0 : 1)
                        .simultaneousGesture(seekGesture(current: current))
                }
                .onAppear {
                    avPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { _ in
                        self.value = getSliderValue()
                    }
                    if offsetIndex == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            DispatchQueue.main.async {
                                stopBackgroundSound()
                                avPlayer?.play()
                                self.play = true
                            }
                        }
                    }
                }
                .onChange(of: offsetIndex) { newValue in
                    if newValue == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            DispatchQueue.main.async {
                                stopBackgroundSound()
                            }
                            avPlayer?.play()
                            self.play = true
                        }
                    } else {
                        self.play = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            avPlayer?.pause()
                            avPlayer?.seek(to: .zero)
                        }
                    }
                }
                .onChange(of: play, perform: { newValue in
                    if play && avPlayer.status == .readyToPlay {
                        avPlayer?.play()
                    } else {
                        avPlayer?.pause()
                    }
                })
                .onChange(of: mute, perform: { newValue in
                    avPlayer?.isMuted = mute
                })
                .onDisappear {
                    DispatchQueue.main.async {
                        self.play = false
                        avPlayer?.pause()
                        avPlayer?.seek(to: .zero)
                        avPlayer = nil
                    }
                }
                .onChange(of: scenePhase) { newValue in
                    if offsetIndex == 0 {
                        if newValue != .active {
                            withAnimation {
                                offsetY = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                DispatchQueue.main.async {
                                    resumeBackgroundSound()
                                    self.avPlayer?.pause()
                                }
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                DispatchQueue.main.async {
                                    stopBackgroundSound()
                                    self.avPlayer?.play()
                                }
                            }
                        }
                    }
                }
                .onChange(of: value) { newValue in
                    if newValue == 1.0 {
                        self.play = false
                        self.avPlayer.seek(to: .zero)
                    }
                }
                .onChange(of: getSeconds()) { newValue in
                    if !isSeeking {
                        self.current = newValue
                    }
                }
        }
    }
    
    private var hideGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    self.hidden.toggle()
                }
            }
    }
    
    
    var customPlayBack: some View {
        let iconSize: CGFloat = 30
        return ZStack {
            BlurView(style: .prominent)
                .frame(width: screenSize.width - 50, height: 130)
                .cornerRadius(20)
            VStack(spacing: 25) {
                VStack(spacing: 5) {
                    HStack {
                        Text("\(durationString(time: getSeconds()))")
                            .padding(.leading, 5)
                        Spacer()
                        Text("\(durationString(time: Double(asset.duration)))")
                            .padding(.trailing, 5)
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    CustomSeekBar(value: self.$value, avPlayer: $avPlayer, play: $play, isSeeking: $isSeeking, slider: $slider)
                        .frame(width: screenSize.width - 100)
                }
                .frame(width: screenSize.width - 100)
                HStack {
                    btnBackward(iconSize: iconSize)
                    btnPlayToggle(play: play, iconSize: iconSize)
                        .padding(.horizontal, 20)
                    btnForward(iconSize: iconSize)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                btnMuteToggle(mute: mute, iconSize: iconSize)
            }
        }
        .foregroundColor(.white)
        
    }
 
}
// MARK: - 2. subViews
extension VideoDetailView {
    
}

// MARK: - 3. functions
extension VideoDetailView {
    // get 비디오
    func fetchingVideo(asset: PHAsset) -> AVURLAsset! {
        var avAsset: AVURLAsset!
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        imageManager.requestAVAsset(forVideo: asset, options: options) { handlerAsset, audioMix, _ in
            if let resultAsset = handlerAsset as? AVURLAsset {
                DispatchQueue.main.async {
                    avAsset = resultAsset
                }
            }
        }
        return avAsset
    }
    
    // 비디오 재생시간
    //        case 1. 11:05:05
    //        case 2.  1:05:10
    //        case 3. 11:04
    //        case 4.  5:14
    //        case 5.  0:05
    func durationString(time: Double) -> String {
        guard !(time.isNaN || time.isInfinite) else { return "illegal value" }
        let duration: Int = Int(time / 1.0)
        let hour: String = duration >= 3600 ? "\(duration / 3600):" : ""
        let minute: String = "\(((duration) % 3600) / 60):"
        let second: String = (duration) % 60 >= 10 ? "\((duration) % 60)" : "0\((duration) % 60)"
        return hour + minute + second
    }
    
    // 비디오 1/4. 재생 토글
    func btnPlayToggle(play: Bool, iconSize: CGFloat) -> some View {
        let playIcon = play ? "pause.fill" : "play.fill"
        return Button {
            withAnimation(.interactiveSpring()) {
                self.play.toggle()
            }
        } label: {
            imageScaledFit(systemName: playIcon, width: iconSize, height: iconSize)
        }
    }
    // 비디오 2/4. 뒤로 5초
    func btnBackward(iconSize: CGFloat) -> some View {
        Button {
            if getSeconds() - 5 < 0 {
                avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
            } else {
                avPlayer.seek(to: CMTime(seconds: getSeconds() - 5, preferredTimescale: 1))
            }
        } label: {
            imageScaledFit(systemName: "gobackward.5", width: iconSize, height: iconSize)
        }
    }
    // 비디오 3/4. 앞으로 5초
    func btnForward(iconSize: CGFloat) -> some View {
        Button {
            if let total = avPlayer.currentItem?.duration.seconds.rounded() {
                if total - getSeconds() < 0 {
                    avPlayer.seek(to: CMTime(seconds: total, preferredTimescale: 1))
                } else {
                    avPlayer.seek(to: CMTime(seconds: getSeconds() + 5, preferredTimescale: 1))
                }
            }
        } label: {
            imageScaledFit(systemName: "goforward.5", width: iconSize, height: iconSize)
        }
    }
    // 비디오 4/4. 뮤트 토글
    func btnMuteToggle(mute: Bool, iconSize: CGFloat) -> some View {
        let muteIcon = mute ? "speaker.slash.fill" : "speaker.wave.2.fill"
        return Button {
            withAnimation(.interactiveSpring()) {
                self.mute.toggle()
            }
        } label: {
            imageScaledFit(systemName: muteIcon, width: iconSize, height: iconSize)
        }
    }
    // 비디오 재생시 시스템 사운드 종료
    func stopBackgroundSound() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.soloAmbient, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print(error)
        }
    }
    // 디테일 뷰 종료시 시스템 사운드 리턴
    func resumeBackgroundSound() {
        let audioSession = AVAudioSession.sharedInstance()
        DispatchQueue.main.async {
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print(error)
            }
        }
    }
    // get 슬라이더 위치
    func getSliderValue() -> Float {
        guard let _ = avPlayer?.currentItem else { return 0 }
        return Float((self.avPlayer?.currentTime().seconds)! / (self.avPlayer?.currentItem?.duration.seconds)!)
    }
    // get 현재 비디오 타임
    func getSeconds() -> Double {
//        guard let item = avPlayer?.currentItem else { return 0 }
        return Double(Double(value) * (asset.duration)).rounded()
    }
    
}

// MARK: - 4. Gestrues
extension VideoDetailView {
    // video seek Gestrue
    func seekGesture(current: Double) -> some Gesture {
        var playPosition: Double = 0
        return DragGesture(minimumDistance: 1)
            .onChanged { newValue in
                isSeeking = true
                self.offsetX = 0
                self.offsetY = 0
                avPlayer?.pause()
                if let item = avPlayer.currentItem {
                    let sec = Int((newValue.translation.width / 180) * item.duration.seconds)
                    avPlayer?.seek(to: CMTime(seconds: Double(Int(current) + sec), preferredTimescale: 1))
                    playPosition = Double(Int(current) + sec)
                }
            }
            .onEnded { newValue in
                isSeeking = false
                avPlayer?.seek(to: CMTime(seconds: playPosition, preferredTimescale: 1))
                self.current = getSeconds()
                if play {
                    avPlayer?.play()
                }
            }
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}

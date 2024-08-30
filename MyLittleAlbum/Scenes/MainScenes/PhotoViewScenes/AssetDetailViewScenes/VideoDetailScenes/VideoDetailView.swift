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
    
    // video properties
    @State var avPlayer: AVPlayer!
    @State var play: Bool = false
    @State var mute: Bool = false
    @Binding var hidden: Bool
    @Binding var isSeeking: Bool
    @State var value: Float = 0
    @State var timeObserver: Any!
    @State var slider: UISlider = UISlider()
    @State var currentTime: Double = 0
    
    let imageManager = PHCachingImageManager()
    // offset proverties
    @Binding var offsetY: CGFloat
    @Binding var offsetX: CGFloat
    
    var body: some View {
        if avPlayer == nil {
            ProgressView()
                .tint(.color1)
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .onAppear {
                    DispatchQueue.main.async {
                        fetchingVideo(asset: asset)
                    }
                }
        } else {
            if let avPlayer = self.avPlayer {
                AVPlayerController(player: avPlayer)
                    .simultaneousGesture(hideGesture)
                    .overlay(alignment: .bottom) {
                        GeometryReader { geoproxy in
                            customPlayBack(geo: geoproxy)
                                .simultaneousGesture(seekGesture(current: currentTime))
                        }
                        .frame(width: device == .phone 
                               ? screenWidth - 50 : screenWidth * 0.5,
                               height: 130)
                        .opacity(self.hidden ? 0 : 1)
                        .padding(.bottom, 50)
                    }
                    .onChange(of: play, perform: { bool in
                        if bool {
                            if self.timeObserver == nil {
                                addObserverToPlayer()
                            }
                            // play & pasue by button
                            if avPlayer.status == .readyToPlay {
                                avPlayer.play()
                            }
                        } else {
                            avPlayer.pause()
                        }
                    })
                    .onChange(of: offsetIndex) { newValue in
                        if newValue != 0 {
                            removeObserver()
                            resetVideo()
                        }
                    }
                    .onDisappear {
                        if offsetIndex == 0 {
                            removeObserver()
                            resetVideo()
                            DispatchQueue.main.async {
                                self.avPlayer = nil
                            }
                        }
                    }
                    .onChange(of: value) { newValue in
                        if newValue == 1.0 {
                            DispatchQueue.main.async {
                                removeObserver()
                                resetVideo()
                            }
                        }
                    }
                    .onChange(of: scenePhase) { newValue in
                        if offsetIndex == 0 && newValue == .background {
                            withAnimation { offsetY = 0 }
                            DispatchQueue.main.async {
                                avPlayer.pause()
                            }
                        }
                    }
                    .onChange(of: mute, perform: { newValue in
                        avPlayer.isMuted = newValue
                    })
//                    .onChange(of: getSeconds()) { newValue in
//                        if !isSeeking {
//                            DispatchQueue.main.async {
//                                self.currentTime = newValue
//                            }
//                        }
//                    }
            }
        }
    }
}
// MARK: - 2. subViews
extension VideoDetailView {
    // 커스텀 비디오 컨트롤러
    func customPlayBack(geo: GeometryProxy) -> some View {
        let iconSize: CGFloat = 30
        let innerPadding = 25.0
        return ZStack {
            BlurView(style: .prominent)
                .cornerRadius(20)
            VStack(spacing: 25) {
                VStack(spacing: 5) {
                    HStack {
                        Text("\(durationString(time: getSeconds()))")
                            .padding(.leading, 5)
                        Spacer()
                        Text("\(durationString(time: Double(asset.duration.rounded(.toNearestOrAwayFromZero))))")
                            .padding(.trailing, 5)
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    CustomSeekBar(value: self.$value, 
                                  avPlayer: $avPlayer, 
                                  play: $play,
                                  isSeeking: $isSeeking,
                                  slider: $slider,
                                  currentTime: $currentTime)
                }
                HStack {
                    if play {
                        btnStopPlay(iconSize: iconSize)
                            .animation(.interactiveSpring(), value: play)
                    } else {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(width: iconSize, height: iconSize)
                    }
                    Spacer()
                    btnBackward(iconSize: iconSize)
                    Spacer()
                    btnPlayToggle(play: play, iconSize: iconSize)
                    Spacer()
                    btnForward(iconSize: iconSize)
                    Spacer()
                    btnMuteToggle(mute: mute, iconSize: iconSize)
                }
                .scaleEffect(0.8)
            }
            .padding(innerPadding)
        }
        .foregroundColor(.white)
        
    }
    // 버튼 1/4. 재생 토글
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
    // 버튼 2/4. 뒤로 5초
    func btnBackward(iconSize: CGFloat) -> some View {
        Button {
            if currentTime - 5 <= 0 {
                avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                currentTime = 0
            } else {
                avPlayer.seek(to: CMTime(seconds: currentTime - 5, preferredTimescale: 1))
                currentTime = currentTime - 5
            }
            DispatchQueue.main.async {
                getValue(runningTime: asset.duration, current: currentTime)
            }
        } label: {
            imageScaledFit(systemName: "gobackward.5", width: iconSize, height: iconSize)
        }
    }
    // 버튼 3/4. 앞으로 5초
    func btnForward(iconSize: CGFloat) -> some View {
        Button {
            if let total = avPlayer.currentItem?.duration.seconds.rounded(.toNearestOrAwayFromZero) {
                if total - currentTime <= 5 {
                    avPlayer.seek(to: CMTime(seconds: total, preferredTimescale: 10))
                    currentTime = total
                } else {
                    avPlayer.seek(to: CMTime(seconds: currentTime + 5, preferredTimescale: 10))
                    currentTime = currentTime + 5
                }
                DispatchQueue.main.async {
                    getValue(runningTime: asset.duration, current: currentTime)
                }
            }
        } label: {
            imageScaledFit(systemName: "goforward.5", width: iconSize, height: iconSize)
        }
    }
    // 버튼 4/4. 뮤트 토글
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
    
    func btnStopPlay(iconSize: CGFloat) -> some View {
        Button {
            DispatchQueue.main.async {
                resetVideo()
                removeObserver()
            }
        } label: {
            imageScaledFit(systemName: "stop.fill", width: iconSize, height: iconSize)
        }
    }
    
}

// MARK: - 3. Vedeo functions
extension VideoDetailView {
    // 3-1. get 비디오
    func fetchingVideo(asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
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
    // 3-2. 재생시간
                    // 비디오 재생시간 All Cases
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
    // get 슬라이더 위치
    func getValue(runningTime: TimeInterval, current: TimeInterval) {
        DispatchQueue.main.async {
            value = Float(current / runningTime)
        }
    }
    // get 현재 비디오 타임
    func getSeconds() -> Double {
        return Double(Double(value) * (asset.duration)).rounded(.toNearestOrAwayFromZero)
    }
    
    // Reset 비디오 재생
    func resetVideo() {
        self.play = false
        DispatchQueue.main.async {
            avPlayer?.pause()
            avPlayer?.seek(to: .zero)
            value = 0
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
            DispatchQueue.main.async {
                self.value = Float(time.seconds / runningTime)
            }
        }
    }
    
    func removeObserver() {
        if let observer = self.timeObserver {
            avPlayer.removeTimeObserver(observer)
            timeObserver = nil
            print("옵저버 removed")
        }
    }
}

// MARK: - 5. Gestrues
extension VideoDetailView {
    // 비디오 커스텀 컨트롤러 hidden 토글 Gesture
    private var hideGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.1)) {
                        self.hidden.toggle()
                    }
                }
            }
    }
    
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
                    guard !(item.duration.seconds.isNaN || item.duration.seconds.isInfinite) else { return }
                    let sec = Int((newValue.translation.width / 180) * item.duration.seconds)
                    avPlayer?.seek(to: CMTime(seconds: Double(Int(current) + sec), preferredTimescale: 1))
                    playPosition = Double(Int(current) + sec)
                    if (0...asset.duration).contains(playPosition) {
                        DispatchQueue.main.async {
                            getValue(runningTime: asset.duration, current: playPosition)
                        }
                    }
                }
            }
            .onEnded { newValue in
                isSeeking = false
                avPlayer?.seek(to: CMTime(seconds: playPosition, preferredTimescale: 1))
                DispatchQueue.main.async {
                    self.currentTime = playPosition
                }
                if play {
                    avPlayer?.play()
                }
            }
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(isExpanded: .constant(true),
                        offsetIndex: 0,
                        asset: PHAsset(),
//                        navigationTitle: "sample",
                        hidden: .constant(false),
                        isSeeking: .constant(false),
                        offsetY: .constant(0),
                        offsetX: .constant(0))
        .preferredColorScheme(.dark)
    }
}

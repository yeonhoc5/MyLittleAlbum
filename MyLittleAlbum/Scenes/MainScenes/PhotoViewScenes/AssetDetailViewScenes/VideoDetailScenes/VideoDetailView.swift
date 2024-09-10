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
    var offsetIndex: Int
    var asset: PHAsset
    
    // video properties
    @State var avPlayer: AVPlayer!
    @State var play: Bool = false
    @State var mute: Bool = false
    @Binding var hidden: Bool
    @State var timeObserver: Any!
    @Binding var isSeeking: Bool
    @State var slider: UISlider = UISlider()
    // uislider의 vlaue가 float임
    @State var sliderValue: Float = 0
    @State var currentTime: Double = 0
    @State var tempSliderPosition: Float = 0
    
    let imageManager = PHCachingImageManager()
    // offset proverties
    @Binding var offsetY: CGFloat
    @Binding var offsetX: CGFloat
    
    var body: some View {
        if avPlayer == nil {
            loadingView
        } else {
            if let avPlayer = self.avPlayer {
                GeometryReader { geoproxy in
                    AVPlayerController(player: avPlayer)
                        .simultaneousGesture(hideGesture)
                        .overlay(alignment: .bottom) {
                            customPlayBack(geo: geoproxy)
                                .simultaneousGesture(
                                    seekGesture(current: $currentTime,
                                                geoProxy: geoproxy)
                                )
                                .opacity(self.hidden ? 0 : 1)
                                .padding(.bottom, 50)
                        }
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
                                if self.avPlayer != nil {
                                    print("video scene out")
                                    DispatchQueue.main.async {
                                        self.avPlayer = nil
                                    }
                                }
                            }
                        }
                        .onChange(of: sliderValue) { newValue in
                            if newValue == 1.0 && !isSeeking {
                                DispatchQueue.main.async {
                                    removeObserver()
                                    resetVideo()
                                }
                            }
                            if play {
                                self.currentTime = getSeconds()
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
                }
            }
        }
    }
}
// MARK: - 2. subViews
extension VideoDetailView {
    var loadingView: some View {
        ProgressView()
            .tint(.color1)
            .progressViewStyle(.circular)
            .scaleEffect(1.5)
            .onAppear {
                DispatchQueue.main.async {
                    fetchingVideo(asset: asset)
                }
            }
    }
    // 커스텀 비디오 컨트롤러
    func customPlayBack(geo: GeometryProxy) -> some View {
        let iconSize: CGFloat = 30
        let innerPadding = 10.0
        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
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
                    CustomSeekBar(value: sliderValue, slider: slider)
                }
                HStack(spacing: 0) {
                    btnStopPlay(iconSize: iconSize, 
                                padding: innerPadding)
                        .opacity(play ? 1 : 0.2)
                        .disabled(!play)
                    Spacer(minLength: 1.0)
                    btnBackward(iconSize: iconSize, 
                                padding: innerPadding)
                    Spacer(minLength: 1.0)
                    btnPlayToggle(play: $play,
                                  iconSize: iconSize,
                                  padding: innerPadding)
                    Spacer(minLength: 1.0)
                    btnForward(iconSize: iconSize, 
                               padding: innerPadding)
                    Spacer(minLength: 1.0)
                    btnMuteToggle(mute: mute, 
                                  iconSize: iconSize,
                                  padding: innerPadding)
                }
            }
            .padding(25)
        }
        .foregroundColor(.white)
        .frame(width: device == .phone ? geo.size.width * 0.9
                                    : min(geo.size.width, geo.size.height) * 0.7,
               height: 150)
    }
    // 버튼 1/4. 재생 토글
    func btnPlayToggle(play: Binding<Bool>, iconSize: CGFloat, padding: CGFloat) -> some View {
        let playIcon = play.wrappedValue ? "pause.fill" : "play.fill"
        return Button {
            if !isSeeking {
                if !play.wrappedValue {
                    withAnimation(.interactiveSpring()) {
                        self.play = true
                    }
                    if self.timeObserver == nil {
                        addObserverToPlayer()
                    }
                    // play & pasue by button
                    if avPlayer.status == .readyToPlay {
                        avPlayer.play()
                    }
                } else {
                    withAnimation(.interactiveSpring()) {
                        self.play = false
                    }
                    avPlayer.pause()
                }
            }
        } label: {
            imageScaledFit(systemName: playIcon, width: iconSize, height: iconSize)
                .padding(padding)
        }
    }
    // 버튼 2/4. 뒤로 5초
    func btnBackward(iconSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            if !isSeeking {
                if let bool = avPlayer.currentItem?.canStepBackward,
                    bool == true {
                    avPlayer.seek(to: CMTime(seconds: currentTime - 5, preferredTimescale: 1))
                    currentTime = currentTime - 5
                } else {
                    avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                    currentTime = 0
                }
                DispatchQueue.main.async {
                    getValue(runningTime: asset.duration, current: currentTime)
                }
            }
        } label: {
            imageScaledFit(systemName: "gobackward.5", width: iconSize, height: iconSize)
                .padding(padding)
        }
    }
    // 버튼 3/4. 앞으로 5초
    func btnForward(iconSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            if !isSeeking {
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
            }
        } label: {
            imageScaledFit(systemName: "goforward.5", width: iconSize, height: iconSize)
                .padding(padding)
        }
    }
    // 버튼 4/4. 뮤트 토글
    func btnMuteToggle(mute: Bool, iconSize: CGFloat, padding: CGFloat) -> some View {
        let muteIcon = mute ? "speaker.slash.fill" : "speaker.wave.2.fill"
        return Button {
            if !isSeeking {
                withAnimation(.interactiveSpring()) {
                    self.mute.toggle()
                }
            }
        } label: {
            imageScaledFit(systemName: muteIcon, width: iconSize, height: iconSize)
                .padding(padding)
        }
    }
    
    func btnStopPlay(iconSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            DispatchQueue.main.async {
                resetVideo()
                removeObserver()
            }
        } label: {
            imageScaledFit(systemName: "stop.fill", width: iconSize, height: iconSize)
                .padding(padding)
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
            sliderValue = Float(current / runningTime)
        }
    }
    // get 현재 비디오 타임
    func getSeconds() -> Double {
        let time = Double(sliderValue) * (asset.duration)
        return Double(time < 0 ? 0 : time)
            .rounded(.toNearestOrAwayFromZero)
    }
    
    // Reset 비디오 재생
    func resetVideo() {
        self.play = false
        DispatchQueue.main.async {
            avPlayer?.pause()
            avPlayer?.seek(to: .zero)
            sliderValue = 0
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
            let remain = runningTime - time.seconds
            print(remain)
            if remain > 0.05 {
                currentTime = time.seconds
                DispatchQueue.main.async {
                    withAnimation {
                        self.sliderValue = Float(time.seconds / runningTime)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.sliderValue = 1.0
                    }
                }
            }
//            print(time.seconds, runningTime)
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
    func seekGesture(current: Binding<Double>, geoProxy: GeometryProxy) -> some Gesture {
        var movedWidth: CGFloat = 0
        
        return DragGesture(minimumDistance: 1)
            .onChanged { newValue in
                if !isSeeking {
                    isSeeking = true
                    tempSliderPosition = sliderValue
                    avPlayer?.pause()
                    print("on changed", "isSeeking \(isSeeking)")
                }
                self.offsetX = 0
                self.offsetY = 0
                if let item = avPlayer.currentItem {
                    guard !(item.duration.seconds.isNaN || item.duration.seconds.isInfinite) 
                    else {
                        return
                    }
                    movedWidth = CGFloat(newValue.translation.width / (geoProxy.size.width * 0.7))
                    let movePercent = tempSliderPosition + Float(movedWidth)
                    sliderValue = movePercent < 0 ? 0 : (movePercent > 1 ? 1 : movePercent)
                    currentTime = item.duration.seconds * Double(sliderValue)
                    avPlayer?
                        .seek(to: CMTime(seconds: currentTime,
                                         preferredTimescale: 1))
                }
            }
            .onEnded { newValue in
                print(currentTime)
                tempSliderPosition = 0
                DispatchQueue.main.async {
                    if play {
                        avPlayer?.play()
                    }
                }
                isSeeking = false
                print("on Ended", "isSeeking \(isSeeking)")
            }
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(offsetIndex: 0,
                        asset: PHAsset(),
//                        navigationTitle: "sample",
                        hidden: .constant(false),
                        isSeeking: .constant(false),
                        offsetY: .constant(0),
                        offsetX: .constant(0))
        .preferredColorScheme(.dark)
    }
}

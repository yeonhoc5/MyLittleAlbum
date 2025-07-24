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
    case play, pause, stop
}

struct VideoDetailView: View {
    var isDigitalShow: Bool = false
    @Environment(\.scenePhase) var scenePhase
    var offsetIndex: Int
    var asset: MLAsset
    let imageManager: PHCachingImageManager
    let size: CGSize
    @Namespace var nameSpace
    
    // video properties
    @State var avPlayer: AVPlayer!
    @Binding var play: VideoState
    @State var play2x: Bool = false
    @State var mute: Bool = false
    @Binding var hideTools: Bool
    @State var timeObserver: Any!
    
    @Binding var userGesture: DetailViewGesture
    // uislider의 vlaue가 float임
    @State var sliderValue: Float = 0
    @State var currentTime: Double = 0
    @State var tempSliderPosition: Float = 0
    
    // offset proverties
    @Binding var offsetY: CGFloat
    @Binding var offsetX: CGFloat
    @State var needOpacity: Bool = false
    @State var needOffset: Bool = false
    
    var body: some View {
        if avPlayer == nil {
            loadingView
        } else {
            if let avPlayer = self.avPlayer {
                AVPlayerController(player: avPlayer)
                    .onLongPressGesture(minimumDuration: 0.5,
                                        perform: {
                        speedPlay(isStart: true)
                    }, onPressingChanged: { _ in
                        speedPlay(isStart: false)
                    })
                    .padding(.bottom,
                             accordingToVideoHeight(height: size.height))
                    .simultaneousGesture(hideGesture)
                    .overlay(alignment: .topTrailing, content: {
                        if userGesture == .soundAdjusting {
                            soundSlider
                        }
                    })
                    .overlay(alignment: .topLeading, content: {
                        if play2x {
                            speedNoticeView
                        }
                    })
                    .overlay(alignment: .bottom) {
                        if !isDigitalShow {
                            let width = size.width / (device == .phone ? 1 : 1.5)
                            let devicePadding = device == .pad ? 0 : (vcHeight + 10)
                            let yOffset = -vcBottomPadding
                                - (devicePadding)
                                + (needOffset
                                   ? (hideTools ? (devicePadding) : 0) : 0)
                            HStack {
                                if device == .pad {
                                    Spacer()
                                }
                                customPlayBack(height: vcHeight)
                                    .padding(.horizontal, vcHorisontalPadding)
                                    .frame(width: width)
                                    .offset(y: yOffset)
                                    .opacity(needOpacity
                                             ? (hideTools ? 0 : 1) : 1)
                            }
                        }
                    }
                    .onAppear(perform: {
                        if isDigitalShow {
                            DispatchQueue.main.async {
                                avPlayer.play()
                            }
                        } else {
                            checkNeedOffset(size: size)
                        }
                    })
                    .onDisappear {
                        if isDigitalShow {
                            DispatchQueue.main.async {
                                avPlayer.pause()
                            }
                        } else {
                            if offsetIndex == 0 {
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
                    }
                    .onChange(of: play2x, perform: { newValue in
                        avPlayer.rate = newValue ? 2 : 1
                    })
                    .onChange(of: mute, perform: { newValue in
                        avPlayer.isMuted = newValue
                    })
                    .onChange(of: sliderValue) { newValue in
                        if newValue == 1.0 && userGesture == .none {
                            print("ended")
                            DispatchQueue.main.async {
                                resetVideo(isFullEnded: true)
                                removeObserver()
                            }
                        }
                    }
                    .onChange(of: scenePhase) { newValue in
                        if offsetIndex == 0 && newValue == .background {
                            withAnimation { offsetY = 0 }
                            DispatchQueue.main.async {
                                self.play = .stop
                                avPlayer.pause()
                            }
                        }
                    }
                    .onChange(of: offsetIndex) { newValue in
                        // 페이지 넘어가면 스탑 & 리셋
                        if newValue != 0 {
                            removeObserver()
                            resetVideo(isFullEnded: true)
                        } else {
                            if play == .play {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation {
                                        self.play = .play
                                    }
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
            }
        }
    }
}

// MARK: - 2. subViews
extension VideoDetailView {
    func checkNeedOffset(size: CGSize) {
        self.needOpacity = size.height
                        - assetHeight(asset: asset.phAsset)
                        - statusBarHeight
                        < tabbarHeight
        if !needOpacity {
            needOffset = (size.height
                          - assetHeight(asset: asset.phAsset)) / 2
            < (vcHeight * 2) + vcBottomPadding + 15
        }
    }
    var speedNoticeView: some View {
        HStack {
            Text("2x")
            Image(systemName: "forward.fill")
                .modify { content in
                    if #available(iOS 18.0, *) {
                        content
                            .symbolEffect(.bounce)
                    }
                }
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background {
            Capsule()
                .foregroundStyle(.thinMaterial)
        }
        .offset(x: 10,
                y: (hideTools ? 0 : navigationbarHeight)
                    + statusBarHeight + 10)
    }
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
    func accordingToVideoHeight(height: CGFloat) -> CGFloat {
        return needOffset
            ? (!hideTools ? 0
               : height - assetHeight(asset: asset.phAsset) - (statusBarHeight * 2))
            : 0
    }
    
    var loadingView: some View {
        ProgressView()
            .tint(.white)
            .controlSize(.large)
            .progressViewStyle(.circular)
            .scaleEffect(0.8)
            .onAppear {
                DispatchQueue.main.async {
                    fetchingVideo(asset: asset.phAsset)
                }
            }
    }
    // 커스텀 비디오 컨트롤러
    func customPlayBack(height: CGFloat) -> some View {
        let iconSize: CGFloat = 20
        let innerPadding = 10.0
        return HStack(alignment: .bottom, spacing: 10) {
            GeometryReader { geometry in
                ZStack {
                    // 0. 백그라운드 슬라이더
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.thinMaterial)
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: geometry.size.width * CGFloat(sliderValue))
                    }
                    .mask(
                        RoundedRectangle(cornerRadius: 10)
                    )
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Group {
                        // 2. 중지 버튼
                            btnStopPlay(iconSize: iconSize,
                                        padding: innerPadding,
                                        disabled: (sliderValue == 0
                                                   || sliderValue == 1))
                                .opacity((sliderValue == 0
                                          || sliderValue == 1) ? 0.2 : 1)
                            Spacer(minLength: 0)
                        // 3. 뒤로 5초 버튼
                            btnBackward(iconSize: iconSize, padding: innerPadding)
                            Spacer(minLength: 1.0)
                            btnPlayToggle(play: $play,
                                          iconSize: iconSize,
                                          padding: innerPadding)
                                .modify { content in
                                    if #available(iOS 17.0, *) {
                                        content
                                            .contentTransition(.symbolEffect)
                                    }
                                }
                            Spacer(minLength: 0)
                        // 4. 앞으로 5초 버튼
                            btnForward(iconSize: iconSize,
                                       padding: innerPadding)
                        }
                        .opacity(userGesture == .videoSeeking ? 0 : 1)
                        .transition(.opacity)
                        .animation(.linear, value: userGesture == .videoSeeking)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 5)
                    .disabled(userGesture == .videoSeeking)

                }
                .simultaneousGesture(
                    seekGesture(current: $currentTime,
                                geoProxy: geometry)
                )
            }
            .frame(height: height)
            .overlay(alignment: .topLeading) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    let entireTime = Double(asset.duration.rounded(.up))
                    // 1-1. 재생 시간
                    processingText(
                        time: durationString(entire: entireTime,time: getSeconds()))
                    // 1-2. 영상 전체 시간
                    processingText(needSlash: true,
                        time: durationString(entire: entireTime, time: entireTime))
                }
                .offset(x: 5, y: -17)
            }
//            ZStack(alignment: .bottom) {
//                if userGesture != .soundAdjusting {
            //                        btnMuteToggle(mute: mute,
            //                                      iconSize: iconSize,
            //                                      padding: innerPadding)
//            .simultaneousGesture(soundGesture())
//                RoundedRectangle(cornerRadius: 10)
//                    .foregroundStyle(.thinMaterial)
//                    .frame(width: height, height: height)
//                    .simultaneousGesture(adjustSound())
            
            btnMuteToggle(mute: mute,
                          height: height,
                          iconSize: iconSize,
                          padding: innerPadding)

                    
            
        }
        .foregroundColor(.white)
    }
    
    func soundGesture() -> some Gesture {
        LongPressGesture(minimumDuration: 1)
            .onChanged { value in
                print(value.description)
            }
    }
    // 버튼 1/4. 재생 토글
    func btnPlayToggle(play: Binding<VideoState>, iconSize: CGFloat, padding: CGFloat) -> some View {
        return Button {
            if userGesture != .videoSeeking {
                if sliderValue == 1.0 {
                    sliderValue = 0
                    avPlayer?.seek(to: .zero)
                }
                if play.wrappedValue != .play {
                    withAnimation(.interactiveSpring()) {
                        self.play = .play
                    }
                    if self.timeObserver == nil {
                        addObserverToPlayer()
                    }
                    // play & pasue by button
                    if avPlayer.status == .readyToPlay {
                        if offsetIndex == 0 {
                            avPlayer.play()
                        }
                    }
                } else {
                    withAnimation(.interactiveSpring()) {
                        self.play = .pause
                    }
                    avPlayer.pause()
                }
            }
        } label: {
            LabelPlayAndPause(
                isPlaying: offsetIndex == 0
                            ? .constant(play.wrappedValue == .play)
                            : .constant(false),
                iconSize: iconSize
            )
            .padding(.vertical, padding)
            .padding(.horizontal, padding / 2)
        }
    }
    // 버튼 2/4. 뒤로 5초
    func btnBackward(iconSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            if userGesture != .videoSeeking {
                if let bool = avPlayer.currentItem?.canStepBackward,
                    bool == true {
                    currentTime -= currentTime <= 0 ? 0 : 5
                    avPlayer.seek(to: CMTime(seconds: currentTime, preferredTimescale: 1))
                    
                } else {
                    currentTime = 0
                    avPlayer.seek(to: CMTime(seconds: 0,
                                             preferredTimescale: 1))
                }
                if play != .play {
                    sliderValue = Float(currentTime < 0 ? 0 : currentTime / asset.duration)
                }
            }
        } label: {
            imageScaledFit(systemName: "gobackward.5", width: iconSize, height: iconSize)
                .padding(.vertical, padding)
                .padding(.horizontal, padding / 2)
        }
    }
    // 버튼 3/4. 앞으로 5초
    func btnForward(iconSize: CGFloat, padding: CGFloat) -> some View {
        Button {
            if userGesture != .videoSeeking {
                if let bool = avPlayer.currentItem?.canStepForward,
                    bool == true {
                    currentTime += currentTime >= asset.duration ? 0 : 5
                    avPlayer.seek(to: CMTime(seconds: currentTime,
                                             preferredTimescale: 1))
                } else {
                    currentTime = avPlayer.currentItem?
                        .preferredForwardBufferDuration.magnitude ?? 0
                    avPlayer.seek(to: CMTime(seconds: currentTime,
                                             preferredTimescale: 1))
                }
                if play != .play {
                    sliderValue = Float(currentTime > asset.duration ? 1.0 : currentTime / asset.duration)
                }
            }
        } label: {
            imageScaledFit(systemName: "goforward.5", width: iconSize, height: iconSize)
                .padding(.vertical, padding)
                .padding(.horizontal, padding / 2)
        }
    }
    // 버튼 4/4. 뮤트 토글
    func btnMuteToggle(mute: Bool, height: CGFloat, iconSize: CGFloat, padding: CGFloat) -> some View {
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
                    .foregroundStyle(.thinMaterial)
                imageScaledFit(systemName: muteIcon,
                                   width: iconSize,
                                   height: iconSize)
                .padding(padding)
                .matchedGeometryEffect(id: "mute", in: nameSpace)
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
    
    func adjustSound() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged({ value in
                print(value.translation.height)
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
    
    func btnStopPlay(iconSize: CGFloat, padding: CGFloat, disabled: Bool = false) -> some View {
        Button {
            withAnimation {
                play = .stop
            }
            DispatchQueue.main.async {
                resetVideo(isFullEnded: false)
                removeObserver()
            }
        } label: {
            imageScaledFit(systemName: "stop.fill", width: iconSize, height: iconSize)
                .padding(.vertical, padding)
                .padding(.horizontal, padding / 2)
        }
        .disabled(disabled)
    }
    func processingText(needSlash: Bool = false, time: String) -> some View {
        HStack(spacing: 3) {
            if needSlash {
                Text("/")
            }
            Text(time)
        }
        .font(.system(.subheadline, design: .monospaced))
        .contentTransition(.numericText())
        .foregroundStyle(.gray)
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
    func resetVideo(isFullEnded: Bool = true) {
        DispatchQueue.main.async {
            play = .stop
            avPlayer?.pause()
            avPlayer?.seek(to: .zero)
            play2x = false
            if isFullEnded {
                sliderValue = 0
            } else {
                withAnimation {
                    sliderValue = 0
                }
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
            let remain = runningTime - time.seconds
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
                if userGesture == .none {
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.1)) {
                            self.hideTools.toggle()
                        }
                    }
                }
            }
    }
    
    // video seek Gestrue
    func seekGesture(current: Binding<Double>, geoProxy: GeometryProxy) -> some Gesture {
        var movedWidth: CGFloat = 0
        
        return DragGesture(minimumDistance: 1)
            .onChanged { newValue in
                if userGesture != .videoSeeking {
                    tempSliderPosition = sliderValue
                }
                userGesture = .videoSeeking
                avPlayer?.pause()
                                    
                if let item = avPlayer.currentItem {
                    guard !(item.duration.seconds.isNaN || item.duration.seconds.isInfinite) 
                    else {
                        return
                    }
                    movedWidth = CGFloat(newValue.translation.width
                                         / (geoProxy.size.width * 0.5))
                    let movePercent = tempSliderPosition + Float(movedWidth)
                    sliderValue = movePercent < 0 ? 0 : (movePercent > 1 ? 1 : movePercent)
                    currentTime = item.duration.seconds * Double(sliderValue)
                    avPlayer?
                        .seek(to: CMTime(seconds: currentTime,
                                         preferredTimescale: 1))
                }
            }
            .onEnded { newValue in
                tempSliderPosition = 0
                DispatchQueue.main.async {
                    if play == .play {
                        avPlayer?.play()
                    }
                }
                userGesture = .none
            }
    }
    
    // sound adjust Gestrue
    func soundGesture(current: Binding<Double>, geoProxy: GeometryProxy) -> some Gesture {
        var movedHeight: CGFloat = 0
        return DragGesture(minimumDistance: 1)
            .onChanged { newValue in
                userGesture = .videoSeeking
                tempSliderPosition = sliderValue
                avPlayer?.pause()
                self.offsetX = 0
                self.offsetY = 0
                if let item = avPlayer.currentItem {
                    guard !(item.duration.seconds.isNaN || item.duration.seconds.isInfinite)
                    else {
                        return
                    }
                    movedHeight = CGFloat(newValue.translation.width / (geoProxy.size.width * 0.7))
                    let movePercent = tempSliderPosition + Float(movedHeight)
                    sliderValue = movePercent < 0 ? 0 : (movePercent > 1 ? 1 : movePercent)
                    currentTime = item.duration.seconds * Double(sliderValue)
                    avPlayer?
                        .seek(to: CMTime(seconds: currentTime,
                                         preferredTimescale: 1))
                }
            }
            .onEnded { newValue in
                tempSliderPosition = 0
                DispatchQueue.main.async {
                    if play == .play {
                        avPlayer?.play()
                    }
                }
                userGesture = .none
            }
    }

    func assetHeight(asset: PHAsset) -> CGFloat {
        return screenWidth * CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
    }
    
    func needOpacity(asset: PHAsset) -> Bool {
        return screenSize.height
        - assetHeight(asset: asset)
        - statusBarHeight
        > tabbarHeight + 50
    }
    func speedPlay(isStart: Bool) {
        if play == .play {
            play2x = isStart
            if isStart {
                let hapticManager = HapticManager.instance
                hapticManager.impact(style: .light)
            }
        }
    }
    
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(offsetIndex: 0,
                        asset: MLAsset(phAsset: PHAsset(), isAlbum: true),
                        imageManager: PHCachingImageManager(),
                        size: .zero,
                        play: .constant(.play),
                        hideTools: .constant(false),
                        userGesture: .constant(.none),
                        offsetY: .constant(0),
                        offsetX: .constant(0))
        .preferredColorScheme(.dark)
    }
}

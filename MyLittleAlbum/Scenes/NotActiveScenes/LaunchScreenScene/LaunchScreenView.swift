//
//  LaunchScreenView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/18.
//

import SwiftUI
import AVKit
//import AVFoundation


struct LaunchScreenView: View {
    @ObservedObject var launchScreenManger: LaunchScreenManager
    
    @State var textGo: Bool = false
    @State var videoPlayer: AVPlayer!
    @Binding var maskingScale: CGFloat
    @Binding var isOpen: Bool
    
    var animationTimer = Timer
        .publish(every: 0.6, on: .current, in: .common)
        .autoconnect()
    
    var body: some View {
        ZStack {
            // 레이어 1: 백그라운드 컬러
            FancyBackground()
                .onAppear { loadVideo() }
            // 레이어 2: 반짝 텍스트
            textGrowl
                .opacity(textGo ? 1 : 0)
            if videoPlayer != nil {
            // 레이어 3: 마스크 써클 비디오 [메인 비디오]
                maskedCircleVideo(player: videoPlayer)
            // 레이어 4: 타이틀 뷰 [비디오 뜨기 전에]
                BackgroudStateView()
                    .opacity(launchScreenManger.state == .ready ? 1 : 0)
                    .onReceive(animationTimer) { _ in
                        updateAnimation()
                        launchScreenManger.state = .first
                    }
            }
        }
    }
}


// subViews
extension LaunchScreenView {
    // 2. 반짝 텍스트
    var textGrowl: some View {
        let width = screenSize.width
        let height = screenSize.height
        return Image("growl")
            .resizable(resizingMode: .tile)
            .frame(width: width, height: height, alignment: .center)
    }
    // 3. 마스크드 써클 비디오
    func maskedCircleVideo(player: AVPlayer) -> some View {
        let width = screenSize.width
        let height = screenSize.height
        return AVPlayerController(player: player)
            .scaledToFill()
            .ignoresSafeArea()
            .frame(width: width, height: height, alignment: .center)
            .mask {
                Color.fancyBackground
                    .clipShape(Circle())
                    .ignoresSafeArea()
                    .scaleEffect(maskingScale)
                    .offset(y: -90)
            }
    }
}


// functions
extension LaunchScreenView {
    
    func loadVideo() {
        // 1. video
        guard let url = Bundle.main.url(forResource: "doonge", withExtension: "mov") else { return }
        let player = AVPlayer(url: url)
        player.allowsExternalPlayback = false
        videoPlayer = player
        pauseBackgroundAudio()
    }
    
    func updateAnimation() {
        switch launchScreenManger.state {
        case .first:
            if videoPlayer.status == .readyToPlay {
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.25)) {
                    maskingScale = 0.8
                }
                
                videoPlayer.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    launchScreenManger.state = .second
                }
            }
        case .second:
            withAnimation(.easeIn(duration: 0.2)) {
                textGo = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                launchScreenManger.state = .third
            }
            
        case .third:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                launchScreenManger.state = .forth
            }
            withAnimation(.linear(duration: 0.25)) {
                textGo = false
            }
        case .forth:
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.8)) {
                maskingScale = 0.0001
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                launchScreenManger.state = .complete
                resumeBackgroundAudio()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.linear(duration: 0.5)) {
                    isOpen = true
                }
            }
        default:
            break
        }
    }
    
    func pauseBackgroundAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.ambient, mode: .default, options: .mixWithOthers)
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


struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView(launchScreenManger: LaunchScreenManager(), maskingScale: .constant(4), isOpen: .constant(true))
    }
}




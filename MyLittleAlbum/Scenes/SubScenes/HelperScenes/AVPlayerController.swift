//
//  AVPlayerController.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/17.
//

import SwiftUI
import AVKit

struct AVPlayerController : UIViewControllerRepresentable {
    
    let player: AVPlayer!

    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.player?.allowsExternalPlayback = false
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
}

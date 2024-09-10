//
//  CustomSeekBar.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/17.
//

import SwiftUI
import AVKit

struct CustomSeekBar: UIViewRepresentable {
    let value: Float
//    @Binding var avPlayer: AVPlayer!
//    @Binding var play: Bool
//    @Binding var isSeeking: Bool
    let slider: UISlider
//    @Binding var currentTime: Double
    
    func makeUIView(context: UIViewRepresentableContext<CustomSeekBar>) -> UISlider {
    
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .gray
        slider.setThumbImage(UIImage(), for: .normal)
        slider.value = value
//        slider.addTarget(context.coordinator,
//                         action: #selector(context.coordinator.changed(slider:)),
//                         for: .valueChanged)
        slider.layer.cornerRadius = 1
        slider.clipsToBounds = true
        slider.isContinuous = true
//        DispatchQueue.main.async {
//            self.slider = slider
//        }
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: UIViewRepresentableContext<CustomSeekBar>) {
        withAnimation {
            uiView.value = value
        }
    }
            
    
    func makeCoordinator() -> CustomSeekBar.Coordinator {
        return CustomSeekBar.Coordinator(self)
    }
    
    class Coordinator: NSObject {
        
        var parent: CustomSeekBar
        
        init(_ parent: CustomSeekBar) {
            self.parent = parent
        }
        
//        @objc func changed(slider: UISlider) {
//            guard let item = parent.avPlayer.currentItem else { return }
//            let sec = Int(slider.value * Float((item.duration.seconds)))
//            if slider.isTracking {
//                parent.avPlayer.pause()
//                parent.avPlayer.seek(to: CMTime(seconds: Double(sec), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
//            } else {
//                parent.currentTime = Double(sec)
//                parent.avPlayer?.seek(to: CMTime(seconds: Double(sec), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
//                if parent.play {
//                    parent.avPlayer.play()
//                }
//                parent.isSeeking = false
//            }
//        }
    }

}

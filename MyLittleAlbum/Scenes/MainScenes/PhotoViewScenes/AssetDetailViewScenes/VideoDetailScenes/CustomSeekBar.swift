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
    let slider: UISlider
    
    func makeUIView(context: UIViewRepresentableContext<CustomSeekBar>) -> UISlider {
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .gray
        slider.setThumbImage(UIImage(), for: .normal)
        slider.value = value
        slider.layer.cornerRadius = 5
        slider.clipsToBounds = true
        slider.isContinuous = true
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
        
    }

}

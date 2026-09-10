//
//  MediaPlayers.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/1/25.
//

import MediaPlayer

extension MPVolumeView {
    static func catchVolume() -> CGFloat {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        return CGFloat(slider?.value ?? 0)
    }
    static func setVolume(_ volume: Float) -> Void {
       let volumeView = MPVolumeView()
       let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

       DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
           slider?.value = volume
       }
   }
}

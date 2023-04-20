//
//  VPlayer.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/12.
//

import SwiftUI
import AVKit

//struct VPlayer: UIViewRepresentable {
//    
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        
//    }
//    
//    func makeUIView(context: Context) -> some UIView {
//        return PlayerUIView(frame: .zero)
//    }
//}
//
//class PlayerUIView: UIView {
//    private var playerLayer = AVPlayerLayer()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        guard let url = Bundle.main.url(forResource: "doonge", withExtension: "mov") else { return }
//        let player = AVPlayer(url: url)
//        playerLayer.player = player
//        playerLayer.videoGravity = .resizeAspectFill
//        layer.addSublayer(playerLayer)
//        
//        DispatchQueue(label: "launch").async {
//            player.play()
//        }
//        
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        playerLayer.frame = bounds
//    }
//}
//struct VPlayer_Previews: PreviewProvider {
//    static var previews: some View {
//        VPlayer()
//    }
//}

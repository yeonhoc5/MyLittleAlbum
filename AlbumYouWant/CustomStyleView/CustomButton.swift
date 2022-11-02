//
//  CustomButton.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/27.
//

import SwiftUI

struct CusotmeBtnStyle: ButtonStyle {
    
    var scale: CGFloat = 0.97
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale:1.0)
    }
}

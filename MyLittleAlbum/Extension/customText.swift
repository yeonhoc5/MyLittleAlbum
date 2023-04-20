//
//  customText.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/16.
//

import SwiftUI

extension View {
    
    func titleText(_ text: String, font: Font, color: Color) -> some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
    }
    
    
    func spacerRectangle(color: Color, height: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}

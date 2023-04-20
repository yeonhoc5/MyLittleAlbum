//
//  CustomProgressView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/08.
//

import SwiftUI

struct CustomProgressView: View {
    var color: Color! = .color1
    var size: CGFloat! = 120
    
    var body: some View {
        ProgressView()
            .tint(color)
            .progressViewStyle(.circular)
            .scaleEffect(1.5)
            .background() {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: size, height: size)
                    .foregroundColor(.white.opacity(1))
            }
    }
}

struct CustomProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CustomProgressView()
            .background {
                Color.fancyBackground
            }
    }
}

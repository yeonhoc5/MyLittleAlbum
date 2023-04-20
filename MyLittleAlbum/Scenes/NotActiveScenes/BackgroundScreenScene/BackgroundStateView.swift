//
//  SwiftUIView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/19.
//

import SwiftUI

struct BackgroudStateView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            Image("MyLittleAlbum")
                .resizable()
                .scaledToFit()
                .frame(width: screenSize.width * 0.35)
                .position(x: screenSize.width / 2, y: screenSize.height / 2 * 0.8)
        }
    }
}

struct BackgroudStateView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroudStateView()
    }
}

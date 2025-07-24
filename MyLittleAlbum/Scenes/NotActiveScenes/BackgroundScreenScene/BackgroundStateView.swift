//
//  SwiftUIView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/19.
//

import SwiftUI

struct BackgroudStateView: View {
    @Namespace var nameSpace
    
    var body: some View {
//        let height = device == .phone ? 0.16 : 0.2
        return ZStack {
            Color("LaunchBackColor")
                .ignoresSafeArea()
            Image("LaunchCenterImage")
                .resizable()
                .scaledToFit()
                .frame(width: screenSize.height * 0.16)
                .position(x: screenSize.width / 2,
                          y: screenSize.height * 0.8 / 2)
                .transition(.scale)
        }
        .ignoresSafeArea()
    }
}

struct BackgroudStateView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroudStateView()
    }
}

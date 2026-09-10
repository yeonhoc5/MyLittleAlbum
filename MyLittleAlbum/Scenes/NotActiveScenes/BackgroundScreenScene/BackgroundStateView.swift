//
//  SwiftUIView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/19.
//

import SwiftUI

struct BackgroudStateView: View {
  let size: CGSize
  @Namespace var nameSpace
  
  var body: some View {
    return ZStack {
      Color("LaunchBackColor")
        .ignoresSafeArea()
      Image("LaunchCenterImage")
        .resizable()
        .scaledToFit()
        .frame(width: size.height * 0.16)
        .offset(y: -size.height * 0.025)
    }
    .ignoresSafeArea()
  }
}

struct BackgroudStateView_Previews: PreviewProvider {
  static var previews: some View {
    GeometryReader { geoproxy in
      BackgroudStateView(size: geoproxy.size)
    }
  }
}

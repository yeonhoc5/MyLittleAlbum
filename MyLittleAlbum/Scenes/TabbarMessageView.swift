//
//  TabbarMessageView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/26/26.
//

import SwiftUI

struct TabbarMessageView<S: View, T: View, V: View>: View {
  @Binding var isShowingMessageView: Bool
  @Binding var tutorialOn: Bool
  @Binding var selectedInt: Int
  let size: CGSize
  let maxWidth: CGFloat = 500
  let maxHeight: CGFloat
  let verticalPadding: CGFloat = 70
  let radius: CGFloat = 20
  @Namespace var nameSpace
  let isPhotosView: Int
  let isShowingSettingView: Bool
  let cardView: () -> S
  let tutorialContent: (S, CGFloat, CGFloat, CGFloat) -> T
  let tabbarContent: () -> V
  
  var body: some View {
    ZStack(alignment: .bottom) {
      if isShowingMessageView {
        Rectangle()
          .foregroundStyle(.ultraThinMaterial)
          .ignoresSafeArea()
          .transition(.opacity)
      }
      cardView()
        .overlay(content: {
          tabbarContent()
        })
        .tabBarLayout(height: tabbarHeight,
                      screenWidth: size.width,
                      isPhotosView: isPhotosView > 0,
                      padEdge: .leading)
        .offset(y: isShowingSettingView ? 150 : 0)
    }
  }
}

#Preview {
  TabbarMessageView(
    isShowingMessageView: .constant(true),
    tutorialOn: .constant(false),
    selectedInt: .constant(0),
    size: .zero,
    maxHeight: 500,
    isPhotosView: 0,
    isShowingSettingView: false,
    cardView: {
      Text("card Content")
    },tutorialContent: {_, _, _, _ in
      Text("tutorial Content")
    }) {
      Text("tabbar Content")
    }
}

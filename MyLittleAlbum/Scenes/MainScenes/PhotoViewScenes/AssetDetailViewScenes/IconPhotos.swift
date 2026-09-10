//
//  IconPhotos.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/21/26.
//

import SwiftUI

struct IconPhotos: View {
  let lineWidth: CGFloat
  let colors1: [Color] = [.orange, .blue, Color.color13, Color.color5]
  let colors2: [Color] = [.yellow, .purple, .red, .green]
  let opacity: Double = 0.2
  
  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      ZStack {
        capsule4way(width: width,
                    lineWidth: lineWidth,
                    colors: colors1.map { $0.opacity(opacity) })
        capsule4way(width: width,
                    lineWidth: lineWidth,
                    colors: colors2.map { $0.opacity(opacity) })
          .rotationEffect(.degrees(45))
      }
      .frame(width: width, height: width)
    }
  }
  
  func capsule4way(width: CGFloat, lineWidth: CGFloat, colors: [Color]) -> some View {
    let spacing = width/6
    let short = width/3.5
    return Group {
      VStack(spacing: spacing) {
        capsuleWidth(width: true, short: short)
          .foregroundStyle(colors[0])
        capsuleWidth(width: true, short: short)
          .foregroundStyle(colors[1])
      }
      HStack(spacing: spacing) {
        capsuleWidth(width: false, short: short)
          .foregroundStyle(colors[2])
        capsuleWidth(width: false, short: short)
          .foregroundStyle(colors[3])
      }
    }
  }
  
  func capsuleWidth(width: Bool, short: CGFloat) -> some View {
    Capsule()
      .modify({ view in
        if width {
          view
            .frame(width: short)
        } else {
          view
            .frame(height: short)
        }
      })
  }
}
#Preview {
    IconPhotos(lineWidth: 2)
}

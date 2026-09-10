//
//  LabelPlayAndPause.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/5/24.
//

import SwiftUI

struct LabelPlayAndPause: View {
  @Binding var isPlaying: Bool
  @Namespace var nameSpace
  let iconSize: CGFloat
  
  var body: some View {
    GeometryReader { geo in
      HStack(spacing: isPlaying ? geo.size.width * 0.3 : 0) {
        Group {
          RoundedRectangle(cornerRadius: isPlaying ? 2 : 0)
          RoundedRectangle(cornerRadius: 2)
        }
        .frame(width: geo.size.width * (isPlaying ? 0.3 : 0.5))
      }
      .frame(width: geo.size.width)
    }
    .frame(width: iconSize, height: iconSize)
    .mask({
      Triangle(insetAmount: isPlaying ? 0 : iconSize / 2)
        .frame(width: iconSize, height: iconSize)
    })
  }
}

#Preview {
  LabelPlayAndPause(isPlaying: .constant(false), iconSize: 40)
}

struct Triangle: Shape {
  var insetAmount: Double
  var animatableData: Double {
    get { insetAmount }
    set { insetAmount = newValue }
  }
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let start = CGPoint(x: rect.minX, y: rect.midY)
    let pointA = CGPoint(x: rect.minX, y: rect.minY)
    let pointB1 = CGPoint(x: rect.maxX, y: insetAmount - rect.minY)
    let pointB2 = CGPoint(x: rect.maxX, y: rect.maxY - insetAmount)
    let pointC = CGPoint(x: rect.minX, y: rect.maxY)
    path.move(to: start)
    path.addLines([pointA, pointB1, pointB2, pointC, start])
    return path
  }
}

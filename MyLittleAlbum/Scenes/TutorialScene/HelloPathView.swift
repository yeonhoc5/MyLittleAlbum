//
//  HelloPathView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/10/26.
//

import SwiftUI

struct HelloPathView: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    
    let h = rect.height
    // Frame 높이에 따라 글짜 크기 결정
    let textW = h * 1.5
    let w = rect.width
    let spacerLineX: CGFloat = (w - textW) / 2
    let startPoint = CGPoint(x: 0, y: h * 0.5)
    let endPoint = CGPoint(x: w, y: h * 0.5)
    let textSP = CGPoint(x: spacerLineX,
                         y: (2 * h) / 3)
    let textEP = CGPoint(x: spacerLineX + textW,
                         y: (2 * h) / 3)
    
    func lwp(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: x * spacerLineX, y: y * h)
    }
    func rwp(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: spacerLineX + textW + (x * spacerLineX), y: y * h)
    }
    func tp(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: spacerLineX + (x * textW),
              y: y * h)
    }
    
    // MARK: - Begin tracing from left tail
    path.move(to: startPoint)
    
    path.addCurve(
      to: textSP,
      control1: lwp(0.2, 0.8),
      control2: lwp(0.8, 0.9)
    )
    path.addCurve(
      to: tp(0, 0.8),
      control1: tp(0.3, 0),
      control2: tp(0, 0)
    )
    path.addCurve(
      to: tp(0.28, 0.75),
      control1: tp(0.3, 0.1),
      control2: tp(0, 1)
    )
    path.addCurve(
      to: tp(0.28, 0.75),
      control1: tp(0.5, 0.45),
      control2: tp(0.2, 0.52)
    )
    path.addCurve(
      to: tp(0.49, 0.7),
      control1: tp(0.3, 0.82),
      control2: tp(0.44, 0.8)
    )
    path.addCurve(
      to: tp(0.49, 0.7),
      control1: tp(0.8, 0),
      control2: tp(0.5, 0)
    )
    path.addCurve(
      to: tp(0.66, 0.7),
      control1: tp(0.5, 0.82),
      control2: tp(0.6, 0.8)
    )
    path.addCurve(
      to: tp(0.66, 0.7),
      control1: tp(0.97, 0),
      control2: tp(0.67, 0)
    )
    path.addCurve(
      to: tp(0.9, 0.52),
      control1: tp(0.67, 0.82),
      control2: tp(0.8, 0.8)
    )
    path.addCurve(
      to: textEP,
      control1: tp(0.78, 0.8),
      control2: tp(0.95, 0.82)
    )
    path.addCurve(
      to: textEP,
      control1: tp(1.05, 0.4),
      control2: tp(0.87, 0.5)
    )
    path.addCurve(
      to: endPoint,
      control1: rwp(0.2, 0.9),
      control2: rwp(0.8, 0.8)
    )
    return path
  }
}

#Preview {
    HelloPathView()
}

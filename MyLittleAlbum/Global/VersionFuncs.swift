//
//  VersionFuncs.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/3/26.
//

import SwiftUI

extension View {
  func glassContainterHStack(_ contents: @escaping () -> some View,
                             spacing: CGFloat) -> some View {
    Group {
      if #available(iOS 26.0, *) {
        GlassEffectContainer(spacing: spacing) {
          contents()
        }
      } else {
        HStack(spacing: spacing) {
          contents()
        }
      }
    }
  }
  func controllGroup17HStack(_ contents: @escaping () -> some View) -> some View {
    Group {
      if #available(iOS 17.0, *) {
        ControlGroup {
          contents()
        }
      } else {
        contents()
      }
    }
  }
  // capsule
  func glassEffect26<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
    if #available(iOS 26, *) {
      return self
        .glassEffect(.clear)
    } else {
      return modifier(self)
    }
  }
}

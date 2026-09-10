//
//  ExtensionView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/24/25.
//

import SwiftUI
import LottieUI

enum PadEdge {
  case leading, trailing, none
  func rawValue() -> Edge.Set {
    switch self {
    case .leading: [.leading]
    case .trailing: [.trailing]
    case .none: []
    }
  }
}
extension View {
  func navigationBlurView(height: CGFloat,
                          color: Color = .fancyBackground,
                          reverse: Bool = false) -> some View {
    Rectangle()
      .foregroundStyle(color)
    .mask {
      LinearGradient(colors: [1, 0.9, 0.8, 0.6, 0.5, 0]
                      .map { .fancyBackground.opacity($0) },
                     startPoint: reverse ? .bottom : .top,
                     endPoint: reverse ? .top : .bottom)
    }
    .frame(height: height)
  }
  func conditionalStackView(condition: Bool, spacing: CGFloat = 0, vAlignment: HorizontalAlignment = .leading, views: @escaping () -> some View) -> some View {
    Group {
      if condition {
        VStack(alignment: vAlignment, spacing: spacing) {
          views()
        }
      } else {
        HStack(alignment: .center, spacing: spacing) {
          views()
        }
      }
    }
  }
  func cardView(device: UIUserInterfaceIdiom,
                radius: CGFloat = 20,
                glassEffect: Bool = true,
                color: Color = .fancyBackground) -> some View {
    let isPad = device == .pad
    return Group {
      if #available(iOS 26, *) {
        let shape = RoundedRectangle(cornerRadius: radius)
        shape
          .foregroundStyle(color.opacity(glassEffect ? 0.5 : 1))
          .conditionalModifier(glassEffect, transform: { view in
            view
              .glassEffect(in: shape)
          })
      } else {
        RoundedRectangle(cornerRadius: radius)
          .foregroundStyle(isPad ? Color.white : color)
      }
    }
  }
  func navigationTitleView(title: String, subTitle: String) -> some ToolbarContent {
    ToolbarItem(placement: .principal) {
      if device == .pad {
        HStack(alignment: .firstTextBaseline, content: {
          Text(title)
            .font(.body)
            .foregroundStyle(.white)
          Text("/ \(subTitle)")
            .font(.caption)
            .foregroundStyle(.gray)
            .contentTransition(.numericText())
        })
      } else {
        VStack(alignment: .leading) {
          Text(title)
            .font(.body)
            .foregroundStyle(.white)
          Text("/ \(subTitle)")
            .font(.caption)
            .foregroundStyle(.gray)
            .contentTransition(.numericText())
        }
      }
    }
  }
  func tabbarPadding(sidePadding: Bool) -> some View {
    return self
      .modify { view in
        if #available(iOS 26.0, *) {
          view.safeAreaPadding(.all)
        } else if device == .pad, #available(iOS 17.0, *) {
          view.safeAreaPadding(.all)
        } else {
          view.padding(.horizontal, sidePadding ? 15 : 0)
        }
    }
  }
  
  func tabBarLayout(height: CGFloat,
                    screenWidth: CGFloat,
                    albumType: AlbumType = .album,
                    isPhotosView: Bool,
                    bottomPadding: Bool = true,
                    sidePadding: Bool = false,
                    padEdge: PadEdge = .none) -> some View {
    let isPad = device == .pad
    let widthR: CGFloat = !isPad ? 1
                          : (albumType == .picker
                             ? 1 : (isPhotosView ? 2 : 3/2))
    return self
      .frame(height: height)
      .tabbarPadding(sidePadding: sidePadding)
      .frame(width: screenWidth / widthR)
      .padding(.bottom, bottomPadding ? 0 :(isPad ? 10 : 0))
      .padding(padEdge.rawValue(), isPad && isPhotosView ? 10 : 0)
  }
  func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
    return modifier(self)
  }
  func toolbarSettingView(showing: Binding<Bool>) -> some View {
    Button {
      dispatchAnimation {
        showing.wrappedValue.toggle()
      }
    } label: {
      Label("Setting", systemImage: iconSetting)
        .labelStyle(.iconOnly)
        .foregroundStyle(.gray)
        .rotationEffect(
          .degrees(showing.wrappedValue ? -180 : 0)
        )
    }
    .buttonStyle(ClickScaleEffect())
  }
  
  @ViewBuilder func conditionalModifier<T: View>(
    _ condition: Bool, transform: (Self) -> T) -> some View {
      Group {
        if condition {
          transform(self)
        } else {
          self
        }
      }
      .animation(.bouncy, value: condition)
    }
  
  func tempView(geoProxy: GeometryProxy, size: CGFloat, backgroundColor: Color = .fancyBackground, needAnimationView: Bool = true, onAppear: @escaping () -> Void) -> some View {
    ZStack {
//      backgroundColor
      RoundedRectangle(cornerRadius: 20)
        .opacity(0)
      if needAnimationView {
        lottieLoadingView(
          lottie: "photoLoading",
          size: CGSize(width: size, height: size),
          leadingPadding: 0)
        .padding(.bottom, tabbarHeight / 2)
      }
    }
//    .ignoresSafeArea()
    .onAppear {
      phPhotosQueue
        .asyncAfter(deadline: .now() + (needAnimationView ? 0.5 : 0)) {
          onAppear()
        }
    }
  }
  
  //    func version26Modify<T: View>(@ViewBuilder _ modifier: (Self) -> T, version: String) -> some View {
  //        if #available(iOS 26.0, *) {
  //            return modifier(self)
  //        } else {
  //            return modifier(self)
  //        }
  //    }
  // roundedRectangle
  func availabeGlassEffect<T: View, S: ShapeStyle>(
    cornerR: CGFloat, foreground: S, @ViewBuilder _ modifier: (Self) -> T) -> some View {
      if #available(iOS 26, *) {
        return self
          .foregroundStyle(foreground)
          .glassEffect(.clear,
                       in: .rect(cornerRadius: cornerR))
      } else {
        return modifier(self)
      }
  }
  
  func cardShape(cornerR: CGFloat) -> some Shape {
    if #available(iOS 26.0, *) {
      return ConcentricRectangle(corners: .concentric,
                                  isUniform: false)
    } else {
      return RoundedRectangle(cornerRadius: cornerR)
    }
  }
  func availableGlassCardView(cornerR: CGFloat) -> some View {
    Group {
      if #available(iOS 26.0, *) {
        let shape = ConcentricRectangle(corners: .concentric,
                            isUniform: false)
        shape
          .foregroundStyle(.ultraThinMaterial)
          .glassEffect(.regular, in: shape)
      } else {
        RoundedRectangle(cornerRadius: cornerR)
          .foregroundStyle(.thinMaterial)
      }
    }
  }
  
  func spacerRectangle(color: Color, height: CGFloat) -> some View {
    Rectangle()
      .fill(color)
      .frame(height: height)
  }
  func lottieLoadingView(lottie: String, size: CGSize, leadingPadding: CGFloat) -> some View {
    let animationView = LottieView(lottie)
    return animationView
      .renderingEngine(.automatic)
      .play(true)
      .backgroundBehavior(.forceFinish)
      .loopMode(.loop)
      .padding(.leading, leadingPadding)
      .frame(width: abs(size.width), height: abs(size.height))
      .foregroundColor(.clear)
  }
}

// text
extension View {
  func titleText(_ text: String, font: Font, color: Color, inline: Bool! = false) -> some View {
    VStack(alignment: .leading) {
      if !inline && text != "" {
        if text.first! != "("
            && text.last! == ")"
            && text.filter({ $0 == "(" }).count == 1 {
          Text(text.split(separator: "(")[0])
            .lineLimit(1, reservesSpace: false)
          Text("(" + text.split(separator: "(")[1])
            .lineLimit(1, reservesSpace: false)
        } else if text.first! == "("
                    && text.last != ")"
                    && text.filter({ $0 == ")" }).count == 1 {
          Text(text.split(separator: ")")[0] + ")")
            .lineLimit(1, reservesSpace: false)
          Text(text.split(separator: ")")[1])
            .lineLimit(1, reservesSpace: false)
        } else {
          Text(text)
        }
      } else {
        Text(text)
      }
    }
    .font(font)
    .foregroundColor(color)
  }
}

// imageScaled
extension View {
  func imageScaledFill(_ name: String, width: CGFloat, height: CGFloat, radius: CGFloat! = 0) -> some View {
    Image(name)
      .resizable()
      .scaledToFill()
      .frame(width: width, height: height)
      .clipped()
      .cornerRadius(radius)
  }
  
  func imageScaledFill(systemName: String, width: CGFloat, height: CGFloat, radius: CGFloat! = 0) -> some View {
    Image(systemName: systemName)
      .resizable()
      .scaledToFill()
      .frame(width: width, height: height)
      .clipped()
      .cornerRadius(radius)
  }
  @ViewBuilder
  func imageScaledFill(uiImage: UIImage, width: CGFloat, height: CGFloat) -> some View {
    Image(uiImage: uiImage)
      .resizable()
      .scaledToFill()
      .frame(width: abs(width), height: abs(height))
      .allowsHitTesting(false)
  }
  
  func imageScaledFit(_ name: String, width: CGFloat, height: CGFloat) -> some View {
    Image(name)
      .resizable()
      .scaledToFit()
      .frame(width: width, height: height)
  }
  
  func imageScaledFit(systemName: String, width: CGFloat, height: CGFloat) -> some View {
    Image(systemName: systemName)
      .resizable()
      .scaledToFit()
      .frame(width: width, height: height)
  }
  
  func imageNonScaled(systemName: String, width: CGFloat, height: CGFloat, color: Color) -> some View {
    Image(systemName: systemName)
      .resizable()
      .foregroundColor(color)
      .frame(width: width)
      .offset(y: 1)
  }
  
  func imageWithScale(systemName: String, scale: Image.Scale = .medium) -> some View {
    Image(systemName: systemName)
      .imageScale(scale)
  }
  
  func dispatchAnimation(_ action: @escaping () -> Void) {
    DispatchQueue.main.async {
      withAnimation {
        action()
      }
    }
  }
  func dispatchAnimationDelay(delay: Double, _ action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      withAnimation {
        action()
      }
    }
  }
  func scrollViewWidthReader<V: View>(
    _ axes: Axis.Set = .vertical,
    showIndicator: Bool = false,
    scrollDisalble: Bool = false,
    @ViewBuilder content: @escaping (ScrollViewProxy) -> V) -> some View {
      ScrollViewReader { scrollProxy in
        ScrollView(axes) {
          content(scrollProxy)
        }
        .scrollDisabled(scrollDisalble)
        .scrollIndicators(showIndicator ? .visible : .hidden)
      }
  }
  func availableGlassContainer<V: View>(@ViewBuilder content: @escaping () -> V) -> some View {
    if #available(iOS 26, *) {
      return GlassEffectContainer {
        content()
      }
    } else {
      return Group {
        content()
      }
    }
  }
}

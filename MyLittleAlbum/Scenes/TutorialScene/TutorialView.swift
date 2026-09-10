//
//  TutorialView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/17/26.
//

import SwiftUI

struct TutorialView<T: View>: View {
  @EnvironmentObject var photoData: MLPhotoData
  let contentView: [Int] = [0, 1, 2, 3, 4, 5]
  let helloHeight: CGFloat
  let tutorialOn: Bool
  @Binding var selectedInt: Int
  let maxWidth: CGFloat
  let maxHeight: CGFloat
  let verticalPadding: CGFloat
  let outPadding: CGFloat = 30
  let nameSpace: Namespace.ID
  let cardView: () -> T
  let completion: () -> Void
  
  @State var progress: CGFloat = 0
  
  var body: some View {
    TabView(selection: $selectedInt) {
      ForEach(contentView, id: \.self) { int in
        eachStepView(int: int)
      }
      .padding(.horizontal, 30)
      .offset(y: outPadding / 2)
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .overlay {
      overlayIndexView()
    }
  }
}

extension TutorialView {
  func eachStepView(int: Int) -> some View {
      ZStack {
        Group {
          cardView()
            .matchedGeometryEffect(id: "\(int)",
                                   in: nameSpace,
                                   isSource: false)
          StepView(outPadding: outPadding, step: int, completion: {
            completion()
          })
          .padding(.horizontal, outPadding)
        }
      }
      .tag(int)
      .frame(maxWidth: maxWidth, maxHeight: maxHeight)
  }
  func overlayIndexView() -> some View {
    ZStack(alignment: .top) {
      HelloPathView()
        .trim(from: 0, to: progress)
        .stroke(Color.white,
                style: StrokeStyle(lineWidth: 1 + (progress * 2),
                                   lineCap: .round,
                                   lineJoin: .round))
        .frame(height: helloHeight)
        .offset(y: -20)
        .onAppear {
          withAnimation(Animation.easeIn(duration: 2.5)) {
            progress = 1.0
          }
        }
//        .onChange(of: photoData.loadingState, perform: { newValue in
//          if newValue == .  {
//            withAnimation(Animation.easeIn(duration: 2.5)) {
//              progress = 1.0
//            }
//          } else {
//            withAnimation(Animation.easeIn(duration: 2.5)) {
//              progress = 0
//            }
//          }
//        })
      VStack {
        btnClose
        Spacer()
        arrows(int: selectedInt)
          .foregroundStyle(.gray)
          .animation(.easeInOut, value: selectedInt)
      }
      .padding(.horizontal, outPadding)
      .frame(maxWidth: maxWidth - 10)
    }
    .frame(maxHeight: maxHeight + helloHeight + verticalPadding)
  }
  var backgroundView: some View {
    Rectangle()
      .foregroundStyle(.yellow)
      .ignoresSafeArea()
  }
  
  var btnClose: some View {
    HStack {
      Spacer()
      Button {
        completion()
      } label: {
        Image(systemName: "xmark")
          .resizable()
          .foregroundStyle(Color.lightGray)
          .frame(width: 20, height: 20)
          .padding(10)
      }
      .buttonStyle(ClickScaleEffect())
    }
  }
  func arrows(int: Int) -> some View {
    let views = HStack(spacing: 5) {
      ForEach(contentView, id: \.self) { int in
        Circle()
          .modify({ view in
            if #available(iOS 26.0, *) {
              view
                .foregroundStyle(.clear)
                .glassEffect()
            } else {
              view
                .foregroundStyle(Color.fancyBackground.opacity(0.8))
            }
          })
        .frame(width: 15, height: 15)
      }
    }
    return HStack(spacing: 50) {
      btnArrow(name: "arrowtriangle.left.fill",
               disable: int == 0) {
        selectedInt -= 1
      }
      available26 {
        views
      }
      .overlay(alignment: .leading) {
        Circle().foregroundStyle(Color.gray)
          .blur(radius: 1)
          .frame(width: 8, height: 8)
          .padding(3.5)
          .offset(x: CGFloat(selectedInt * 20))
      }
      btnArrow(name: "arrowtriangle.right.fill",
               disable: int == contentView.count - 1) {
        selectedInt += 1
      }
    }
  }
  func available26(views: @escaping () -> some View) -> some View {
    Group {
      if #available(iOS 26.0, *) {
        GlassEffectContainer(spacing: 12) {
          views()
        }
      } else {
        Group {
          views()
        }
      }
    }
  }
  func btnArrow(name: String,
                disable: Bool,
                action: @escaping () -> Void) -> some View {
    Button {
      withAnimation {
        action()
      }
    } label: {
      Image(systemName: name)
        .resizable()
        .scaledToFit()
        .frame(width: 18, height: 18)
    }
    .buttonStyle(ClickScaleEffect(scale: 0.8))
    .opacity(disable ? 0 : 1)
  }
}

#Preview {
  TutorialView(helloHeight: 100,
               tutorialOn: true,
               selectedInt: .constant(0),
               maxWidth: 500,
               maxHeight: 400,
               verticalPadding: 40,
               nameSpace: Namespace().wrappedValue) {
    Text("cardView")
  } completion: { }

}

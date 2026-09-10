//
//  StepView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/23/26.
//

import SwiftUI

struct StepView: View {
  let imageSize: CGFloat = 70
  let font: String = "MapoPeacefull"
  let outPadding: CGFloat
  let textSize: CGFloat = 20
  let textKerning: CGFloat = 1
  let textSpacing: CGFloat = 5
  let step: Int
  let completion: () -> Void
  
  var body: some View {
    Group {
      switch step {
      case 0: step0()
      case 1: step1()
      case 2: step2()
      case 3: step3()
      case 4: step4()
      default:
        endView()
      }
    }
    .foregroundStyle(.white)
  }
  
  func step0() -> some View {
    VStack(spacing: outPadding) {
      Spacer()
      textView(texts: {
        Group {
          Text("[마이리틀앨범]은")
          Text("iOS기기의 [사진]app과")
          HStack(spacing: 2) {
            Text("실시간 동기화")
              .foregroundStyle(.blue)
            Text("합니다.")
          }
        }
      })
      HStack(spacing: 20) {
        resizableImage(photoName: "MyLittleAlbum",
                       size: imageSize)
        .mask {
          RoundedRectangle(cornerRadius: imageSize / 4)
        }
        .shadow(color: .gray.opacity(0.2), radius: 4)
        .glassEffect26({ view in
          view
        })
        resizableImage(systemName: syncSymbol, size: 40)
          .fontWeight(.bold)
          .foregroundStyle(.blue)
          .modify({ view in
            if #available(iOS 18.0, *) {
              view
                .symbolEffect(.rotate)
            } else if #available(iOS 17.0, *) {
              view
                
            } else {
              view
            }
          })
        resizableImage(photoName: "Photos", size: imageSize)
      }
      .padding(.horizontal, 10)
      Spacer()
    }
  }
  func step1() -> some View {
    VStack(spacing: outPadding) {
      Spacer()
      textView {
        Group {
          Text("기기의 사진 데이터에")
          Text("직접 접근하므로")
          Text("앱의 용량이 커지지 않습니다.")
        }
      }
      photoView(name: "Step2")
      Spacer()
    }
  }
  func step2() -> some View {
    VStack(spacing: outPadding) {
      Spacer()
      textView {
        Group {
          Text("[마이리틀앨범]에서")
          Text("사진 모음함의 기본은")
          Text("<앨범에 없는 항목>").foregroundColor(.blue)
          + Text("입니다.")
        }
      }
      photoView(name: "Step3")
      Spacer()
    }
    .overlay(alignment: .leading) {
      starMark()
        .offset(x: -20, y: -60)
    }
  }
  func step3() -> some View {
    VStack(spacing: outPadding) {
      Spacer()
      textView {
        Group {
          HStack(spacing: 2) {
            Text("<노크>")
              .foregroundStyle(.blue)
            Text("기능을 사용하면")
          }
          Text("각 앨범에서")
          Text("\"가려진 사진\"을 관리할 수 있습니다.")
        }
      }
      photoView(name: "Step4")
      Spacer()
    }
    .overlay(alignment: .topLeading) {
      starMark()
        .padding(.top, 15)
        .offset(x: -30)
    }
  }
  func step4() -> some View {
    VStack {
      Spacer()
      textView {
        Group {
          Text("[마이리틀앨범]은")
          Text("사진에 관한 모든 기능이")
          Text("있는 App을 꿈꿉니다.")
          Text("")
          Text("차근차근 이뤄갈 예정이니")
          Text("기다려 주세요.")
        }
      }
      Spacer()
    }
  }
  func step(step: Int) -> some View {
    Text("step\(step)")
  }
  func endView() -> some View {
    VStack(spacing: outPadding) {
      Spacer()
      HStack {
        Spacer()
        VStack(alignment: .leading) {
          Text("Enjoy")
          Text("your BIG Album")
        }
        Spacer()
      }
      Button {
        completion()
      } label: {
        Capsule()
          .foregroundStyle(.blue)
          .glassEffect26 { capsule in
            capsule
          }
          .overlay {
            Text("시작하기")
          }
      }
      .frame(height: 60)
      .buttonStyle(ClickScaleEffect())
      .padding(.horizontal, 10)
      Spacer()
    }
    .font(Font.custom(font, size: textSize))
    .kerning(textKerning)
  }
  func starMark() -> some View {
    Image("starMark2")
      .resizable()
      .frame(width: 50, height: 50)
  }
  
  func resizableImage(systemName: String,
                      size: CGFloat, size2: CGFloat? = nil) -> some View {
    Image(systemName: systemName)
      .resizable()
      .scaledToFit()
      .frame(width: size2 ?? size, height: size)
  }
  func resizableImage(photoName: String,
                      size: CGFloat) -> some View {
    Image("\(photoName)")
      .resizable()
      .frame(width: size, height: size)
  }
  func photoView(name: String, radius: CGFloat = 20) -> some View {
    Image(name)
      .resizable()
      .scaledToFit()
      .cornerRadius(radius)
      .clipped()
  }
  
  func textView(texts: @escaping () -> some View) -> some View {
    VStack(alignment: .leading, spacing: textSpacing) {
      texts()
    }
    .font(Font.custom(font, size: textSize))
    .kerning(0)
  }
}

#Preview {
  StepView(outPadding: 30, step: 0) { }
}

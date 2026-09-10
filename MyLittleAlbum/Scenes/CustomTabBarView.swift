//
//  CustomTabBarView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/07.
//

import SwiftUI
import Photos

// MARK: - 1. Tabbar View
struct CustomTabBarView<V: View>: View {
  @EnvironmentObject var photoData: MLPhotoData
  @Binding var selectedTab: Tabs
  // 애니메이션 재실행 프라퍼티
  @ObservedObject var launchScreenManager: LaunchScreenManager
  let width: CGFloat
  let spacing: CGFloat
  @Binding var isOpen: Bool
  @Binding var maskingScale: CGFloat
  @Binding var albumTabTapped: Bool
  var isPhotosView: Int
  let nameSpace: Namespace.ID
  
  let actionTab1: () -> Void
  let actionTab2: () -> Void
  let actionTab3: () -> Void
  let actionTab4: () -> Void
  
  @Binding var isShowingHome: Bool
  @Binding var animationEnded: Bool
  let photosView: () -> V
  let closePhtosView: () -> Void
  
  var body: some View {
    return ZStack(alignment: .bottom) {
      let cornerRadius: CGFloat = 25
      if isShowingHome {
        // "사진함"
        Group {
          availableGlassCardView(cornerR: cornerRadius)
          photosView()
            .clipShape(cardShape(cornerR: 38))
            .padding(1)
        }
        .matchedGeometryEffect(id: "homeBack", in: nameSpace)
      }
      // "사진함" 버튼 + 앨범2개 탭버튼
      HStack(spacing: 10) {
        btnPhotos(cornerR: cornerRadius)
        tabButtons(cornerR: cornerRadius)
      }
      .frame(maxWidth: width > 600 ? width / 2 : width)
      .tabBarLayout(height: tabbarHeight,
                    screenWidth: width,
                    isPhotosView: isPhotosView > 0,
                    padEdge: .leading)
    }
  }
}

// MARK: - 2. subViews
extension CustomTabBarView {
  func tabButtons(cornerR: CGFloat) -> some View {
    GeometryReader { geometry in
      ZStack {
        Button {
          if isShowingHome {
            closePhtosView()
          }
        } label: {
          ZStack {
            cardShapeView(foreground: Color.fancyBackground,
                          cornerR: cornerR)
            Group {
              if isShowingHome {
                Text("닫 기")
              } else {
                HStack {
                  customTabItem(tab: .album, title: "나의 앨범") {
                    actionTab2()
                  }
                  customTabItem(tab: .share, title: "공유 앨범") {
                      actionTab3()
                  }
                }
              }
            }
            .transition(.scale)
          }
        }
        .disabled(!isShowingHome)
        .buttonStyle(ClickScaleEffect(scale: 0.9))
      }
      .simultaneousGesture(
        SpatialTapGesture(count: 1, coordinateSpace: .local)
          .onEnded({ translation in
            let locate = translation.location
            if !isShowingHome {
              if locate.x < (geometry.size.width/2) {
                withAnimation {
                  selectedTab = .album
                }
              } else {
                withAnimation {
                  selectedTab = .share
                }
              }
            }
          })
      )
    }
  }
  func btnPhotos(cornerR: CGFloat) -> some View {
    Button {
      if !isShowingHome {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          withAnimation(Animation.bouncy(duration: 0.2)) {
              isShowingHome = true
            } completion: {
              withAnimation(.easeInOut(duration: 0.2)) {
                animationEnded = true
              }
            }
          }
      }
    } label: {
      ZStack {
        if !isShowingHome {
          cardShapeView(foreground: .thinMaterial,
                        cornerR: cornerR)
            .matchedGeometryEffect(id: "homeBack", in: nameSpace)
            .frame(width: tabbarHeight, height: tabbarHeight)
        }
        VStack(spacing: 4) {
          Group {
            if photoData.isReadyHomeView {
              imageWithScale(systemName: iconPhotosSelected,
                             scale: .large)
                .frame(width: 80, height: 20)
            } else {
              ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .frame(width: 80, height: 20)
            }
          }
          .transition(.scale)
          Text("사진함")
            .font(.system(size: 9, weight: .semibold, design: .rounded))
        }
        .scaleEffect(isShowingHome ? 1.3 : 1)
        .foregroundColor(isShowingHome ? .white : .gray)
      }
    }
    .buttonStyle(ClickScaleEffect(scale: 0.9))
  }
  func tabbarBackground(device: UIUserInterfaceIdiom) -> some View {
    let isPad = device == .pad
    return Group {
      if #available(iOS 26, *) {
        Group {
          if isPad {
            RoundedRectangle(cornerRadius: 15)
              .foregroundStyle(Color.fancyBackground.opacity(0.5))
              .glassEffect(in: RoundedRectangle(cornerRadius: 15))
          } else {
            ContainerRelativeShape()
              .foregroundStyle(Color.fancyBackground.opacity(0.5))
              .glassEffect(in: ContainerRelativeShape())
          }
        }
      } else {
        RoundedRectangle(cornerRadius: isPad ? 10 : 0)
          .foregroundStyle(isPad ? Color.white : Color.fancyBackground)
      }
    }
  }
  func customTabItem(tab: Tabs,
                     title: String,
                     actionOnLongPress: @escaping () -> Void) -> some View {
    let selected = (selectedTab == tab && !isShowingHome)
    let icon: String = switch tab {
    case .album: selectedTab == .album ? iconAlbumSelected : iconAlbum
    case .share: selectedTab == .share ? "person.2.fill" : "person.2"
    }
    return VStack(spacing: 4) {
      imageWithScale(systemName: icon, scale: .large)
        .frame(width: 50, height: 20)
        .transition(.opacity)
      Text(title)
        .font(.system(size: 9, weight: .semibold, design: .rounded))
    }
    .scaleEffect(selected ? 1.3 : 1)
    .modify({ view in
      if device == .pad, #available(iOS 26, *) {
        view.foregroundColor(selected ? .white : .gray)
      } else if device == .phone {
        view.foregroundColor(selected ? .white : .gray)
      } else {
        view.foregroundColor(selected ? .fancyBackground : .gray)
      }
    })
    .frame(width: 80, height: tabbarHeight-10)
    .onLongPressGesture(minimumDuration: 2) {
      actionOnLongPress()
    }
  }
  func cardShapeView<S: ShapeStyle>(foreground: S, cornerR: CGFloat, autoCornerRadius: Bool = false) -> some View {
    RoundedRectangle(cornerRadius: cornerR)
      .availabeGlassEffect(
        cornerR: cornerR,
        foreground: foreground.opacity(0.85)) { view in
          view
      }
  }
}


struct CustomTabBarView_Previews: PreviewProvider {
  static var previews: some View {
    GeometryReader { geometry in
      VStack(spacing: 0, content: {
        CustomTabBarView(selectedTab: .constant(.album),
                         launchScreenManager: LaunchScreenManager(),
                         width: geometry.size.width,
                         spacing: 40,
                         isOpen: .constant(true),
                         maskingScale: .constant(4),
                         albumTabTapped: .constant(false),
                         isPhotosView: 0,
                         nameSpace: Namespace().wrappedValue,
                         actionTab1: { print("action 1") },
                         actionTab2: { print("action 2") },
                         actionTab3: { print("action 3") },
                         actionTab4: { print("action 4") },
                         isShowingHome: .constant(false),
                         animationEnded: .constant(false),
                         photosView: { EmptyView() },
                         closePhtosView: { }
        )
      })
    }
    .ignoresSafeArea(edges: .bottom)
  }
}

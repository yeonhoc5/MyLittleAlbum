//
//  RecyclePageView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/17.
//

import SwiftUI
import Photos

enum AssetHandling {
    case delete, subtract, move, hidden, none
}

struct AssetInfo {
  let mediaType: PHAssetMediaType
  let size: CGSize
}

struct RecyclePageView<Content: View>: View {
  @Environment(\.scenePhase) var scenePhase
  @Binding var isExpanded: Bool
  @Binding var indexToView: Int
  let geometry: GeometryProxy
  let count: Int
  let assetInfo: AssetInfo
  
  @State var spinIndex = 0
  @Binding var userGesture: DetailViewGesture
  @Binding var hideToolBar: Bool
  @Binding var variableScale: CGFloat
  @State var offset: CGSize = .zero
  @State var zoomOffset: CGSize = .zero
  @State var preZoomOffset: CGSize = .zero
  @State var zoomPoint: UnitPoint = .zero
  @Binding var landScapePlay: Bool
  let completion: () -> Void
  let content: (_ offsetIndex: Int, _ pageIndex: Int) -> Content
  
  @State var correctoffset: CGSize = .zero
  
  init(isExpanded: Binding<Bool>,
       indexToView: Binding<Int>,
       geometry: GeometryProxy,
       count: Int,
       assetInfo: AssetInfo,
       userGesture: Binding<DetailViewGesture>,
       hideToolBar: Binding<Bool>,
       scale: Binding<CGFloat>,
       landscapePlay: Binding<Bool>,
       completion: @escaping () -> Void,
       @ViewBuilder content: @escaping (
        _ page: Int, _ pageNum: Int) -> Content) {
          self._isExpanded = isExpanded
          self._indexToView = indexToView
          self.geometry = geometry
          self.count = count
          self.assetInfo = assetInfo
          self.content = content
          self._userGesture = userGesture
          self._hideToolBar = hideToolBar
          self._variableScale = scale
          self._landScapePlay = landscapePlay
          self.completion = completion
  }
  
  var body: some View {
    let opacity = 1 - (Double(abs(offset.height)
                        / (geometry.size.height / 3)))
    ZStack {
      backgroundBlackView(isEmpty: count == 0,
                          color: .black,
                          opacity: opacity)
        .zIndex(0.4)
      ForEach(-2..<3, id: \.self) { int in
        let page = spinIndex - int
        let offsetIndex = calcOffsetIndex(page)
        let pageIndex = offsetIndex + indexToView
        contentFrame(offsetIndex: offsetIndex,
                     pageIndex: pageIndex,
                     color: colorSet[int + 2],
                     opacity: opacity)
          .zIndex(calczIndex(offsetIndex))
          .simultaneousGesture(
            detailViewGesture(pageIndex: pageIndex,
                              offsetIndex: offsetIndex,
                              geometry: geometry)
            .exclusively(before: zoomGestureByDoubleTap(
                                currentSize: assetInfo.size,
                                geometry: geometry))
            .exclusively(before: hideGesture(geometry: geometry))
          )
      }
      .onChange(of: self.count, perform: { [oldValue = self.count] newValue in
        changeOffsetAtRemove(old: oldValue, new: newValue)
      })
    }
  }
}

extension RecyclePageView {
  func zoomGestureByDoubleTap(currentSize: CGSize,
                              geometry: GeometryProxy) -> some Gesture {
    let screenSize = geometry.size
    return SpatialTapGesture(count: 2, coordinateSpace: .local)
      .onEnded { value in
        if variableScale == 1.0 {
          let width = screenSize.width
          let multiple = (screenSize.height * CGFloat(currentSize.width))
                        / (width * CGFloat(currentSize.height))
          let rightEdge = (width - value.location.x) * multiple
          let leftEdge = value.location.x * multiple
          
          let zoomPointX = rightEdge < (width/2)
          ? 1 : ((leftEdge < width/2)
                 ? 0 : (value.location.x / width))
          self.zoomPoint = UnitPoint(x: zoomPointX, y: 0.5)
          withAnimation {
            hideToolBar = true
            variableScale = multiple == 1 ? 2 : multiple
          }
        } else {
          withAnimation {
            hideToolBar = false
            variableScale = 1.0
            zoomOffset = .zero
          }
        }
      }
  }
  // navigationtitle & customPlayBack hidden 토글
  private func hideGesture(geometry: GeometryProxy) -> some Gesture {
    SpatialTapGesture(count: 1, coordinateSpace: .global)
      .onEnded { tap in
        guard userGesture == .none else { return }
        let zeroSpace = hideToolBar || assetInfo.mediaType == .video
        if tap.location.y < geometry.size.height - (tabbarHeight * (zeroSpace ? 0 : 1)) - tabbarBottomPadding - 20 {
          withAnimation {
            self.hideToolBar.toggle()
          }
        }
      }
      .exclusively(before: TapGesture(count: 2))
  }
  private func changeOffsetAtRemove(old: Int, new: Int) {
    if new > 0 && new < old {
      if indexToView > 0 {
        withAnimation {
          if indexToView > new-2 {
            self.indexToView -= 1
          }
        }
      }
    }
  }
  @ViewBuilder
  func backgroundBlackView(isEmpty: Bool, color: Color, opacity: Double) -> some View {
    color
      .ignoresSafeArea()
      .overlay(content: {
        if isEmpty && userGesture != .dismissingView {
          Text("No Media Here")
            .foregroundStyle(.gray)
            .onAppear {
              self.isExpanded = false
              completion()
            }
        } else {
          EmptyView()
        }
      })
      .opacity(opacity)
  }
    
  func contentFrame(offsetIndex: Int,
                    pageIndex: Int,
                    color: Color,
                    opacity: CGFloat) -> some View {
    let frame = geometry.frame(in: .global)
    let size = geometry.size
    let zeroIndex = offsetIndex == 0
    return ZStack {
      Color.black // 사진 밖에서도 gestrue 적용
      content(offsetIndex, pageIndex)
        .onGeometryChange(for: CGRect.self) { geo in
          return geo.frame(in: .global)
        } action: { newValue in
          if offsetIndex == 0 {
            if newValue.origin.x > 0 {
              self.correctoffset.width = -newValue.origin.x
            } else if newValue.maxX < size.width {
              self.correctoffset.width = (size.width - newValue.maxX)
            }
            if newValue.origin.y > 0 {
              self.correctoffset.height = -newValue.origin.y
            } else if newValue.maxY < size.height {
              self.correctoffset.height = (size.height - newValue.maxY)
            }
          }
        }
        .onChange(of: userGesture, perform: { [old = userGesture] new in
          if old == .magnifying && new == .none {
            withAnimation {
              self.zoomOffset.width += self.correctoffset.width
              self.zoomOffset.height += self.correctoffset.height
            }
            self.correctoffset = .zero
          }
        })
        .position(x: frame.midX, y: frame.midY)
        .offset(
          x: zeroIndex
          ? (variableScale == 1.0
             ? (landScapePlay
                ? ((zoomOffset.width + preZoomOffset.width) / variableScale)
                : .zero)
             : (zoomOffset.width + preZoomOffset.width)
                / variableScale)
          : .zero)
        .offset(y: zeroIndex && variableScale == 1.0
                ? .zero
                : (zoomOffset.height + preZoomOffset.height) / variableScale)
    }
    .scaleEffect(zeroIndex ? variableScale : 1, anchor: zoomPoint)
    .offset(x: CGFloat(offsetIndex) * (size.width + 20)
            + (userGesture == .paging ? offset.width : 0))
    .offset((userGesture == .dismissingView && zeroIndex)
            ? offset : .zero)
    .onChange(of: scenePhase, perform: { newValue in
      if newValue != .active {
        withAnimation { offset = .zero }
      }
    })
    .onChange(of: variableScale) { newValue in
      if newValue == 1 {
        withAnimation { offset = .zero }
      }
    }
  }
  func realoffset(int: Int) -> Int {
    return (int % 5) + 2
  }
  private func calcOffsetIndex(_ current: Int) -> Int {
    if current > 0 {
      let checkNum = current % 5
      return checkNum >= 3 ? checkNum - 5 : checkNum
    } else {
      let checkNum = (current * -1) % 5
      return checkNum >= 3 ? -checkNum + 5 : -checkNum
    }
  }
  
  private func calcPageIndex(_ index: Int, _ indexToView: Int) -> Int {
    return calcOffsetIndex(index) + indexToView
  }
  
  private func calczIndex(_ offsetIndex: Int) -> CGFloat {
    return offsetIndex == 0 ? 1 : (abs(offsetIndex) == 1 ? 0.5 : 0.3)
  }
}

// extension Gestures
extension RecyclePageView {
  // 디테일뷰 dismissing 제스쳐
  private func detailViewGesture(
                pageIndex: Int,
                offsetIndex: Int,
                geometry: GeometryProxy) -> some Gesture {
    DragGesture(minimumDistance: 10)
      .onChanged { value in
        if variableScale == 1 && !landScapePlay {
          guard value.location.y > 50,
                value.location.y < geometry.size.height - 50
          else { return }
          if userGesture == .none {
            self.userGesture = (abs(value.translation.width)
                                > abs(value.translation.height))
            ? .paging : .dismissingView
          } else {
            if userGesture == .paging {
              self.offset = CGSize(width: value.translation.width, height: 0)
            } else if userGesture == .dismissingView
                        || userGesture == .magnifying {
              offset = value.translation
            }
          }
        } else {
          userGesture = .magnifying
          self.preZoomOffset = value.translation
        }
      }
      .onEnded { value in
        if userGesture == .dismissingView {
          if max(abs(value.translation.height),
                 abs(value.predictedEndTranslation.height))
              > 150 {
            withAnimation {
              offset.height = value.predictedEndTranslation.height
              self.isExpanded = false
              completion()
            }
          } else {
            withAnimation {
              offset = .zero
              userGesture = .none
            }
          }
        } else if userGesture == .paging {
          if (indexToView > 0)
              && max(value.predictedEndTranslation.width,
                     value.translation.width)
                  > (geometry.size.width / 4) {
            withAnimation(.easeOut(duration: 0.25)) {
              self.indexToView -= 1
              self.spinIndex += 1
              offset = .zero
              userGesture = .none
            }
          } else if (pageIndex < count-1)
              && min(value.predictedEndTranslation.width,
                     value.translation.width)
                   < -(geometry.size.width / 4) {
            withAnimation(.easeOut(duration: 0.25)) {
              self.indexToView += 1
              self.spinIndex -= 1
              offset = .zero
              userGesture = .none
            }
          } else {
            // 첫 & 마지막 페이지
            withAnimation(.easeOut(duration: 0.25)) {
              offset = .zero
              userGesture = .none
            }
          }
        } else {
          if variableScale == 1 {
            if abs(value.translation.width) > 100 {
              dispatchAnimation {
                landScapePlay = false
                preZoomOffset = .zero
              }
            } else {
              dispatchAnimation {
                preZoomOffset = .zero
              }
            }
          } else {
            withAnimation {
              zoomOffset = CGSize(
                width: zoomOffset.width + preZoomOffset.width,
                height: zoomOffset.height + preZoomOffset.height)
              preZoomOffset = .zero
            }
          }
          userGesture = .none
        }
      }
  }
}

//struct RecyclePageView_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotosDetailView(indexToView: .constant(0), 
//                         isExpanded: .constant(false),
//                         navigationTitle: "sample")
//    }
//}

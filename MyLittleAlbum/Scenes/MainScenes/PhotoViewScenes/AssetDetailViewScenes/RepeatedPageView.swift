//
//  RepeatedPageView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/17.
//

import SwiftUI

struct RepeatedPageView<Content: View>: View {
    let content: (_ offsetIndex: Int, _ pageIndex: Int) -> Content
    let count: Int
    var indexToView: Int
    @State var offsetIndex = 0
    @Binding var isExpanded: Bool
    
    @Binding var isUserSwiping: Bool
    @Binding var pagingGesture: Bool
    @Binding var toDismiss: Bool
    var variableScale: CGFloat
    var isSeeking: Bool
    
    @Binding var offsetX: CGFloat
    @State var offsetY: CGFloat = .zero
    @Environment(\.scenePhase) var scenePhase
    
    init(count: Int, indexToView: Int, isExpanded: Binding<Bool>, isUserSwiping: Binding<Bool>,
         pagingGesture: Binding<Bool>, toDismiss: Binding<Bool>, scale: CGFloat, isSeeking: Bool, offsetX: Binding<CGFloat>, @ViewBuilder content: @escaping (_ page: Int, _ pageNum: Int) -> Content) {
        self.count = count
        self.indexToView = indexToView
        self.content = content
        self._isExpanded = isExpanded
        self._isUserSwiping = isUserSwiping
        self._pagingGesture = pagingGesture
        self._toDismiss = toDismiss
        self.variableScale = scale
        self.isSeeking = isSeeking
        self._offsetX = offsetX
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .zIndex(0.49)
            ForEach(-2..<3) { int in
                contentFrame(offsetIndex: calcOffsetIndex(offsetIndex - int),
                             pageIndex: calcPageIndex(offsetIndex - int, indexToView),
                             color: colorSet[int + 2])
                .zIndex(calczIndex(calcOffsetIndex(offsetIndex - int)))
            }
        }
    }
    
}

extension RepeatedPageView {
    
    func contentFrame(offsetIndex: Int, pageIndex: Int, color: Color) -> some View {
        GeometryReader { geometry in
            content(offsetIndex, pageIndex)
                .frame(width: geometry.size.width, 
                       height: geometry.size.height)
                .background(content: {
//                    color
                    Color.black
                        .ignoresSafeArea()
                })
                .offset(x: self.isUserSwiping ?
                        CGFloat(offsetIndex) * (geometry.size.width + 20) + self.offsetX
                        : CGFloat(offsetIndex) * (geometry.size.width + 20))
                .offset(y: offsetY)
                .onChange(of: scenePhase, perform: { newValue in
                    if newValue != .active {
//                    if newValue != 0 && isExpanded && !toDismiss {
                        withAnimation {
                            offsetY = 0
                        }
                    }
                })
                .simultaneousGesture(pagingGesture(geometry: geometry, pageIndex: pageIndex))
                .simultaneousGesture(dismissingGesture)
        }
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
        return offsetIndex == 0 ? 1 : (abs(offsetIndex) == 1 ? 0.5 : 0)
    }
}

// extension Gestures
extension RepeatedPageView {
    // 페이징 제스쳐
    private func pagingGesture(geometry: GeometryProxy, pageIndex: Int) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if variableScale == 1 && !isSeeking {
                    isUserSwiping = true
                    if !toDismiss && abs(value.translation.width) > abs(value.translation.height) {
                        self.pagingGesture = true
                        self.offsetX = value.translation.width
                    } else {
                        offsetX = 0
                    }
                }
            }
            .onEnded { value in
                if !isSeeking {
                    if pagingGesture {
                        if (1..<count).contains(pageIndex)
                            && max(value.predictedEndTranslation.width, value.translation.width)
                            > 150 {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    self.offsetIndex += 1
                                    self.isUserSwiping = false
                                }
                        } else if (0..<count - 1).contains(pageIndex)
                                    && min(value.predictedEndTranslation.width, value.translation.width)
                                    < -150 {
                            withAnimation(.easeOut(duration: 0.25)) {
                                self.offsetIndex -= 1
                                self.isUserSwiping = false
                            }
                        } else {
                            withAnimation { self.offsetX = 0 }
                            self.isUserSwiping = false
                        }
                    } else {
                        withAnimation { self.offsetX = 0 }
                        self.isUserSwiping = false
                    }
                }
                self.pagingGesture = false
            }
    }
    // 디테일뷰 dismissing 제스쳐
    private var dismissingGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if variableScale == 1 && !isSeeking {
                    isUserSwiping = true
                    if !pagingGesture && abs(value.translation.width) <= abs(value.translation.height) {
                        toDismiss = true
                        offsetY = value.translation.height
                    } else {
                        offsetY = 0
                    }
                }
            }
            .onEnded { value in
                if toDismiss {
                    if max(abs(value.translation.height), abs(value.predictedEndTranslation.height)) > 100 {
                        withAnimation {
                            offsetY = value.predictedEndTranslation.height
                            self.isUserSwiping = false
                        }
                        self.isExpanded = false
                    } else {
                        withAnimation {
                            offsetY = 0
                            self.isUserSwiping = false
                        }
                    }
                    self.toDismiss = false
                } else {
                    withAnimation {
                        self.offsetY = 0
                    }
                }
            }
    }
}

struct RepeatedPageView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosDetailView(indexToView: .constant(0), 
                         isExpanded: .constant(false),
                         navigationTitle: "sample")
    }
}

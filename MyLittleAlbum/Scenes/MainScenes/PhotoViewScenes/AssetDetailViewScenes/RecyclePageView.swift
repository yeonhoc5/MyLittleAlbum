//
//  RecyclePageView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/17.
//

import SwiftUI

enum AssetHandling {
    case delete, subtract, move, hidden, none
}

struct RecyclePageView<Content: View>: View {
    let content: (_ offsetIndex: Int, _ pageIndex: Int, _ size: CGSize) -> Content
    let count: Int
    @Binding var indexToView: Int
    @State var offsetIndex = 0
    @Binding var isExpanded: Bool
    
    @Binding var userGesture: DetailViewGesture
    @Binding var hideToolBar: Bool
    var variableScale: CGFloat
    
    @Binding var offsetX: CGFloat
    @State var offsetY: CGFloat = .zero
    @Environment(\.scenePhase) var scenePhase
    
    init(count: Int, indexToView: Binding<Int>,
         isExpanded: Binding<Bool>,
         userGesture: Binding<DetailViewGesture>,
         hideToolBar: Binding<Bool>,
         scale: CGFloat,
         offsetX: Binding<CGFloat>,
         @ViewBuilder content: @escaping (_ page: Int, _ pageNum: Int, _ size: CGSize) -> Content) {
        self.count = count
        self._indexToView = indexToView
        self.content = content
        self._isExpanded = isExpanded
        self._userGesture = userGesture
        self._hideToolBar = hideToolBar
        self.variableScale = scale
        self._offsetX = offsetX
    }
    
    var body: some View {
        ZStack {
            backgroundBlackView(count: count)
                .zIndex(0.49)
            ForEach(-2..<3, id: \.self) { int in
                contentFrame(offsetIndex: calcOffsetIndex(offsetIndex - int),
                             pageIndex: calcPageIndex(offsetIndex - int, indexToView),
                             color: colorSet[int + 2])
                .zIndex(calczIndex(calcOffsetIndex(offsetIndex - int)))
            }
            .onChange(of: self.count, perform: { newValue in
                if newValue > 0 {
                    if indexToView > 0 {
                        withAnimation {
                            self.indexToView -= 1
                            self.offsetIndex += 1
                        }
                    }
                }
            })
        }
        .simultaneousGesture(dismissingGesture)
    }
    
}

extension RecyclePageView {
    private var hideGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                if userGesture == .none {
                    withAnimation(.easeOut(duration: 0.1)) {
                        self.hideToolBar.toggle()
                    }
                }
            }
    }
    @ViewBuilder
    func backgroundBlackView(count: Int) -> some View {
        Color.black
            .ignoresSafeArea()
            .overlay(content: {
                if count == 0 && userGesture != .dismissingView {
                    Text("No Media Here")
                        .foregroundStyle(.gray)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation {
                                    isExpanded = false
                                }
                            }
                        }
                } else {
                    EmptyView()
                }
            })
    }
    
    func contentFrame(offsetIndex: Int, pageIndex: Int, color: Color) -> some View {
        GeometryReader { geometry in
            content(offsetIndex, pageIndex, geometry.size)
                .frame(width: geometry.size.width,
                       height: geometry.size.height)
                .contentTransition(.identity)
                .background(content: {
//                    color // test(화면 구분)용으로 남겨둠
                    Color.black
                        .opacity(Double(100.0 - Double(offsetY)) / 100.0)
                        .ignoresSafeArea()
                })
                .offset(x: self.userGesture == .paging ?
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
//                .gesture(hideGesture)
                .simultaneousGesture(
                    pagingGesture(geometry: geometry, pageIndex: pageIndex)
                        .exclusively(before: hideGesture)
                )
            
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
extension RecyclePageView {
    // 페이징 제스쳐
    private func pagingGesture(geometry: GeometryProxy,
                               pageIndex: Int) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if variableScale == 1 && (userGesture == .none || userGesture == .paging) {
                    if abs(value.translation.width) > abs(value.translation.height) {
                        self.userGesture = .paging
                        self.offsetX = value.translation.width
                    } else {
                        offsetX = 0
                    }
                }
            }
            .onEnded { value in
                if userGesture == .paging {
                    if (1..<count).contains(pageIndex)
                        && max(value.predictedEndTranslation.width,
                               value.translation.width)
                        > 150 {
                        withAnimation(.easeOut(duration: 0.25)) {
                            self.offsetIndex += 1
                            userGesture = .none
                        }
                    } else if (0..<count - 1).contains(pageIndex)
                                && min(value.predictedEndTranslation.width,
                                       value.translation.width)
                                < -150 {
                        withAnimation(.easeOut(duration: 0.25)) {
                            self.offsetIndex -= 1
                            userGesture = .none
                        }
                    } else {
                        withAnimation { self.offsetX = 0 }
                        userGesture = .none
                    }
                } else {
                    withAnimation { self.offsetX = 0 }
                    userGesture = .none
                }
            }
    }
    // 디테일뷰 dismissing 제스쳐
    private var dismissingGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if variableScale == 1
                    && (userGesture == .none || userGesture == .dismissingView) {
                        if abs(value.translation.width) <= abs(value.translation.height) {
                            userGesture = .dismissingView
                            offsetY = value.translation.height
                        } else {
                            offsetY = 0
                        }
                }
            }
            .onEnded { value in
                if userGesture == .dismissingView {
                    if max(abs(value.translation.height), abs(value.predictedEndTranslation.height)) > 100 {
                        withAnimation {
                            offsetY = value.predictedEndTranslation.height
                        }
                        userGesture = .none
                        self.isExpanded = false
                    } else {
                        withAnimation {
                            offsetY = 0
                        }
                        userGesture = .none
                    }
//                    self.toDismiss = false
                } else {
                    withAnimation {
                        self.offsetY = 0
                    }
                    if userGesture == .dismissingView {
                        userGesture = .none
                    }
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

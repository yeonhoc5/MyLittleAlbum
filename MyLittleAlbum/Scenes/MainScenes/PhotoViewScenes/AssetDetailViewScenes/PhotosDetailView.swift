//
//  PhotosDetailView.swift
//  PhotosDetailView
//
//  Created by yeonhoc5 on 2023/02/21.
//

import SwiftUI
import Photos
import AVKit

// MARK: - 1. BODY
struct PhotosDetailView: View {
    var assetArray = [PHAsset]()
    @Binding var indexToView: Int
    @Binding var isExpanded: Bool
    @State var navigationTitle: String
    @Namespace var animationID
    
    // 페이지
    @State var hideToolbar: Bool = false
    @State var isUserSwiping: Bool = false
    @State var pagingGesture: Bool = false
    @State var toDismiss: Bool = false
    // 이미지/비디오 공통
    @State var offsetY: CGFloat = 0
    @State var offsetX: CGFloat = .zero
    // 이미지
    @State var variableScale: CGFloat = 1
    @State var currentScale: CGFloat = 1
    // 비디오
    @State var isSeeking: Bool = false
    
    var body: some View {
        let count = assetArray.count
        NavigationStack {
            RepeatedPageView(count: count,
                             indexToView: indexToView,
                             isExpanded: $isExpanded,
                             isUserSwiping: $isUserSwiping,
                             pagingGesture: $pagingGesture,
                             toDismiss: $toDismiss,
                             scale: variableScale,
                             isSeeking: isSeeking,
                             offsetX: $offsetX) { offsetIndex, pageIndex in
                if (0..<count).contains(pageIndex) {
                    let asset = assetArray[pageIndex]
                    detailView(currentAsset: asset, offsetIndex: offsetIndex, animationID: animationID)
                        .id(asset.localIdentifier)
                        .onAppear(perform: {
                            navigationTitle = timeFormmatter(asset: assetArray[indexToView])
                        })
                        .offset(x: 0, y: offsetY)
                        .onChange(of: offsetIndex) { newValue in
                            changeNavigationTitle(newValue, pageIndex: pageIndex)
                        }
                        .onChange(of: indexToView) { newValue in
                            if newValue-2 >= 0 {
                                if assetArray[newValue-2].mediaType == .image {
                                    DispatchQueue.main.async {
                                        cachingImageInAdvance(asset: assetArray[newValue-2])
                                    }
                                }
                            }
                            if newValue+2 < assetArray.count {
                                if assetArray[newValue+2].mediaType == .image {
                                    DispatchQueue.main.async {
                                        cachingImageInAdvance(asset: assetArray[newValue+2])
                                    }
                                }
                            }
                        }
                }
            }
            .ignoresSafeArea()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(hideToolbar ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { closeButton }
                ToolbarItem(placement: .navigationBarTrailing) { assetCountLabel }
            }
            .onDisappear {
                DispatchQueue.main.async {
                    let cacheManger = PHCachingImageManager()
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .opportunistic
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    let width = screenSize.width * scale
                    let size = CGSize(width: width, height: .infinity)
                    cacheManger.stopCachingImages(for: assetArray,
                                                  targetSize: size,
                                                  contentMode: .aspectFit,
                                                  options: options)
                }
            }
        }
        .ignoresSafeArea()
    }
}


struct detailPageView<Content: View>: View {
    @Binding var indexToView: Int
    let countSum: Int
    let content: (_ pageIndex: Int) -> Content
    @Binding var isExpanded: Bool
    
    init(indexToView: Binding<Int>, countSum: Int, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping (_ pageIndex: Int) -> Content) {
        self._indexToView = indexToView
        self.countSum = countSum
        self.content = content
        self._isExpanded = isExpanded
    }
    
    var body: some View {
        TabView(selection: $indexToView) {
            ForEach(0..<countSum, id: \.self) { pageIndex in
                if (indexToView-1...indexToView+1).contains(pageIndex) {
                    GeometryReader { proxy in
                        ZStack {
                            Color.black
                                .ignoresSafeArea()
                            content(pageIndex)
                        }
                        .onTapGesture {
                            isExpanded = false
                        }
                        .opacity((indexToView-1...indexToView+1).contains(pageIndex) ? 1 : 0)
                    }
                } else {
                    Color.clear
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
    
}

// MARK: - 2. extension [Subviews]
extension PhotosDetailView {
    // detail View 닫기 버튼
    var closeButton: some View {
        Button {
            withAnimation {
                isExpanded = false
            }
        } label: {
            Image(systemName: "xmark")
                .imageScale(.medium)
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .frame(width: 50, height: 40, alignment: .center)
        }
    }
    
    var assetCountLabel: some View {
        Text("(\(indexToView + 1) / \(assetArray.count))")
            .font(.footnote)
            .foregroundColor(.gray)
            .padding(.top, 5)
    }
    
    @ViewBuilder
    func detailView(currentAsset: PHAsset, offsetIndex: Int, animationID: Namespace.ID) -> some View {
        if currentAsset.mediaType == .image {
            ImageDetailView(asset: currentAsset,
                            variableScale: $variableScale,
                            currentScale: $currentScale,
                            offsetY: $offsetY)
            .id(currentAsset.localIdentifier)
            .scaleEffect(variableScale)
            .simultaneousGesture(hideGesture)
            .simultaneousGesture(zoomGestureByPinch)
            
        } else if currentAsset.mediaType == .video {
            VideoDetailView(offsetIndex: offsetIndex,
                            asset: currentAsset,
                            hidden: $hideToolbar,
                            isSeeking: $isSeeking,
                            offsetY: $offsetY,
                            offsetX: $offsetX)
            .id(currentAsset.localIdentifier)
        }
    }
    
}

// MARK: - 3. extension [Funcitons]
extension PhotosDetailView {
    func changeNavigationTitle(_ newValue: Int, pageIndex: Int) {
        if newValue == 0 {
            indexToView = pageIndex
            navigationTitle = timeFormmatter(asset: assetArray[indexToView])
        }
    }
    
    func cachingImageInAdvance(asset: PHAsset) {
        let imageManager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        let width = screenSize.width * scale
        let size = CGSize(width: width, height: .infinity)
        imageManager.startCachingImages(for: [asset],
                                        targetSize: size,
                                        contentMode: .aspectFit,
                                        options: options)
    }
    
    func timeFormmatter(asset: PHAsset) -> String {
        let fommatter = DateFormatter()
        fommatter.locale = Locale(identifier: "ko_KR")
        fommatter.dateFormat = "yy년 MM월 dd일"
        let date = fommatter.string(from: asset.creationDate ?? Date())
        return date
    }
}
// MARK: - 4. extenstion [Gestures]
extension PhotosDetailView {
    // navigationtitle & customPlayBack hidden 토글
    private var hideGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    self.hideToolbar.toggle()
                }
            }
    }
    
    var zoomGestureByPinch: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if !isUserSwiping {
                    self.variableScale = currentScale * value.magnitude
                }
            }
            .onEnded { value in
                if !isUserSwiping && !toDismiss {
                    if self.variableScale >= 1 && self.variableScale <= 2 {
                        self.variableScale = currentScale * value.magnitude
                    } else  if variableScale > 2 {
                        withAnimation { self.variableScale = 2 }
                    } else {
                        withAnimation { self.variableScale = 1 }
                    }
                    currentScale = self.variableScale
                }
            }
    }
    
}


struct PhotosDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosDetailView(indexToView: .constant(0),
                         isExpanded: .constant(true),
                         navigationTitle: "photos")
            .preferredColorScheme(.dark)
    }
}

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

    @State var hidden: Bool = false
    
    @State var isSeeking: Bool = false
    @State var isUserSwiping: Bool = false
    @State var pagingGesture: Bool = false
    @State var toDismiss: Bool = false
    
    @State var offsetY: CGFloat = 0
    @State var offsetX: CGFloat = .zero
    
    @State var variableScale: CGFloat = 1
    @State var currentScale: CGFloat = 1
    @State var currentTime: Double = 0
    
    
//    var body: some View {
//        TabView(selection: $indexToView) {
//            ForEach(0..<assetArray.count, id: \.self) { index in
//                switch index {
//                case indexToView-3...indexToView+3:
//                    ZStack {
//                        Color.black
//                        ImageDetailView(isExpanded: $isExpanded,
//                                        asset: assetArray[index],
//                                        navigationTitle: navigationTitle,
//                                        variableScale: $variableScale,
//                                        currentScale: $currentScale,
//                                        offsetY: $offsetY)
//                            .tag(index)
////                            .matchedGeometryEffect(id: assetArray[index], in: animationID)
//                            .id(assetArray[index].localIdentifier)
//                            .scaleEffect(variableScale)
////                            .simultaneousGesture(hideGesture)
////                            .simultaneousGesture(zoomGestureByPinch)
//                            .onTapGesture {
//                                isExpanded = false
//                            }
//                    }
//                default:
//                    Color.clear
//                        .tag(index)
//                        .onTapGesture {
//                            isExpanded = false
//                        }
//                }
////                if (indexToView-1...indexToView+1).contains(assetArray.firstIndex(of: asset as! PHAsset)!) {
////                    Color.yellow
////                        .onTapGesture {
////                            isExpanded = false
////                        }
////                } else {
//
////                }
//            }
//        }
//        .tabViewStyle(.page(indexDisplayMode: .always))
//    }
    
    
    var body: some View {
        let count = assetArray.count
        NavigationStack {
            ZStack(alignment: .topLeading) {
                RepeatedPageView(count: count,
                                 indexToView: indexToView,
                                 isExpanded: $isExpanded,
                                 isUserSwiping: $isUserSwiping,
                                 pagingGesture: $pagingGesture,
                                 toDismiss: $toDismiss,
                                 scale: variableScale,
                                 isSeeking: isSeeking,
                                 offsetX: $offsetX) { offsetIndex, pageIndex in
                    if (indexToView - 1...indexToView + 1).contains(pageIndex) {
                        let asset = assetArray[pageIndex]
                        detailView(currentAsset: asset,
                                   offsetIndex: offsetIndex,
                                   animationID: animationID)
                        .id(asset.localIdentifier)
                        .onAppear(perform: {
                            navigationTitle = timeFormmatter(asset: assetArray[indexToView])
                        })
                        .offset(x: 0, y: offsetY)
                        .onChange(of: offsetIndex) { newValue in
                            changeNavigationTitle(newValue, pageIndex: pageIndex)
                            if (newValue == indexToView - 2 && indexToView - 2 >= 0) {
                                let imageManager = PHCachingImageManager()
                                let options = PHImageRequestOptions()
                                options.deliveryMode = .opportunistic
                                options.isSynchronous = true
                                options.isNetworkAccessAllowed = true
                                let width = screenSize.width * scale
                                let size = CGSize(width: width, height: .infinity)
                                imageManager.startCachingImages(for: [assetArray[indexToView - 2]],
                                                                targetSize: size,
                                                                contentMode: .aspectFit,
                                                                options: options)
                            } else if (newValue == indexToView + 2 && indexToView + 2 < assetArray.count) {
                                let imageManager = PHCachingImageManager()
                                let options = PHImageRequestOptions()
                                options.deliveryMode = .opportunistic
                                options.isSynchronous = true
                                options.isNetworkAccessAllowed = true
                                let width = screenSize.width * scale
                                let size = CGSize(width: width, height: .infinity)
                                imageManager.startCachingImages(for: [assetArray[indexToView + 2]],
                                                                targetSize: size,
                                                                contentMode: .aspectFit,
                                                                options: options)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(hidden ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { closeButton }
                ToolbarItem(placement: .navigationBarTrailing) { assetCountLabel }
            }
            .onDisappear {
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
        .ignoresSafeArea()
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
            ImageDetailView(isExpanded: $isExpanded,
                            asset: currentAsset,
                            navigationTitle: navigationTitle,
                            variableScale: $variableScale,
                            currentScale: $currentScale,
                            offsetY: $offsetY)
            .id(currentAsset.localIdentifier)
            .scaleEffect(variableScale)
            .simultaneousGesture(hideGesture)
            .simultaneousGesture(zoomGestureByPinch)
            
        } else if currentAsset.mediaType == .video {
            VideoDetailView(isExpanded: $isExpanded,
                            offsetIndex: offsetIndex,
                            asset: currentAsset,
                            navigationTitle: navigationTitle,
                            offsetY: $offsetY,
                            hidden: $hidden,
                            isSeeking: $isSeeking,
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
    
    func timeFormmatter(asset: PHAsset) -> String {
        let fommatter = DateFormatter()
        fommatter.locale = Locale(identifier: "KO-kr")
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
                    self.hidden.toggle()
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
        PhotosDetailView(indexToView: .constant(0), isExpanded: .constant(true), navigationTitle: "photos")
    }
}

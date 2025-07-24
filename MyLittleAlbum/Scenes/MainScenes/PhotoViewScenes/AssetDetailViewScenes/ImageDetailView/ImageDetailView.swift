//
//  ImageDetailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/31.
//

import SwiftUI
import Photos
import Zoomable

struct ImageDetailView: View {
    @Environment(\.scenePhase) var scenePhase
    
    let asset: MLAsset
    let imageManager: PHCachingImageManager
    let size: CGSize
    let enableZoom: Bool
    
    @Binding var variableScale: CGFloat
    @Binding var currentScale: CGFloat
    @State var fetchedImage: UIImage!
    @Binding var offsetY: CGFloat
    @State var widthIsCreteria: Bool = false
    
    var body: some View {
        if fetchedImage == nil {
            loadingView
        } else {
//            GeometryReader { goeproxy in
//                HStack {
//                    Spacer(minLength: 0)
//                    VStack {
//                        Spacer(minLength: 0)
                        Image(uiImage: (fetchedImage))
                            .resizable()
                            .scaledToFit()
                            .modify({ view in
                                if enableZoom {
                                    view
                                        .zoomable(minZoomScale: 1.0,
                                                  doubleTapZoomScale: 3.0,
                                                  outOfBoundsColor: .clear)
                                } else {
                                    view
                                }
                            })
//                        Spacer(minLength: 0)
//                    }
//                    Spacer(minLength: 0)
//                }
//            }
        }
    }
}

extension ImageDetailView {
    var loadingView: some View {
        ProgressView()
            .tint(.white)
            .controlSize(.large)
            .progressViewStyle(.circular)
            .scaleEffect(0.8)
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation {
                        fetchedImage = fetchingImage(asset: asset.phAsset)
                    }
                }
            }
    }
    var zoomGestureByTab: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                withAnimation {
                    if variableScale != 1 {
                        variableScale = 1
                        currentScale = 1
                    } else {
                        variableScale = 1.5
                        currentScale = 1.5
                    }
                }
            }
    }
}

//
extension ImageDetailView {
    func fetchingImage(asset: PHAsset) -> UIImage {
        let assetRatio = CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
        let screenRatio = screenSize.height / screenSize.width
        widthIsCreteria = assetRatio <= screenRatio
        var returnImage: UIImage!
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        let creteriaSize = (widthIsCreteria
                     ? screenSize.width
                     : screenSize.height) * scale
        let size = CGSize(width: widthIsCreteria ? creteriaSize : .infinity,
                          height: widthIsCreteria ? .infinity : creteriaSize)
        
        imageManager.requestImage(for: asset,
                                  targetSize: size,
                                  contentMode: .aspectFit,
                                  options: options) { assetImage, _ in
            if let image = assetImage {
                returnImage = image
            }
        }
        return returnImage
    }
    
}


struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PhotoData())
    }
}

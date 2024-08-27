//
//  ImageDetailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/31.
//

import SwiftUI
import Photos

struct ImageDetailView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @Binding var isExpanded: Bool
    let asset: PHAsset
    let imageManager = PHCachingImageManager()
    @Binding var variableScale: CGFloat
    @Binding var currentScale: CGFloat
    @State var fetchtedImage: UIImage!
    @Binding var offsetY: CGFloat
    @State var widthIsCreteria: Bool = false
    
    var body: some View {
        if fetchtedImage == nil {
            ProgressView()
                .tint(.color1)
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .onAppear {
                    DispatchQueue.main.async {
                        withAnimation {
                            fetchtedImage = fetchingImage(asset: asset)
                        }
                    }
                }
        } else {
            GeometryReader { proxy in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: (fetchtedImage))
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * variableScale,
                               height: proxy.size.height * variableScale)
                        .simultaneousGesture(zoomGestureByTab)
                }
                .scrollDisabled(variableScale == 1)
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

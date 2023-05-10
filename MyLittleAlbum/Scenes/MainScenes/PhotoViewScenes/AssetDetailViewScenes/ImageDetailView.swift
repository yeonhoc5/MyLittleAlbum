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
//    let navigationTitle: String
    let imageManager = PHCachingImageManager()
    @Binding var variableScale: CGFloat
    @Binding var currentScale: CGFloat
    @State var fetchtedImage: UIImage!
    @Binding var offsetY: CGFloat
    
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
                        .frame(width: proxy.size.width * variableScale)
                        .simultaneousGesture(zoomGestureByTab)
                }
                .scrollDisabled(variableScale == 1)
            }
        }
    }
    
    
//    var titleView: some View {
//        HStack(alignment: .center) {
//            Button {
//                withAnimation {
//                    isExpanded = false
//                }
//            } label: {
//                Image(systemName: "xmark")
//                    .imageScale(.large)
//                    .foregroundColor(.white)
//                    .bold()
//                    .frame(width: 50, height: 40, alignment: .center)
//            }
//            Text(navigationTitle)
//                .foregroundColor(.white)
//                .font(Font.system(size: 17, weight: .bold))
//                .frame(width: screenSize.width - 100, height: 40, alignment: .center)
//            Spacer(minLength: 50)
//        }
//        .frame(width: screenSize.width, height: 85, alignment: .bottom)
//    }
    
    
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
        var returnImage: UIImage!
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        let width = screenSize.width * scale
        let size = CGSize(width: width, height: .infinity)
        
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
        TabBarView()
            .environmentObject(PhotoData())
    }
}

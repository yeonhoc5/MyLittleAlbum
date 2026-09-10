//
//  ImageDetailView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/31.
//

import SwiftUI
import Photos

struct ImageDetailView<TempView: View>: View {
  @Environment(\.scenePhase) var scenePhase
  
  let asset: MLAsset
  let imageManager: PHCachingImageManager
  let geometry: GeometryProxy
  @State var fetchedImage: UIImage!
  let tempView: () -> TempView
  let resutlMedia: (UIImage) -> Void
  @Namespace var nameSpace
  
  var body: some View {
    if let image = fetchedImage {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .onAppear {
          resutlMedia(image)
        }
    } else {
      tempView()
        .opacity(0.5)
        .onAppear {
          DispatchQueue.global(qos: .userInteractive).async {
            withAnimation {
              fetchingImage(asset: asset.phAsset,
                            size: geometry.size)
            }
          }
        }
      }
  }
}

//
extension ImageDetailView {
  func fetchingImage(asset: PHAsset, size: CGSize) {
    let options = PHImageRequestOptions()
    options.deliveryMode = .opportunistic
    options.resizeMode = .exact
    options.isSynchronous = true
    options.isNetworkAccessAllowed = true

    let creteria = creteriaResult(
      screenSize: size,
      size: CGSize(width: asset.pixelWidth,
                   height: asset.pixelHeight)
    )
    let creteriaSize = (creteria == .width ? size.width : size.height) * scale
    let anotherSize: CGFloat = (
      creteria == .width
      ? (CGFloat(asset.pixelHeight) * size.width / CGFloat(asset.pixelWidth))
      : (CGFloat(asset.pixelWidth) * size.height / CGFloat(asset.pixelHeight))
    ) * scale
    let size = CGSize(width: creteria == .width ? creteriaSize : anotherSize,
                      height: creteria == .height ? creteriaSize : anotherSize)
    imageManager.requestImage(for: asset,
                              targetSize: size,
                              contentMode: .aspectFit,
                              options: options) { assetImage, _ in
      if let image = assetImage {
        dispatchAnimation {
          self.fetchedImage = image
        }
      }
    }
  }
  
}


struct ImageDetailView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(PhotoData())
  }
}

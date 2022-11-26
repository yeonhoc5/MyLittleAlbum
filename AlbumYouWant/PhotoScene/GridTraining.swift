//
//  GridTraining.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/23.
//

import SwiftUI
import Photos

struct GridTraining: View {
    @EnvironmentObject var photoData: PhotoData
    @State private var numberOfRows: Int = 5
    let imageManage = PHCachingImageManager()
    let spacing: CGFloat = 1
    let scale = UIScreen.main.scale
    let thumbNailSize: CGSize = CGSize(width: .bitWidth, height: .bitWidth)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)]) {
                ForEach(1..<25) { index in
//                        let width = geo.size.width
//                        let height = geo.size.height
//                        let scale = UIScreen.main.scale
//                        let thumbNailSize: CGSize = CGSize(width: width * scale, height: height * scale)
                        if let image = loadImage(index: index, thumbNailSize: thumbNailSize) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                .clipped()
                                .aspectRatio(1, contentMode: .fit)
                                
                        }
                    }
            }
        }
    }
    
    func loadImage(index: Int, thumbNailSize: CGSize) -> UIImage? {
        let asset = photoData.allPhotos.object(at: index)
        var loadedImage: UIImage!
//        requestOpsitons.deliveryMode = .highQualityFormat
//        requestOpsitons.isSynchronous = false
        imageManage.requestImage(for: asset, targetSize: thumbNailSize, contentMode: .aspectFill, options: nil) { image, _ in
            if let image = image{
                loadedImage = image
            }
        }
        return loadedImage
    }
}

struct GridTraining_Previews: PreviewProvider {
    static var previews: some View {
        GridTraining()
            .environmentObject(PhotoData())
    }
}

//
//  PhotoView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos
import UIKit

struct PhotoView: View {
    @EnvironmentObject var photoData: PhotoData
    var allPhotos: PHFetchResult<PHAsset>!
    
    let imageManage = PHCachingImageManager()
    let spacing: CGFloat = 2
    
    var body: some View {
        return ZStack(alignment: .bottom) {
            photoGridView
            PhotoMenu(allPhotos: allPhotos)
                .offset(CGSize(width: 0, height: -30))
        }
    }
     
    var photoGridView: some View {
        let coloumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 5)
        return ScrollView {
            LazyVGrid(columns: coloumns, spacing: spacing) {
                if let allPhotos = allPhotos {
                    ForEach(0..<allPhotos.count, id: \.self) { index in
                        thumbnailView(index: index)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            .padding(.bottom, 100)
            
        }
    }
    
    func thumbnailView(index: Int) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let scale: CGFloat = UIScreen.main.scale
            let thumbNailSize: CGSize = CGSize(width: width * scale, height: height * scale)
            if let image = loadImage(index: index, thumbNailSize: thumbNailSize) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    
            }
        }
        
    }
    
    func loadImage(index: Int, thumbNailSize: CGSize) -> UIImage? {
        var image: UIImage!
        let asset = allPhotos.object(at: index)
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = true
        requestOptions.resizeMode = .exact
        imageManage.requestImage(for: asset, targetSize: thumbNailSize, contentMode: .default, options: requestOptions) { assetImage, _ in
                if let assetImage = assetImage {
                    image = assetImage
//                    print(image.size)
                }
            }
        return image
    }
    
}

struct PhotoView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoView(allPhotos: PhotoData().allPhotos)
            .environmentObject(PhotoData())
    }
}



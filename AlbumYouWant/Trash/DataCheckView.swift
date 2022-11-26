//
//  DataCheckView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/10.
//

import SwiftUI
import Photos
//import PhotosUI

struct DataCheckView: View {
    @EnvironmentObject var photoData: PhotoData
    @State private var numberOfRows: Int = 5
    let spacing: CGFloat = 1
    let imageManage = PHCachingImageManager()
    
    var body: some View {
        let coloumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: numberOfRows)
        GeometryReader {
            let width = ($0.size.width - 4) / 5
            LazyVGrid(columns: coloumns, spacing: spacing) {
                ForEach(0..<photoData.allPhotos.count, id: \.self) { index in
                    if let image = loadImage(index: index) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: width)
                            .clipped()
                    }
                }
            }
        }
    }
    
    func loadImage(index: Int) -> UIImage? {
        let asset = photoData.allPhotos.object(at: index)
        var loadedImage = UIImage()
        imageManage.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: nil) { image, _ in
            if let image = image{
                loadedImage = image
            }
        }
        return loadedImage
    }
}

struct DataCheckView_Previews: PreviewProvider {
    static var previews: some View {
        DataCheckView()
            .environmentObject(PhotoData())
    }
}

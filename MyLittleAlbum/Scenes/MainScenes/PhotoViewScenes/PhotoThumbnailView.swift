//
//  PhotoView2.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/16.
//

import SwiftUI

struct PhotoThumbnailView: View {
    @EnvironmentObject var photoData: PhotoData
    @State var image: Image! = Image("sample")
    private var assetLocalId: String
    
    init(assetLocalId: String) {
            self.assetLocalId = assetLocalId
        }
    
    var body: some View {
            ZStack {
                // Show the image if it's available
                if let image = image {
                    GeometryReader { proxy in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: proxy.size.width,
                                height: proxy.size.width
                            )
                            .clipped()
                    }
                    // We'll also make sure that the photo will
                    // be square
                    .aspectRatio(1, contentMode: .fit)
                } else {
                    // Otherwise, show a gray rectangle with a
                    // spinning progress view
                    Rectangle()
                        .foregroundColor(.gray)
                        .aspectRatio(1, contentMode: .fit)
                    ProgressView()
                }
            }
            // We need to use the task to work on a concurrent request to
            // load the image from the photo library service, which
            // is asynchronous work.
            .task {
                await loadImageAsset()
            }
            // Finally, when the view disappears, we need to free it
            // up from the memory
            .onDisappear {
                image = nil
            }
        }
}

extension PhotoThumbnailView {
    func loadImageAsset(
        targetSize: CGSize = CGSize(width: 100, height: 100)
    ) async {
            guard let uiImage = try? await photoData
            .fetchImage(
                byLocalIdentifier: assetLocalId,
                targetSize: targetSize
            ) else {
                image = nil
                return
            }
        image = Image(uiImage: uiImage)
    }
}



struct PhotoView2_Previews: PreviewProvider {
    static var previews: some View {
        PhotoThumbnailView(assetLocalId: "")
    }
}

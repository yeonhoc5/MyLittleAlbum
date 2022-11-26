//
//  PhotoThumbnailView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/25.
//

import SwiftUI
import Photos

struct PhotoThumbnailView: View {
    @State private var image: Image?
    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    private var assetLocalId: String
    
    init(assetLocalId: String) {
            self.assetLocalId = assetLocalId
        }
    
    var body: some View {
        ZStack {
            if let image = image {
                GeometryReader { proxy in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame( width: proxy.size.width, height: proxy.size.width)
                        .clipped()
                }
                .aspectRatio(1, contentMode: .fit)
            } else {
                Rectangle()
                    .foregroundColor(.gray)
                    .aspectRatio(1, contentMode: .fit)
                ProgressView()
            }
        }
        .task { await loadImageAsset() }
        .onDisappear { image = nil }
    }
}

extension PhotoThumbnailView {
    func loadImageAsset(targetSize: CGSize = PHImageManagerMaximumSize) async {
        guard let uiImage = try? await photoLibraryService
            .fetchImage( byLocalIdentifier: assetLocalId, targetSize: targetSize) else {
            image = nil
            return
        }
        image = Image(uiImage: uiImage)
    }
}


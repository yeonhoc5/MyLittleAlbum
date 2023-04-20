//
//  CellView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI
import Photos

struct ClassicCell: View {
    var cellType: CellType
    
//    var album: Album!
    
    var title: String!
    
    var countAlbum: Int!
    var countFolder: Int!
    
    var rprsttivePhoto1: PHAsset!
    
    var width: CGFloat! = 100
    var height: CGFloat! = 100
    
    var showingLine: Bool = false
    
    var color: Color! = .orange
    let emptyLabel: String = "빈 앨범"
    var cornerRadius: CGFloat! = 5
    
    var body: some View {
        VStack(spacing: 0) {
            switch cellType {
            case .folder: folderCell(countAlbum: countAlbum ?? 0, countFolder: countFolder ?? 0, width: width * 0.8, height: height * 0.65)
            case .album: albumCell(width: width, height: height)
            case .miniAlbum: albumCell(width: width * 0.8, height: height * 0.58, padding: height * 0.07)
            }
            cellTitle
        }
    }
}

extension ClassicCell {
    
    func folderCell(countAlbum: Int = 0, countFolder: Int = 0, width: CGFloat!, height: CGFloat!) -> some View {
        ZStack(alignment: .bottom) {
            imageScaledFit(systemName: "folder.fill", width: width, height: height)
                .foregroundColor(color)
                .padding(0)
            Text("\(countFolder) / \(countAlbum)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.bottom, 5)
                .frame(width: width * 0.8, height: height * 0.3, alignment: .bottomTrailing)
        }
    }
    
    @ViewBuilder
    func albumCell(width: CGFloat!, height: CGFloat!, padding: CGFloat = 0) -> some View {
        if let image = loadImage(thumbNailSize: CGSize(width: width * scale, height: height * scale)) {
            imageScaledFill(uiImage: image, width: width, height: height)
                .cornerRadius(5)
                .padding(.top, padding)
        } else {
            Color.gray.opacity(0.3)
                .frame(width: width, height: height)
                .cornerRadius(5)
                .overlay(alignment: .bottomTrailing) {
                    Text(emptyLabel)
                    .font(.caption).foregroundColor(.secondary)
                    .padding([.bottom, .trailing], 5)
                }
                .padding(.top, padding)
        }
    }
    
    var cellTitle: some View {
        Text(title ?? "")
            .font(.caption).bold().foregroundColor(color)
            .truncationMode(.tail)
            .frame(width: cellType == .album ? width:width * 0.8, height: height * 0.25, alignment: .center)
    }
    
    func loadImage(thumbNailSize: CGSize) -> UIImage? {
        let imageManager = PHCachingImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .exact
        requestOptions.isNetworkAccessAllowed = true
        var image: UIImage!
        if let asset = rprsttivePhoto1 {
            imageManager.requestImage(for: asset, targetSize: thumbNailSize, contentMode: .default, options: requestOptions) { assetImage, _ in
                    if let assetImage = assetImage {
                        image = assetImage
                    }
                }
        }
        return image
        
    }
    
}

//struct FolderAndAlbumCell_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack {
//            HStack {
//                ClassicCell(cellType: .album, title: "단양여행", image: "sample", color: .orange)
//                ClassicCell(cellType: .album, title: "단양여행", image: "sample", color: .orange)
//            }
//            HStack(alignment: .bottom) {
//                ClassicCell(cellType: .folder, title: "단양여행", color: .orange)
//                ClassicCell(cellType: .miniAlbum, title: "단양여행", image: "sample", color: .orange)
//                ClassicCell(cellType: .miniAlbum, title: "단양여행", color: .orange)
//            }
//        }
//    }
//}

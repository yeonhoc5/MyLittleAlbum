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
    var title: String!
    
    var countFolder: Int!
    var countAlbum: Int!
    
    var rprstPhoto1: PHAsset!
    
    var width: CGFloat! = 100
    
    var color: Color! = .orange
    let emptyLabel: String = "빈 앨범"
    var cornerRadius: CGFloat! = 5
    
    var sampleCase: SampleCase! = SampleCase.none
    
    var body: some View {
        VStack(spacing: 0) {
            switch cellType {
            case .folder: folderCell(width: width)
            case .album: albumCell(width: width)
            case .miniAlbum: albumCell(width: width, cellType: .miniAlbum)
            }
            cellTitle(width: width)
        }
    }
}

extension ClassicCell {
    @ViewBuilder
    func albumCell(width: CGFloat, cellType: CellType = .album) -> some View {
        let height = width * heightRatio(uiMode: .classic, cellType: cellType)
        let albumHeight = height * (cellType == .album ? 1 : 0.9)
        Group {
            if sampleCase == SampleCase.none {
                if let image = loadImage(thumbNailSize: 
                                            CGSize(width: width * scale,
                                                   height: albumHeight * scale)) {
                    imageScaledFill(uiImage: image,
                                    width: width,
                                    height: albumHeight)
                        
                } else {
                    Color.gray.opacity(0.3)
                        .overlay(alignment: .bottomTrailing) {
                            Text(emptyLabel)
                            .font(.caption)
                            .foregroundColor(.fancyBackground)
                            .padding([.bottom, .trailing], 5)
                        }
                }
            } else {
                imageScaledFill(cellType == .album
                                ? "sampleImage04" : "sampleImage02",
                                width: width,
                                height: albumHeight,
                                radius: cornerRadius)
            }
        }
        .cornerRadius(cornerRadius)
        .padding(.top, cellType == .miniAlbum ? height * 0.1 : 0)
        .frame(width: width, height: height)
    }
    
    func folderCell(width: CGFloat) -> some View {
        let height = width * heightRatio(uiMode: .classic, cellType: .folder)
        return ZStack(alignment: .bottom) {
            imageNonScaled(systemName: "folder.fill",
                           width: width,
                           height: height,
                           color: .orange)
                .foregroundColor(color)
                .padding(0)
            Text("\(countFolder ?? 0) / \(countAlbum ?? 0)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.bottom, 5)
                .frame(width: width * 0.8, 
                       height: height * 0.3,
                       alignment: .bottomTrailing)
        }
        .frame(width: width, height: height)
    }
    
    
    func cellTitle(width: CGFloat) -> some View {
        Text(title ?? "")
            .font(.caption)
            .bold()
            .foregroundColor(color)
            .truncationMode(.tail)
            .frame(width: width, 
                   height: width * 0.25,
                   alignment: .center)
    }
    
    func loadImage(thumbNailSize: CGSize) -> UIImage? {
        let imageManager = PHImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .exact
        requestOptions.isNetworkAccessAllowed = true
        var image: UIImage!
        if let asset = rprstPhoto1 {
            imageManager.requestImage(for: asset, targetSize: thumbNailSize, contentMode: .default, options: requestOptions) { assetImage, _ in
                    if let assetImage = assetImage {
                        image = assetImage
                    }
                }
        }
        return image
        
    }
    
}

struct FolderAndAlbumCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                ClassicCell(cellType: .album, title: "앨범1", sampleCase: .one)
                ClassicCell(cellType: .album, title: "앨범1")
            }
            HStack(alignment: .bottom) {
                ClassicCell(cellType: .folder, title: "폴더")
                ClassicCell(cellType: .miniAlbum, title: "미니앨범1", sampleCase: .one)
                ClassicCell(cellType: .miniAlbum, title: "미니앨범2")
            }
        }
        .preferredColorScheme(.dark)
    }
}

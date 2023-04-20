//
//  FancyCell.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import SwiftUI
import Photos

struct FancyCell: View {
    // cell 폴더 or 일반앨범 or 미니앨범 (3가지 케이스)
    var cellType: CellType
    
// 폴더, 앨범 공용 프라퍼티
    let title: String
// 폴더용 프라퍼티
    var countOfFolder: Int!
    var countOfAlbum: Int!
// 앨범용 프라퍼티
    let colorIndex: Int
    let rprstPhoto1: PHAsset!
    let rprstPhoto2: PHAsset!
// 레이아웃
    var width: CGFloat! = 115
    let height: CGFloat! = 130
    let cornerRadius: CGFloat! = 5
    // 타이틀-이미지 / 이미지-이미지 spacing
    let spacing: CGFloat! = 5
    
    var body: some View {
        switch cellType {
        case .folder: folderCell
        case .album: albumCell
        case .miniAlbum: miniAlbumCell
        }
    }
}

extension FancyCell {
    var folderCell: some View {
        imageNonScaled(systemName: "folder.fill", width: width * 0.8, height: height * 0.7, color: .folder)
            .overlay(alignment: .bottom) {
                titleText(title, font: .footnote, color: .fancyBackground)
                    .frame(width: width * 0.7, height: height * 0.4, alignment: .topLeading)
                    .multilineTextAlignment(.leading)
            }
            .overlay(alignment: .bottomTrailing, content: {
                titleText("\(countOfFolder ?? 0) / \(countOfAlbum ?? 0)", font: .caption, color: .fancyBackground.opacity(0.5))
                    .padding([.bottom, .trailing], 5)
            })
    }
    
    var albumCell: some View {
        let imageHeight = height * 0.6
        let titleHeight = height * 0.26
        let radius = width * 0.05
        return ZStack {
            RoundedRectangle(cornerRadius: radius)
                .foregroundColor(colorSet[colorIndex % colorSet.count])
            VStack(spacing: 3) {
                titleText(title, font: .footnote.bold(), color: .white)
                    .frame(width: width * 0.9, height: titleHeight, alignment: .topLeading)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 5)
                if rprstPhoto2 != nil {
                    let firstWidth = width * 0.55
                    let secondWidth = width * 0.25
                    if let imageFirst = loadImage(asset: rprstPhoto1, thumbNailSize: CGSize(width: firstWidth * scale, height: imageHeight * scale)),
                       let imageSecond = loadImage(asset: rprstPhoto2, thumbNailSize: CGSize(width: secondWidth * scale, height: imageHeight * scale)) {
                        HStack(spacing: spacing) {
                            imageScaledFill(uiImage: imageFirst, width: firstWidth, height: imageHeight, radius: radius)
                            imageScaledFill(uiImage: imageSecond, width: secondWidth, height: imageHeight, radius: radius)
                        }
                    } else {
                        spacerRectangle(color: .clear, height: imageHeight)
                    }
                } else if rprstPhoto1 != nil {
                    let firstWidth = width * 0.8
                    if let imageFirst = loadImage(asset: rprstPhoto1, thumbNailSize: CGSize(width: firstWidth * scale, height: imageHeight * scale)) {
                        imageScaledFill(uiImage: imageFirst, width: firstWidth, height: imageHeight, radius: radius)
                    } else {
                        spacerRectangle(color: .clear, height: imageHeight)
                    }
                } else {
                    Text(emptyLabel[colorIndex % emptyLabel.count])
                        .foregroundColor(.white.opacity(0.5))
                        .frame(height: imageHeight)
                }
            }
            
        }
        .frame(width: width, height: height)
        .padding(1)
    }
    
    var miniAlbumCell: some View {
        let imageWidth = width * 0.7
        let imageHeight = width * 1.13 * 0.47
        let radius = width * 0.056
        let scale = 3.0
        return VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .foregroundColor(colorSet[colorIndex % colorSet.count])
                VStack(spacing: spacing) {
                    titleText(title, font: .footnote, color: .black)
                        .frame(width: imageWidth, height: width * 1.13 * 0.1, alignment: .leading)
                        .lineLimit(1)
                    if rprstPhoto1 != nil {
                        if let imageFirst = loadImage(asset: rprstPhoto1, thumbNailSize: CGSize(width: imageWidth * scale, height: imageHeight * scale)) {
                            imageScaledFill(uiImage: imageFirst, width: imageWidth, height: imageHeight, radius: radius)
                        } else {
                            spacerRectangle(color: .clear, height: imageHeight)
                        }
                    } else {
                        Text(emptyLabel[colorIndex % emptyLabel.count])
                            .foregroundColor(.white.opacity(0.5))
                            .frame(height: imageHeight)
                    }
                }
            }
            .frame(width: width * 0.8, height: width * 1.13 * 0.715)
        }
    }
    
    func loadImage(asset: PHAsset, thumbNailSize: CGSize) -> UIImage? {
        let imageManager = PHCachingImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.resizeMode = .fast
        var image: UIImage!
        imageManager.requestImage(for: asset, targetSize: thumbNailSize, contentMode: .default, options: requestOptions) { assetImage, _ in
                if let assetImage = assetImage {
                    image = assetImage
                }
            }
        return image
    }
}
//
//struct FancyCell_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack {
//            HStack {
//                FancyCell(cellType: .album, album: Albu, count: 10)
//                FancyCell(cellType: .album, title: "2022년 서울", count: 1)
//                FancyCell(cellType: .album, title: "명동", count: 0)
//            }
//            HStack {
//                FancyCell(cellType: .folder, title: "2022년")
//                FancyCell(cellType: .miniAlbum, title: "단양", count: 1)
//                FancyCell(cellType: .miniAlbum, title: "하동", count: 0)
//            }
//        }
//    }
//}

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
    var countFolder: Int!
    var countAlbum: Int!
    // 앨범용 프라퍼티
    var colorIndex: Int
    var rprstPhoto1: PHAsset!
    var rprstPhoto2: PHAsset!
// 레이아웃
    var width: CGFloat! = 115
//    var height: CGFloat! = 130
    let cornerRadius: CGFloat! = 5
    // 타이틀-이미지 / 이미지-이미지 spacing
    let spacing: CGFloat! = 7.0
    var sampleCase: SampleCase! = SampleCase.none
    
    var body: some View {
        switch cellType {
        case .folder: folderCell(width: width)
        case .album: albumCell(width: abs(width))
        case .miniAlbum: miniAlbumCell(width: width)
        }
    }
}

extension FancyCell {
    func albumCell(width: CGFloat) -> some View {
        let radius = width * 0.05
        return ZStack {
            bgColor(index: colorIndex, radius: radius)
            VStack(spacing: spacing) {
                titleText(title, font: .footnote.bold(), color: .white)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(width:  abs(width) > 0
                           ? abs(width - (2.0 * spacing)) : 0,
                           alignment: .topLeading)
                GeometryReader(content: { geometry in
                    let innerWidth = geometry.size.width
                    let innerHeight = geometry.size.height
                    let innerSpacing = spacing * 0.8
                    let firstWidth = (innerWidth-(innerSpacing)) * 0.65
                    let secondWidth = (innerWidth-(innerSpacing)) * 0.35
                    if sampleCase == SampleCase.none {
                        if rprstPhoto2 != nil {
                            if let imageFirst = loadImage(
                                asset: rprstPhoto1,
                                thumbNailSize: CGSize(
                                    width: firstWidth * scale,
                                    height: innerHeight * scale)),
                               let imageSecond = loadImage(
                                asset: rprstPhoto2,
                                thumbNailSize: CGSize(
                                    width: secondWidth * scale,
                                    height: innerHeight * scale)) {
                                HStack(spacing: innerSpacing) {
                                    imageScaledFill(
                                        uiImage: imageFirst,
                                        width: firstWidth,
                                        height: innerHeight,
                                        radius: radius
                                    )
                                    imageScaledFill(
                                        uiImage: imageSecond,
                                        width: secondWidth,
                                        height: innerHeight,
                                        radius: radius
                                    )
                                }
                            } else {
                                spacerRectangle(color: .clear,
                                                height: innerHeight)
                            }
                        } else if rprstPhoto1 != nil {
                            if let imageFirst = loadImage(asset: rprstPhoto1, 
                                                          thumbNailSize: CGSize(
                                                            width: innerWidth * scale,
                                                            height: innerHeight * scale)) {
                                imageScaledFill(uiImage: imageFirst, 
                                                width: innerWidth,
                                                height: innerHeight,
                                                radius: radius)
                            } else {
                                spacerRectangle(color: .clear,
                                                height: innerHeight)
                            }
                        } else {
                            Text(emptyLabel[colorIndex % emptyLabel.count])
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: abs(width - (2.0 * spacing)),
                                       height: innerHeight)
                        }
                    } else if sampleCase == .overTwo {
                        HStack(spacing: innerSpacing) {
                            imageScaledFill("sampleImage01",
                                            width: firstWidth,
                                            height: innerHeight,
                                            radius: cornerRadius)
                            
                            imageScaledFill("sampleImage03",
                                            width: secondWidth,
                                            height: innerHeight,
                                            radius: cornerRadius)
                        }
                    } else {
                        imageScaledFill("sampleImage02",
                                        width: innerWidth,
                                        height: innerHeight,
                                        radius: cornerRadius)
                    }
                })
            }
            .padding(spacing)
        }
        .frame(width: width,
               height: width * heightRatio(uiMode: .fancy, cellType: .album))
    }
    
    func folderCell(width: CGFloat) -> some View {
        let height = width * heightRatio(uiMode: .fancy, cellType: .folder)
        let innerWidth = width - (2.0 * spacing)
        let innerHeight = height - (3.0 * spacing)
        return imageNonScaled(systemName: "folder.fill",
                       width: width,
                       height: height,
                       color: .folder)
        .offset(y: 1.0)
        .overlay(alignment: .center) {
            VStack(alignment: .leading, spacing: spacing, content: {
                titleText("\(countFolder ?? 0) / \(countAlbum ?? 0)",
                          font: .caption,
                          color: .fancyBackground.opacity(0.5))
                .lineLimit(1)
                .frame(width: innerWidth,
                       height: innerHeight * 0.33,
                       alignment: .leading)
                titleText(title,
                          font: .footnote,
                          color: .fancyBackground)
                .lineLimit(.max)
                .multilineTextAlignment(.leading)
                .frame(width: innerWidth,
                       height: innerHeight * 0.67,
                       alignment: .topLeading)
            })
        }
        .frame(width: width,
               height: secondaryHeight(width: width, uiMode: .fancy))
    }
    
    func miniAlbumCell(width: CGFloat) -> some View {
        let radius = width * 0.05
        let miniSpacing = spacing * 0.8
        let height = secondaryHeight(width: width, uiMode: .fancy)
        return VStack(spacing: 0) {
            Rectangle()
                .fill(.clear)
                .frame(height: height * 0.12)
            ZStack {
                bgColor(index: colorIndex, radius: radius)
                VStack(spacing: spacing) {
                    titleText(title, font: .footnote, color: .black, inline: true)
                        .frame(width: width - (2.0 * miniSpacing),
                               alignment: .topLeading)
                        .lineLimit(1)
                    GeometryReader(content: { geometry in
                        let innerWidth = geometry.size.width
                        let innerHeight = geometry.size.height
                        if sampleCase == SampleCase.none {
                            if rprstPhoto1 != nil {
                                if let imageFirst = loadImage(asset: rprstPhoto1,
                                                              thumbNailSize: CGSize(width: innerWidth * scale, height: innerHeight * scale)) {
                                    imageScaledFill(uiImage: imageFirst,
                                                    width: innerWidth,
                                                    height: innerHeight,
                                                    radius: radius)
                                } else {
                                    spacerRectangle(color: .clear, 
                                                    height: innerHeight)
                                }
                            } else {
                                Text(emptyLabel[colorIndex % emptyLabel.count])
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: innerWidth,
                                           height: innerHeight)
                            }
                        } else {
                            imageScaledFill("sampleImage04",
                                            width: innerWidth,
                                            height: innerHeight,
                                            radius: cornerRadius)
                        }
                    })
                }
                .padding(miniSpacing)
            }
        }
        .frame(width: width,
               height: secondaryHeight(width: width, uiMode: .fancy))
    }
    
}

extension FancyCell {
    func loadImage(asset: PHAsset, thumbNailSize: CGSize) -> UIImage? {
        let imageManager = PHImageManager()
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

struct FancyCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                FancyCell(cellType: .album,
                          title: "앨범1",
                          colorIndex: 0, sampleCase: .overTwo)
                FancyCell(cellType: .album,
                          title: "앨범2",
                          colorIndex: 1, sampleCase: .one)
                FancyCell(cellType: .album,
                          title: "앨범3",
                          colorIndex: 2)
            }
            HStack {
                FancyCell(cellType: .folder,
                          title: "폴더",
                          colorIndex: 0)
                FancyCell(cellType: .miniAlbum,
                          title: "미니앨범1",
                          colorIndex: 3, sampleCase: .one)
                FancyCell(cellType: .miniAlbum,
                          title: "미니앨범2",
                          colorIndex: 4)
                
            }
        }
        .frame(height: 100)
        .preferredColorScheme(.dark)
    }
}


extension FancyCell {
    func bgColor(index: Int, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .foregroundColor(colorSet[index % colorSet.count])
    }
}

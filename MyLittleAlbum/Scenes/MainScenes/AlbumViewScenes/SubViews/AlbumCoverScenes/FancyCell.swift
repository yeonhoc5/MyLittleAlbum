//
//  FancyCell.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import SwiftUI
import Photos

struct FancyCell: View  {
    // cell 폴더 or 일반앨범 or 미니앨범 (3가지 케이스)
    var cellType: CellType
    // 폴더, 앨범 공용 프라퍼티
    let title: String
    // 폴더용 프라퍼티
    var countFolder: Int!
    var countAlbum: Int!
    // 앨범용 프라퍼티
    let colorIndex: Int
//    let randomNum1: Int
//    let randomNum2: Int
    let count: Int
    var rpstPhoto1: UIImage!
    var rpstPhoto2: UIImage!

// 레이아웃
    var width: CGFloat! = 115
//    var height: CGFloat! = 130
    let cornerRadius: CGFloat! = 5
    // 타이틀-이미지 / 이미지-이미지 spacing
    let spacing: CGFloat! = 7.0
//    var sampleCase: SampleCase! = SampleCase.none
    
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
                    let firstWidth = (innerWidth-innerSpacing) * 0.65
                    let secondWidth = (innerWidth-innerSpacing) * 0.35
                    if count == 0 {
                        Text(emptyLabel[colorIndex % emptyLabel.count])
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: abs(width - (2.0 * spacing)),
                                   height: innerHeight)
                    } else {
                        if let photos = rpstPhoto1 {
                            if count == 1 {
//                                if let image = imageScaledFill(uiImage: ,
//                                                    width: innerWidth,
//                                                    height: innerHeight,
//                                                    radius: radius)
//                                } else {
//                                    Color.gray
//                                }
                            } else {
//                                if let image1 = photos[firstWidth],
//                                   let image2 = photos[secondWidth] {
//                                    HStack(spacing: innerSpacing) {
//                                        imageScaledFill(uiImage: image1,
//                                                        width: firstWidth,
//                                                        height: innerHeight,
//                                                        radius: radius)
//                                        imageScaledFill(uiImage: image2,
//                                                        width: secondWidth,
//                                                        height: innerHeight,
//                                                        radius: radius)
//                                    }
//                                } else {
//                                    Color.gray
//                                        .onAppear {
//                                            [firstWidth, secondWidth].forEach {
//                                                album.setPhotos(
//                                                    uiMode: .fancy,
//                                                    size: CGSize(width: $0,
//                                                                 height: innerHeight),
//                                                    randomNum1: randomNum1,
//                                                    randomNum2: randomNum2)
//                                            }
//                                        }
//                                }
                            }
                        } else {
                            
                        }
                    }
                            
                })
            }
            .padding(spacing)
        }
        .frame(width: width,
               height: cellHeight(width: width, uiMode: .fancy, cellType: .album)
        )
    }
    
    func folderCell(width: CGFloat) -> some View {
        let height = cellHeight(width: width, uiMode: .fancy, cellType: .folder)
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
               height: cellHeight(width: width, uiMode: .fancy, cellType: .folder)
        )
    }
    
    func miniAlbumCell(width: CGFloat) -> some View {
        let radius = width * 0.05
        let miniSpacing = spacing * 0.8
        let height = cellHeight(width: width, uiMode: .fancy, cellType: .miniAlbum)
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
                        if let imageFirst = rpstPhoto1 {
                            imageScaledFill(uiImage: imageFirst,
                                            width: innerWidth,
                                            height: innerHeight,
                                            radius: radius)
                        } else {
                            Text(emptyLabel[colorIndex % emptyLabel.count])
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: innerWidth,
                                       height: innerHeight)
                        }
                    })
                }
                .padding(miniSpacing)
            }
        }
        .frame(width: width,
               height: cellHeight(width: width, uiMode: .fancy, cellType: .miniAlbum)
        )
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
            imageManager.requestImage(for: asset,
                                      targetSize: thumbNailSize,
                                      contentMode: .default,
                                      options: requestOptions) { assetImage, _ in
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
                          colorIndex: 0,
                          count: 2,
                          rpstPhoto1: UIImage(named: "sampleImage01"),
                          rpstPhoto2: UIImage(named: "sampleImage03"))
                FancyCell(cellType: .album,
                          title: "앨범2",
                          colorIndex: 1,
                          count: 1,
                          rpstPhoto1: UIImage(named: "sampleImage02"))
                          
                FancyCell(cellType: .album,
                          title: "앨범3",
                          colorIndex: 2,
                          count: 0)
            }
            HStack {
                FancyCell(cellType: .folder,
                          title: "폴더",
                          colorIndex: 0,
                          count: 0)
                FancyCell(cellType: .miniAlbum,
                          title: "미니앨범1",
                          colorIndex: 3,
                          count: 1,
                          rpstPhoto1: UIImage(named: "sampleImage04"))
                FancyCell(cellType: .miniAlbum,
                          title: "미니앨범2",
                          colorIndex: 4,
                          count: 0)
                
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

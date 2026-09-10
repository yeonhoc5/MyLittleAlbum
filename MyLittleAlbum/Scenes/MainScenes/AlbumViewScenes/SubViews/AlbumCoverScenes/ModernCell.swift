//
//  WhiteCell.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/30.
//

import SwiftUI
import Photos

struct ModernCell: View {
    var cellType: CellType
    var title: String!
    
    var countFolder: Int!
    var countAlbum: Int!

    var count: Int
    var rprstPhoto1: UIImage!
    
    var width: CGFloat! = 150
    
    let emptyLabel: String = "No Photos"
    var cornerRadius: CGFloat! = 5
    var textLabelOpacity = 0.8
    let spacing: CGFloat! = 7.0
    var sampleCase: SampleCase! = SampleCase.none
    
    var body: some View {
        switch cellType {
        case .folder: folderCell(width: width)
        case .album: albumCell(width: width)
                .shadow(color: .gray, radius: 0.2, x: 0, y: 0)
        case .miniAlbum: miniAlbumCell(width: width)
                .shadow(color: .gray, radius: 0.2, x: 0, y: 0)
        }
    }
}

extension ModernCell {
    func albumCell(width: CGFloat) -> some View {
        let height = cellHeight(width: width, uiMode: .modern, cellType: .album)
        let labelHeight = height * 0.35
        return ZStack(alignment: .bottom) {
            if count == 0 {
                emptyView(width: width,
                          height: height,
                          bottomPadding: labelHeight)
            } else {
                if rprstPhoto1 != nil {
                    imageScaledFill(uiImage: rprstPhoto1,
                                    width: width,
                                    height: height)
                } else {
                    EmptyView()
                }
            }
            modernTextLabel(title: title,
                           font: .subheadline,
                           width: width,
                           height: labelHeight)
            
        }
        .frame(width: width, height: height)
        .cornerRadius(cornerRadius)
    }

    func folderCell(width: CGFloat) -> some View {
        let height = cellHeight(width: width, uiMode: .modern, cellType: .folder)
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
               height: cellHeight(width: width, uiMode: .modern, cellType: .folder)
        )
    }
    
    
    func miniAlbumCell(width: CGFloat) -> some View {
        let secondaryHeight = cellHeight(width: width, uiMode: .modern, cellType: .miniAlbum)
        let miniHeight = secondaryHeight * 0.88
        return VStack(spacing: 0, content: {
            Rectangle()
                .fill(.clear)
                .frame(height: secondaryHeight * 0.12)
            ZStack(alignment: .bottom) {
                if count == 0 {
                    emptyView(width: width,
                              height: miniHeight,
                              bottomPadding: miniHeight * 0.3)
                        .font(.caption2)
                } else {
                    if rprstPhoto1 != nil {
                        imageScaledFill(uiImage: rprstPhoto1,
                                        width: width,
                                        height: miniHeight)
                    } else {
                        EmptyView()
                    }
                }
                modernTextLabel(title: title,
                               font: .caption,
                               width: width,
                               height: miniHeight * 0.3)
            }
            .frame(width: width, height: miniHeight)
            .cornerRadius(cornerRadius)
        })
        .frame(width: width, height: secondaryHeight)
    }
}


extension ModernCell {
    func emptyView(width: CGFloat, height: CGFloat, bottomPadding: CGFloat) -> some View {
        Color.fancyBackground
            .overlay {
                Text(emptyLabel)
                    .foregroundStyle(.white)
                    .padding(.bottom, bottomPadding)
            }
            .frame(width: width, height: height)
    }
    
    func modernTextLabel(title: String, font: Font.TextStyle, width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Color.white.opacity(textLabelOpacity)
            titleText(title, font: Font.system(font, weight: .semibold), color: .fancyBackground)
                .lineLimit(2, reservesSpace: true)
                .truncationMode(.tail)
                .lineSpacing(0.1)
                .kerning(0.4)
                .padding(.horizontal, 5)
        }
        .frame(width: width, height: height)
    }
    
    func loadImage(asset: PHAsset, thumbNailSize: CGSize) -> UIImage? {
        let imageManager = PHImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.resizeMode = .exact
        var image: UIImage!
        imageManager.requestImage(for: asset, targetSize: thumbNailSize, contentMode: .default, options: requestOptions) { assetImage, _ in
                if let assetImage = assetImage {
                    image = assetImage
                }
            }
        return image
    }
    
}

struct WhiteCell_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            FancyBackground()
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ModernCell(cellType: .album,
                                   title: "앨범1",
                                   count: 0)
                        ModernCell(cellType: .album,
                                   title: "앨범2",
                                   count: 0)
                        ModernCell(cellType: .album,
                                   title: "앨범3",
                                   count: 0)
                        ModernCell(cellType: .album,
                                   title: "앨범4",
                                   count: 0)
                        ModernCell(cellType: .album,
                                   title: "두 줄 짜리 제목 가나다라",
                                   count: 0)
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom) {
                        ModernCell(cellType: .folder,
                                   title: "폴더",
                                   count: 0)
                        ModernCell(cellType: .miniAlbum,
                                   title: "미니앨범1",
                                   count: 0)
                        ModernCell(cellType: .miniAlbum,
                                   title: "미니앨범2",
                                   count: 0)
                        ModernCell(cellType: .miniAlbum,
                                   title: "미니앨범3",
                                   count: 0)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

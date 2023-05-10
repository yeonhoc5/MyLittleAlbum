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

    var rprstPhoto1: PHAsset!
    
    var width: CGFloat! = min(screenSize.width, screenSize.height) / 3 - 15
    var height: CGFloat! = 100
    
    let emptyLabel: String = "No Photos"
    var cornerRadius: CGFloat! = 5
    var textLabelOpacity = 0.8
    
    var sampleCase: SampleCase! = SampleCase.none
    
    var body: some View {
        switch cellType {
        case .folder: folderCell
        case .album: albumCell
                .shadow(color: .gray, radius: 0.2, x: 0, y: 0)
        case .miniAlbum: miniAlbumCell
                .shadow(color: .gray, radius: 0.2, x: 0, y: 0)
        }
    }
}

extension ModernCell {
    
    var folderCell: some View {
        imageNonScaled(systemName: "folder.fill", width: width * 0.8, height: width * 0.9, color: .folder)
            .overlay(alignment: .bottom) {
                titleText(title, font: .footnote, color: .fancyBackground)
                    .frame(width: width * 0.7, height: height * 0.5, alignment: .topLeading)
                    .multilineTextAlignment(.leading)
            }
            .overlay(alignment: .bottomTrailing, content: {
                titleText("\(countFolder ?? 0) / \(countAlbum ?? 0)", font: .caption, color: .fancyBackground)
                    .padding([.bottom, .trailing], 5)
            })
    }
    
    var albumCell: some View {
        let regularHeight = height * 1.5
        return ZStack(alignment: .bottom) {
            if sampleCase == SampleCase.none {
                if rprstPhoto1 != nil {
                    if let image = loadImage(asset: rprstPhoto1,
                                             thumbNailSize: CGSize(width: width * scale,
                                                                   height: regularHeight * scale)) {
                        imageScaledFill(uiImage: image, width: width, height: regularHeight)
                    }
                } else {
                    emptyView(width: width, height: regularHeight, bottomPadding: height * 0.5)
                }
            } else {
                Color.white.opacity(0.5)
                    .frame(width: width, height: regularHeight)
                    .clipped()
                    .cornerRadius(cornerRadius)
            }
            moderTextLabel(title: title, font: .subheadline, width: width, height: height * 0.5)
        }
        .frame(width: width, height: regularHeight)
        .cornerRadius(cornerRadius)
    }

    
    var miniAlbumCell: some View {
        let miniWidth = width * 0.8
        let miniHeight = height * 0.8
        return ZStack(alignment: .bottom) {
            if sampleCase == SampleCase.none {
                if rprstPhoto1 != nil {
                    if let image = loadImage(asset: rprstPhoto1,
                                             thumbNailSize: CGSize(width: miniWidth * scale,
                                                                   height: miniHeight * scale)) {
                        imageScaledFill(uiImage: image, width: miniWidth, height: miniHeight)
                    }
                } else {
                    emptyView(width: miniWidth, height: miniHeight, bottomPadding: height * 0.3)
                        .font(.caption2)
                }
            } else {
                Color.white.opacity(0.5)
                    .frame(width: miniWidth, height: miniHeight)
                    .clipped()
                    .cornerRadius(cornerRadius)
            }
            moderTextLabel(title: title, font: .caption, width: miniWidth, height: height * 0.3)
        }
        .frame(width: miniWidth, height: miniHeight)
        .cornerRadius(cornerRadius)
    }
}


extension ModernCell {
    
    func emptyView(width: CGFloat, height: CGFloat, bottomPadding: CGFloat) -> some View {
        Color.fancyBackground
            .overlay {
                Text(emptyLabel)
                    .padding(.bottom, bottomPadding)
            }
            .frame(width: width, height: height)
    }
    
    func moderTextLabel(title: String, font: Font.TextStyle, width: CGFloat, height: CGFloat) -> some View {
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

struct WhiteCell_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            FancyBackground()
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ModernCell(cellType: .album, title: "앨범1", sampleCase: .one)
                        ModernCell(cellType: .album, title: "앨범2")
                        ModernCell(cellType: .album, title: "앨범3")
                        ModernCell(cellType: .album, title: "앨범4")
                        ModernCell(cellType: .album, title: "두 줄 짜리 제목 가나다라")
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom) {
                        ModernCell(cellType: .folder, title: "폴더")
                        ModernCell(cellType: .miniAlbum, title: "미니앨범1", sampleCase: .one)
                        ModernCell(cellType: .miniAlbum, title: "미니앨범2")
                        ModernCell(cellType: .miniAlbum, title: "미니앨범3")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

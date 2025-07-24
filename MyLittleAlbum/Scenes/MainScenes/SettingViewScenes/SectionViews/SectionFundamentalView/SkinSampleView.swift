//
//  SkinSampleView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/4/24.
//

import SwiftUI

struct SkinSampleView: View {
    let uiMode: UIMode
    let size: CGSize
    
    var body: some View {
        let firstWidth = 100.0
        let secondWidth = firstWidth * 0.7
        VStack(alignment: .center, spacing: 10) {
            HStack(alignment: .top) {
                if uiMode == .fancy {
                    CellView(uiMode: uiMode,
                             cellType: .album,
                             index: 0,
                             width: firstWidth, tapAction: {
                        
                    }) { size, namespace in
                        AlbumCoverView(
                            sampleMLAlbum: MLAlbum(sampleID: 1,
                                                   sampleCase: .overTwo),
                            uiMode: uiMode,
                            cellType: .album,
                            size: size,
                            albumCell: namespace,
                            rprstImage1: UIImage(named: "sampleImage01"),
                            rprstImage2: UIImage(named: "sampleImage03")
                        )
                    }
                }
                CellView(uiMode: uiMode,
                         cellType: .album,
                         index: 1,
                         width: firstWidth, tapAction: {
                    
                }) { size, namespace in
                    AlbumCoverView(
                        sampleMLAlbum: MLAlbum(sampleID: 2,
                                        sampleCase: .one),
                        uiMode: uiMode,
                        cellType: .album,
                        size: size,
                        albumCell: namespace,
                        rprstImage1: UIImage(named: "sampleImage02")
                    )
                }
                CellView(uiMode: uiMode,
                         cellType: .album,
                         index: 2,
                         width: firstWidth, tapAction: {
                    
                }) { size, namespace in
                    AlbumCoverView(
                        sampleMLAlbum: MLAlbum(sampleID: 3,
                                         sampleCase: .none),
                                   uiMode: uiMode,
                                   cellType: .album,
                                   size: size,
                                   albumCell: namespace)
                }
            }
            HStack(alignment: .top, content: {
                CellView(uiMode: uiMode,
                         cellType: .folder,
                         index: 0,
                         width: secondWidth, tapAction: {
                    
                }) { size, namespace in
                    FolderCoverView(folder: MLFolder(sampleID: 1),
                                    uiMode: uiMode,
                                    size: size,
                                    cellNameSpace: namespace)
                }
                CellView(uiMode: uiMode,
                         cellType: .miniAlbum,
                         index: 3,
                         width: secondWidth, tapAction: {
                    
                }) { size, namespace in
                    AlbumCoverView(
                        sampleMLAlbum: MLAlbum(sampleID: 4,
                                        sampleCase: .one),
                        uiMode: uiMode,
                        cellType: .miniAlbum,
                        size: size,
                        albumCell: namespace,
                        rprstImage1: UIImage(named: "sampleImage04")
                    )
                }
                CellView(uiMode: uiMode,
                         cellType: .miniAlbum,
                         index: 4,
                         width: secondWidth, tapAction: {
                }) { size, namespace in
                    AlbumCoverView(
                        sampleMLAlbum: MLAlbum(sampleID: 5,
                                        sampleCase: .none),
                        uiMode: uiMode,
                        cellType: .miniAlbum,
                        size: size,
                        albumCell: namespace)
                }
//
            })
        }
    }
    
    func classicImage(width: CGFloat, height: CGFloat) -> some View {
        Image(systemName: "photo")
            .resizable()
            .frame(width: width, height: height)
            .foregroundColor(Color.gray)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            }
            .clipped()
    }
}

#Preview {
    SkinSampleView(uiMode: .fancy, size: CGSize(width: 300, height: 150))
}

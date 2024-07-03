//
//  SkinSampleView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/2/24.
//

import SwiftUI

struct SkinSampleView: View {
    let uiMode: UIMode
    
    var body: some View {
        VStack(spacing: 10) {
            if uiMode == .fancy {
                HStack {
                    FancyCell(cellType: .album, title: "앨범1", colorIndex: 0, rprstPhoto1: nil, rprstPhoto2: nil, sampleCase: .overTwo)
                    FancyCell(cellType: .album, title: "앨범2", colorIndex: 1, rprstPhoto1: nil, rprstPhoto2: nil, sampleCase: .one)
                    FancyCell(cellType: .album, title: "앨범2", colorIndex: 2, rprstPhoto1: nil, rprstPhoto2: nil)
                }
                HStack(alignment: .bottom) {
                    FancyCell(cellType: .folder, title: "폴더", colorIndex: 0, rprstPhoto1: nil, rprstPhoto2: nil)
                    Group {
                        FancyCell(cellType: .miniAlbum, title: "미니앨범1", colorIndex: 4, rprstPhoto1: nil, rprstPhoto2: nil, sampleCase: .one)
                        FancyCell(cellType: .miniAlbum, title: "미니앨범2", colorIndex: 8, rprstPhoto1: nil, rprstPhoto2: nil)
                    }
                    .frame(height: 100)
                }
            } else if uiMode == .modern {
                HStack {
                    ModernCell(cellType: .album, title: "앨범1", sampleCase: .one)
                    ModernCell(cellType: .album, title: "앨범2")
                }
                HStack(alignment: .bottom) {
                    ModernCell(cellType: .folder, title: "폴더")
                    Group {
                        ModernCell(cellType: .miniAlbum, title: "미니앨범1", sampleCase: .one)
                        ModernCell(cellType: .miniAlbum, title: "미니앨범2")
                    }
                    
                }
            } else if uiMode == .classic {
                HStack(alignment: .top) {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color.gray)
                    ClassicCell(cellType: .album, width: 100, height: 100)
                }
                HStack(alignment: .top, content: {
                    ClassicCell(cellType: .folder)
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 80, height: 60)
                        .foregroundColor(Color.gray)
                    ClassicCell(cellType: .album, width: 80, height: 60)
                })
            }
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    SkinSampleView(uiMode: .fancy)
}

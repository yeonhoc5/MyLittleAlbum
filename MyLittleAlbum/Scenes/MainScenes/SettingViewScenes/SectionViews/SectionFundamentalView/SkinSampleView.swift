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
            switch uiMode {
            case .classic:
                HStack(alignment: .top) {
                    ClassicCell(cellType: .album,
                                width: firstWidth,
                                sampleCase: .overTwo)
                    ClassicCell(cellType: .album,
                                width: firstWidth)
                }
                HStack(alignment: .top, content: {
                    ClassicCell(cellType: .folder,
                                width: secondWidth)
                    ClassicCell(cellType: .miniAlbum,
                                width: secondWidth,
                                sampleCase: .overTwo)
                    ClassicCell(cellType: .miniAlbum,
                                width: secondWidth)
                })
            case .modern:
                HStack {
                    ModernCell(cellType: .album,
                               title: "앨범1",
                               width: firstWidth,
                               sampleCase: .one)
                    ModernCell(cellType: .album,
                               title: "앨범2",
                               width: firstWidth)
                }
                HStack(alignment: .bottom) {
                    ModernCell(cellType: .folder, title: "폴더", width: secondWidth)
                    Group {
                        ModernCell(cellType: .miniAlbum, title: "미니앨범1",
                                   width: secondWidth, sampleCase: .one)
                        ModernCell(cellType: .miniAlbum, title: "미니앨범2", width: secondWidth)
                    }
                    
                }
            case .fancy:
                HStack {
                    ForEach((0..<3)) { int in
                        FancyCell(cellType: .album,
                                  title: "앨범\(int+1)",
                                  colorIndex: int,
                                  width: firstWidth,
                                  sampleCase: SampleCase.returnType(int: 2-int))
                    }
                }
                HStack(alignment: .bottom, spacing: 10) {
                    FancyCell(cellType: .folder,
                              title: "폴더",
                              colorIndex: 0,
                              width: secondWidth)
                    Group {
                        ForEach(1..<3) { int in
                            FancyCell(cellType: .miniAlbum,
                                      title: "미니앨범\(int)",
                                      colorIndex: 4 * int,
                                      width: secondWidth,
                                      sampleCase: int == 1
                                      ? .one : SampleCase.none)
                        }
                    }
                }
            }
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

//
//  TempCoverView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/23/25.
//

import SwiftUI

struct TempCoverView: View {
    let title: String
    let nameSpace: Namespace.ID
    let size: CGSize
    let cellType: CellType
    
    var body: some View {
        Group {
            if cellType == .folder {
                let title = Text(title)
                  .font(.footnote)
                  .matchedGeometryEffect(id: "title", in: nameSpace)
                  .foregroundStyle(.black)
                  .lineLimit(1)
                  .frame(width: size.width - 14,
                         height: size.height,
                         alignment: .leading)
                let progress = ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.mini)
                    .frame(height: size.height / 2.5)
                Group {
                    if #available(iOS 26.0, *) {
                        ZStack(alignment: .bottomTrailing) {
                            title
                            progress
                        }
                    } else {
                        ZStack(alignment: .topLeading) {
                            title
                            progress
                        }
                    }
                }
            } else {
                VStack(alignment: .center, spacing: 0) {
                    Text(title)
                      .font(.footnote)
                      .matchedGeometryEffect(id: "title", in: nameSpace)
                      .lineLimit(cellType == .album ? 2 : 1)
                      .frame(width: size.width - 14)
                      .padding(cellType == .album ? normalPadding : miniPadding)
                    Rectangle()
                      .foregroundStyle(.clear)
                      .overlay(alignment: .center) {
                          ProgressView()
                              .progressViewStyle(.circular)
                              .controlSize(cellType == .miniAlbum ? .mini : .regular)
                      }
                }
                .frame(width: size.width - 14, height: size.height)
            }
        }
        .padding(.horizontal, 7)
        .frame(width: size.width, height: size.height)
    }
}

//#Preview {
//    TempCoverView(title: "Title", nameSpace: Name, size: <#T##CGSize#>)
//}

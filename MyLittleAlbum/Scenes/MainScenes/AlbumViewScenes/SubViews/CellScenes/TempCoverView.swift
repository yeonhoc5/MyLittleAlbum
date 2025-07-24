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
                ZStack(alignment: .topLeading) {
                    Text(title)
                        .matchedGeometryEffect(id: "title", in: nameSpace)
                        .font(.footnote)
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .frame(width: size.width - 14, height: size.height,
                               alignment: .leading)
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.mini)
                        .frame(height: size.height / 2)
                }
            } else {
                VStack(spacing: 15) {
                    Text(title)
                        .matchedGeometryEffect(id: "title", in: nameSpace)
                        .font(.footnote)
                        .lineLimit(cellType == .album ? 2 : 1)
                        .frame(width: size.width - 14)
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: size.width - 14)
                }
            }
        }
        .padding(.horizontal, 7)
        .frame(width: size.width, height: size.height)
    }
}

//#Preview {
//    TempCoverView(title: "Title", nameSpace: Name, size: <#T##CGSize#>)
//}

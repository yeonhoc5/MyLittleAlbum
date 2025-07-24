//
//  CellView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/13/25.
//

import SwiftUI

struct CellView<Content: View>: View {
    let uiMode: UIMode
    let cellType: CellType
    let index: Int!
    let width: CGFloat
    let height: CGFloat
    let content: (CGSize, Namespace.ID) -> Content
    @Namespace var cellNamespace
    
    init(uiMode: UIMode,
         cellType: CellType,
         index: Int!,
         width: CGFloat,
         content: @escaping (CGSize, Namespace.ID) -> Content) {
        self.content = content
        self.uiMode = uiMode
        self.cellType = cellType
        self.index = index
        self.width = width
        self.height = cellHeight(width: width, uiMode: uiMode, cellType: cellType) - 2
    }
    
    var body: some View {
        Group {
            switch cellType {
            case .folder:
                folderView(uiMode: uiMode)
            case .album, .miniAlbum:
                albumBGView(uiMode: uiMode, cellType: cellType)
            }
        }
        .frame(width: abs(width), height: abs(height))
    }
}

extension CellView {
    @ViewBuilder
    func folderView(uiMode: UIMode) -> some View {
        let color: Color = uiMode == .classic ? .orange : .folder
        if uiMode == .classic {
            GeometryReader { geoProxy in
                let size = geoProxy.size
                ZStack {
                    VStack(spacing: 5) {
                        GeometryReader { innerGeoProxy in
                            let innerSize = innerGeoProxy.size
                                imageNonScaled(systemName: "folder.fill",
                                               width: innerSize.width,
                                               height: innerSize.height,
                                               color: color)
                                .matchedGeometryEffect(id: "foldercell",
                                                       in: cellNamespace)
                        }
                        Text(" ")
                            .font(.footnote)
                    }
                    content(CGSize(width: size.width, height: size.height - 1),
                            cellNamespace)
                    .clipped()
                }
            }
        } else {
            ZStack {
                imageNonScaled(systemName: "folder.fill",
                               width: width,
                               height: height,
                               color: color)
                .matchedGeometryEffect(id: "foldercell", in: cellNamespace)
                content(CGSize(width: width, height: height),
                        cellNamespace)
            }
        }
    }
    
    @ViewBuilder
    func albumBGView(uiMode: UIMode,
                     cellType: CellType) -> some View {
        GeometryReader { geoProxy in
            let size = CGSize(width: geoProxy.size.width,
                              height: geoProxy.size.height)
            switch uiMode {
            case .fancy:
                VStack(spacing: 0) {
                    if cellType == .miniAlbum {
                        Spacer(minLength: 0)
                            .frame(height: size.height * 0.12)
                    }
                    ZStack {
                        let size = CGSize(
                            width: size.width,
                            height: size.height * (cellType == .miniAlbum ? 0.88 : 1)
                        )
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(colorSet[index % colorSet.count])
                            .animation(.snappy, value: index)
                            .matchedGeometryEffect(id: "cell", in: cellNamespace)
                        content(size, cellNamespace)
                    }
                }
            case .modern:
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color.gray.opacity(0.2))
                        .matchedGeometryEffect(id: "cell", in: cellNamespace)
                    content(size, cellNamespace)
                }
            case .classic:
                ZStack {
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color.gray.opacity(0.2))
                            .matchedGeometryEffect(id: "cell", in: cellNamespace)
                        titleText(" ", font: .caption, color: .orange, inline: true)
                            .bold().lineLimit(1)
                    }
                    content(size, cellNamespace)
                }
            }
        }
    }
}

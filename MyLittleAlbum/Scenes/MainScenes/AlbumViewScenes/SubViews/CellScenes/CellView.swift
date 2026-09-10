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
  let size: CGSize
  let content: (UIMode, CGSize, Namespace.ID) -> Content
  @Namespace var cellNamespace
  
  init(uiMode: UIMode,
       cellType: CellType,
       index: Int!,
       width: CGFloat,
       content: @escaping (UIMode, CGSize, Namespace.ID) -> Content) {
    self.content = content
    self.uiMode = uiMode
    self.cellType = cellType
    self.index = index
    self.size = CGSize(width: width,
                       height: cellHeight(width: width,
                                          uiMode: uiMode,
                                          cellType: cellType) - 2)
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
    .frame(width: abs(size.width), height: abs(size.height))
  }
}

extension CellView {
  @ViewBuilder
  func folderView(uiMode: UIMode) -> some View {
    let color: Color = uiMode == .classic ? .orange : .folder
    ZStack(alignment: .bottom) {
      VStack(spacing: 5) {
        imageNonScaled(systemName: "folder.fill",
                       width: size.width,
                       height: size.height,
                       color: color)
        .matchedGeometryEffect(id: "foldercell", in: cellNamespace)
        if uiMode == .classic {
          Text(" ").font(.footnote)
        }
      }
      content(uiMode, size, cellNamespace)
        .clipped()
    }
  }
  
  @ViewBuilder
  func albumBGView(uiMode: UIMode,
                   cellType: CellType) -> some View {
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
            .matchedGeometryEffect(id: "cell", in: cellNamespace)
            .animation(.snappy, value: index)
          content(uiMode, size, cellNamespace)
        }
      }
    case .modern:
      ZStack {
        RoundedRectangle(cornerRadius: 5)
          .foregroundStyle(Color.gray.opacity(0.2))
          .matchedGeometryEffect(id: "cell", in: cellNamespace)
        content(uiMode, size, cellNamespace)
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
        content(uiMode, size, cellNamespace)
      }
    }
  }
}

//
//  FolderCoverView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/20/25.
//

import SwiftUI

struct FolderCoverView: View {
    @ObservedObject var folder: MLFolder
    let uiMode: UIMode
    let size: CGSize
    let cellNameSpace: Namespace.ID
    
    var body: some View {
        let strCount = count(folder: folder)
        switch uiMode {
        case .classic:
            classicFolderCover(count: strCount)
        case .modern, .fancy:
            fancyFolderCover(count: strCount)
        }
    }
}

extension FolderCoverView {
    
    func count(folder: MLFolder) -> String {
        return "\(folder.foldersArray.count) / \(folder.albumsArray.count)"
    }
    func classicFolderCover(count: String) -> some View {
        VStack(spacing: 5) {
            GeometryReader { geoProxy in
                Text(count)
                    .font(.caption)
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .padding(.bottom, 5)
                    .frame(width: geoProxy.size.width - 10,
                           height: geoProxy.size.height,
                           alignment: .bottomTrailing)
                
            }
            titleText(folder.title, font: .caption, color: .orange, inline: true)
            .bold()
            .lineLimit(1)
            .contentTransition(.numericText())
            .matchedGeometryEffect(id: "title", in: cellNameSpace)
        }
    }
    func fancyFolderCover(count: String) -> some View {
        let spacing: CGFloat = 10
        return VStack(alignment: .leading,
                      spacing: spacing,
                      content: {
            titleText(count, font: .caption,
                      color: .fancyBackground.opacity(0.5))
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .frame(width: size.width - 10,
                           height: (size.height - spacing) * 0.33,
                           alignment: .bottomLeading)
                    .matchedGeometryEffect(id: "count", in: cellNameSpace)
            titleText(folder.title, font: .footnote,
                      color: .fancyBackground)
                    .lineLimit(.max)
                    .multilineTextAlignment(.leading)
                    .contentTransition(.numericText())
                    .frame(width: size.width - 10,
                           height: (size.height - spacing) * 0.67,
                           alignment: .topLeading)
                    .matchedGeometryEffect(id: "title", in: cellNameSpace)
        })
        .frame(width: size.width, height: size.height)
    }

}

//#Preview {
//    VStack {
//        CellView(uiMode: .classic,
//                 cellType: .folder,
//                 title: "Classic 앨범",
//                 index: 0,
//                 width: 100) { size in
//            FolderCoverView(folder: MLFolder(collectionList: nil),
//                            uiMode: .classic,
//                            size: size)
//                .environmentObject(MLPhotoData())
//        }
//        CellView(uiMode: .modern,
//                 cellType: .folder,
//                 title: "Modern 폴더",
//                 index: 0,
//                 width: 100) { size in
//            FolderCoverView(folder: MLFolder(collectionList: nil),
//                            uiMode: .modern,
//                            size: size)
//                .environmentObject(MLPhotoData())
//        }
//        CellView(uiMode: .fancy,
//                 cellType: .folder,
//                 title: "Fancy 폴더",
//                 index: 0,
//                 width: 100) { size in
//            FolderCoverView(folder: MLFolder(collectionList: nil),
//                            uiMode: .fancy,
//                            size: size)
//                .environmentObject(MLPhotoData())
//        }
//    }
//}

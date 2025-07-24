//
//  UnfoldableListLayout.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 4/11/25.
//

import SwiftUI
import Photos

struct UnfoldableListLayout<Content: View>: View {
    @EnvironmentObject var photoData: MLPhotoData
    let content: (_ proxy: ScrollViewProxy) -> Content
    let pageIdentifier: String
    let isUnfolded: Bool
    let screenWidth: CGFloat
    let widthOfContent: CGFloat
    let lineCount: Int
    
    init(content: @escaping (ScrollViewProxy) -> Content,
         pageIdentifier: String,
         isUnfolded: Bool,
         screenWidth: CGFloat,
         widthOfContent: CGFloat,
         lineCount: Int) {
        self.content = content
        self.pageIdentifier = pageIdentifier
        self.isUnfolded = isUnfolded
        self.screenWidth = screenWidth
        self.widthOfContent = widthOfContent
        self.lineCount = lineCount
    }
    
    var body: some View {
        let pageFolder = photoData.folders[pageIdentifier]
        let spacing = (screenWidth - 5.0 - (CGFloat(listCount) * widthOfContent)) / CGFloat(listCount)
        let column = Array(
            repeating: GridItem(.fixed(widthOfContent),
                                spacing: isUnfolded ? spacing : 10),
            count: isUnfolded ? listCount : lineCount
        )
        return ScrollViewReader(content: { proxy in
            ScrollView(.horizontal, showsIndicators: false, content: {
                LazyVGrid(columns: column)  {
                        content(proxy)
                }
                .id("albumViewEdge")
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background {
                    Color.red
                }
//                .padding(.all, 10)
//                    .padding(.trailing, 5)
            })
            .scrollDisabled(isUnfolded)
            .onChange(of: pageFolder?.albumsArray.count ?? 0) {
                [oldValue = pageFolder?.albumsArray.count ?? 0] newValue in
                if oldValue < newValue && !isUnfolded {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.interactiveSpring()) {
                            proxy.scrollTo(
                                pageFolder?.albumsArray.last?.localIdentifier ?? "albumViewEdge",
                                anchor: .bottomTrailing)
                        }
                    }
                }
            }
        })
    }
}

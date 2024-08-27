//
//  SectionView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/11/30.
//

import SwiftUI

struct SectionView: View {
    var sectionType: CellType
    var uiMode: UIMode = .fancy
    var collectionCount: Int
    @Binding var viewMode: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            let title = sectionType == .folder ? "폴더 리스트":"앨범 리스트"
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .fontWeight(.heavy)
            Text("(\(collectionCount)개)")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            // 앨범 리스트 펼쳐보기 / 한 줄 보기 버튼
            if sectionType == .album && collectionCount > listCount {
                titleText(viewMode ? "한줄 보기" : "펼쳐 보기",
                          font: .footnote,
                          color: .gray)
                    .onTapGesture {
                        DispatchQueue.global(qos: .userInteractive).async {
                            withAnimation(.interactiveSpring(
                                response: 0.35,
                                dampingFraction: 0.8,
                                blendDuration: 0)) {
                                self.viewMode.toggle()
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, 10)
        
    }
}

struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        SectionView(sectionType: .folder,
                    collectionCount: 10,
                    viewMode: .constant(false))
    }
}

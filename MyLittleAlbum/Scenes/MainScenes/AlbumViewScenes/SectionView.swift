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
    @Binding var isUnfolded: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            let title = sectionType == .folder ? "폴더 리스트" : "앨범 리스트"
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .fontWeight(.heavy)
            Text("(\(collectionCount)개)")
                .font(.footnote)
                .foregroundColor(.gray)
                .contentTransition(.numericText())
            Spacer()
            // 앨범 리스트 펼쳐보기 / 한 줄 보기 버튼
            if sectionType == .album && collectionCount > listCount {
                HStack(spacing: 5) {
                    Group {
                        if isUnfolded {
                            Text("한줄")
                        } else {
                            Text("펼쳐")
                        }
                    }
                    .transition(isUnfolded ? .flip : .flipReverse)
                    Text("보기")
                }
                .font(.footnote)
                .foregroundStyle(.gray)
                .onTapGesture {
                    DispatchQueue.global(qos: .userInteractive).async {
                        withAnimation(.interactiveSpring(
                            response: 0.35,
                            dampingFraction: 0.8,
                            blendDuration: 0)) {
                            self.isUnfolded.toggle()
                        }
                    }
                }
            }
        }
        .padding([.top, .horizontal], 10)
        .background {
            FancyBackground()
        }
    }
}

struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            FancyBackground()
            VStack {
                SectionView(sectionType: .album,
                            collectionCount: 10,
                            isUnfolded: .constant(false))
                SectionView(sectionType: .album,
                            collectionCount: 11,
                            isUnfolded: .constant(true))
                SectionView(sectionType: .folder,
                            collectionCount: 12,
                            isUnfolded: .constant(false))
            }
        }
    }
}

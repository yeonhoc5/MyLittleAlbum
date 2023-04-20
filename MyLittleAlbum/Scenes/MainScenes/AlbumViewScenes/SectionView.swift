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
    
    var body: some View {
        HStack(alignment: .center) {
            let title = sectionType == .folder ? "폴더 리스트":"앨범 리스트"
            Text(title).font(.headline).foregroundColor(.white).fontWeight(.heavy)
            Text("(\(collectionCount)개)").font(.footnote).foregroundColor(.gray)
            Spacer()
        }
    }
}

struct SectionView_Previews: PreviewProvider {
    static var previews: some View {
        SectionView(sectionType: .folder, collectionCount: 10)
            .background(Color.fancyBackground)
    }
}

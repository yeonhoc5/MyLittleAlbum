//
//  AlbumLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/29.
//

import SwiftUI

struct AlbumLineView: View {
    let albumType: AlbumType
    let title: String!
    let subText: String
    let selected: Bool
    
    init(albumType: AlbumType,
         title: String!,
         subText: String!,
         selected: Bool) {
        self.albumType = albumType
        self.title = title
        self.subText = subText
        self.selected = selected
    }
    
    var body: some View {
        HStack {
            Image(systemName: "photo.stack")
                .imageScale(.large)
                .frame(width: 20)
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.white)
                Text(title)
            }
            if subText != "" {
                Spacer()
                Text(subText)
                    .font(.footnote)
                    .foregroundColor(.disabledColor)
            }
        }
    }
}
struct AlbumLineView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumLineView(albumType: .album,
                      title: "마이 리틀 앨범",
                      subText: "[현재 앨범]",
                      selected: false)
    }
}

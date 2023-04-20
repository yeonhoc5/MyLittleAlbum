//
//  NoCollectionPhotoView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/16.
//

import SwiftUI

struct NoCollectionPhotoView: View {
    var selectedType: CollectionType = .none
    var type: CollectionType = .none
    var body: some View {
        let size = screenSize.width / 2
        imageScaledFill("noCollectionPhoto", width: size, height: size)
            .scaleEffect((type == .album || type == .folder) ? 1 : (selectedType == .album ? 1 : (selectedType == .folder ? 1.5 : 2.7)))
            .offset(x: (type == .album || type == .folder) ? 0 : (selectedType == .album ? 0 : (selectedType == .folder ? 30 : 65)),
                    y: (type == .album || type == .folder) ? 0 : (selectedType == .album ? 0 : (selectedType == .folder ? 10 : 45)))
            .mask {
                Circle()
                    .frame(width: size, height: size)
            }
            .shadow(color: .black, radius: 3, x: 0, y: 0)
    }
}

struct NoCollectionPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        NoCollectionPhotoView(type: .album)
    }
}

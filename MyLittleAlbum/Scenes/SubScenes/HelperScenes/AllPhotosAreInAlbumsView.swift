//
//  AllPhotosAreInAlbumsView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/08.
//

import SwiftUI

struct AllPhotosAreInAlbumsView: View {
    var body: some View {
        ZStack {
            FancyBackground()
            Image("arrangeKing")
                .resizable()
                .scaledToFit()
                .opacity(0.9)
        }
    }
}

struct AllPhotosAreInAlbumsView_Previews: PreviewProvider {
    static var previews: some View {
        AllPhotosAreInAlbumsView()
    }
}

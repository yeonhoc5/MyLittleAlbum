//
//  RefreshPhotoView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/16.
//

import SwiftUI

struct RefreshPhotoView: View {
    var sentence = "you need a Little Refresh time"
    var body: some View {
        Rectangle()
            .foregroundColor(.fancyBackground)
            .overlay {
                VStack(spacing: 20) {
                    Text(sentence)
                        .foregroundColor(.white)
                    let size = screenSize.width / 2
                    let refreshiPhoto = refreshPhotos[Int.random(in: 0..<refreshPhotos.count)]
                    imageScaledFit(refreshiPhoto, width: size, height: size)
                        .shadow(color: .white.opacity(0.12), radius: 7, x: 0, y: 0)
                }
            }
            .ignoresSafeArea()
    }
}

struct RefreshPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshPhotoView()
    }
}

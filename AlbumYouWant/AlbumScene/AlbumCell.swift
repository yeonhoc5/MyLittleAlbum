//
//  AlbumCell.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/28.
//

import SwiftUI

struct AlbumCell: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .border(Color.secondary)
                .frame(width: 60, height: 45)
                .rotationEffect(Angle.degrees(4))
                .padding(.bottom, 4)
            Rectangle()
                .fill(Color.white)
                .border(Color.secondary)
                .frame(width: 60, height: 45)
                .rotationEffect(Angle.degrees(-4))
            Image("sample")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 45)
                .border(Color.white, width: 4)
                .clipped()
                .foregroundColor(.gray)
            Rectangle()
                .fill(Color.white.opacity(0))
                .border(Color.secondary)
                .frame(width: 60, height: 45)
        }
        .padding(.top, 5)
    }
}

struct AlbumCell_Previews: PreviewProvider {
    static var previews: some View {
        AlbumCell()
    }
}

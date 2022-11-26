//
//  AlbumCell.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/28.
//

import SwiftUI

struct AlbumCell: View {
    var width: CGFloat = 60
    var height: CGFloat = 45
    let emptyLabel: String = "빈 앨범"
    var image: String!
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .border(Color.secondary)
                .frame(width: width, height: height)
                .rotationEffect(Angle.degrees(4))
                .padding(.bottom, 4)
            if image == nil {
                Text(emptyLabel)
                    .font(.caption)
                    .foregroundColor(.primaryColorInvert.opacity(0.7))
                    .frame(width: width, height: height)
                    .background(Color.white)
                    .border(Color.white, width: 4)
                    .overlay {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: width * 0.9, height: height * 0.9)
                            .border(Color.gray, width: 0.4).opacity(0.8)
                    }
            } else {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .border(Color.white, width: 4)
                    .clipped()
                    .foregroundColor(.gray)
            }
            Rectangle()
                .fill(Color.white.opacity(0))
                .border(Color.secondary)
                .frame(width: width, height: height)
        }
        .padding(.top, 5)
    }
}

struct AlbumCell_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            AlbumCell()
            AlbumCell(image: "sample")
        }
    }
}

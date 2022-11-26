//
//  CellView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

enum CellType {
    case folder, album
}

struct CellView: View {
    var title: String = "depth"
    var color: Color! = .orange
    var cellType: CellType
    var image: String!
    var width: CGFloat! = 60
    var height: CGFloat! = 40
    
    var body: some View {
        
        VStack(spacing: 0) {
                
            if cellType == .folder {
                ZStack(alignment: .bottom) {
                    Image(systemName: "folder.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 50)
                        .foregroundColor(color)
                    Text("3 / 4")
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 10, alignment: .trailing)
                        .padding([.bottom, .trailing], 10)
                }
            } else {
                AlbumCell(width: width, height: height)
            }
                
            Text(title)
                .font(.caption)
                .foregroundColor(color)
                .bold()
                .controlSize(.mini)
                .truncationMode(.tail)
                .padding(.top, 5)
                .frame(width: width, height: height * 0.3)
                .truncationMode(.tail)
        }
    }
    
}

struct CellView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CellView(title: "단양여행", color: .orange, cellType: .folder)
            CellView(title: "단양여행", color: .black, cellType: .album, image: "sample")
            CellView(title: "단양여행", color: .black, cellType: .album)
        }
    }
}

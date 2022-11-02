//
//  PhotoView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI

struct PhotoView: View {
    var color: Color
    
    var body: some View {
        ZStack(alignment: .bottom, content: {
            ScrollView(.vertical, content: {
                VStack(spacing: 1) {
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                    CollectionRowView(color: color)
                }
            })
                .ignoresSafeArea(.all)
            PhotoMenu()
                .padding(.bottom, 30)
        })
    }
}

struct CollectionRowView: View {
    var color: Color
    var body: some View {
        HStack(spacing: 1){
            
            PhotoCell(color: color)
            PhotoCell(color: color)
            PhotoCell(color: color)
            PhotoCell(color: color)
            PhotoCell(color: color)
            
        }
    }
}

struct PhotoView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoView(color: .orange)
    }
}



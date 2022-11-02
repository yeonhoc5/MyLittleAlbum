//
//  CollectionLineView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

struct CollectionLineView: View {
    
    var color: Color
    @State var showingLine: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            sectionView
            CustomDivider(color: .secondary)
            
            if showingLine {
                ScrollView(.horizontal, showsIndicators: false, content: {
                    HStack(alignment: .top, spacing: 10) {
                        CellView(title: "9월", color: color, cellType: .folder)
                        CellView(title: "10월", color: color, cellType: .folder)
                        CellView(title: "수목원", cellType: .album)
                        CellView(title: "강화도", cellType: .album)
                        CellView(title: "수원", cellType: .album)
                        CellView(title: "제주도", cellType: .album)
                        CellView(title: "춘천", cellType: .album)
                    }
                    .padding([.leading, .trailing], 15)
                })

            }
        }
        .padding(.bottom, 15)
        .animation(Animation.easeInOut(duration: 0.2), value: showingLine)
    }
    
    var sectionView: some View {
        HStack {
            Button(action: { showingLine.toggle() }) {
                HStack {
                    Text("2022년")
                        .foregroundColor(color)
                        .fontWeight(.heavy)
                        .padding(.leading)
                    Text("(2 / 5)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .fontWeight(.bold)
                    Spacer()
                }
            }
            .buttonStyle(CusotmeBtnStyle())
            
            Button(action: { }) {
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 15)
            .buttonStyle(CusotmeBtnStyle(scale: 0.8))
        }
    }
    
    
}

struct CollectionLineView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionLineView(color: .purple)
    }
}

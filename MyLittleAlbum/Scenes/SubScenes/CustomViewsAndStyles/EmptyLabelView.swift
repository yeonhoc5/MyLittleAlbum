//
//  EmptyView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/19.
//

import SwiftUI

struct EmptyLabelView: View {
    let text = emptyLabel[Int.random(in: 0..<emptyLabel.count)]
    var body: some View {
        Text(text)
            .font(.title)
            .foregroundColor(.secondary).opacity(0.15)
            .frame(height: 100)
    }
}

struct EmptyLabelView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyLabelView()
    }
}

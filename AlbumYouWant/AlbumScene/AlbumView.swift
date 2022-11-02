//
//  AlbumView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI

struct AlbumView: View {
    var title: String
    var color: Color
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CollectionLineView(color: color)
                CollectionLineView(color: color)
                CollectionLineView(color: color)
                CollectionLineView(color: color)
                CollectionLineView(color: color)
                CollectionLineView(color: color)
                CollectionLineView(color: color)
            }
            .animation(Animation.default)
        }
    }
}

struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView(title: "my Album", color: .orange)
    }
}

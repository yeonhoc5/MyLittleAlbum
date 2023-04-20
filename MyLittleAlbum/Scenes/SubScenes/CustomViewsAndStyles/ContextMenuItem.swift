//
//  ContextMenuItem.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/04.
//

import SwiftUI

struct ContextMenuItem: View {
    var title: String! = ""
    var image: String! = ""
    var color: Color! = .primary
    var body: some View {
        if image == "" {
            Text(title)
                .foregroundColor(color)
        } else {
            HStack {
                Text(title)
                imageWithScale(systemName: image, scale: .medium)
            }
            .foregroundColor(color)
        }
    }
}

struct ContextMenuItem_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuItem()
    }
}

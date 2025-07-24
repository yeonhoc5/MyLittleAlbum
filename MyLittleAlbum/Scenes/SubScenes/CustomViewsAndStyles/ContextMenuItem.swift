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
    var color: Color! = .white
    var body: some View {
        Group {
            if image == "" {
                Text(title)
            } else {
                HStack {
                    Text(title)
                    imageWithScale(
                        systemName: image,
                        scale: .medium)
                    
                }
            }
        }
    }
}

struct ContextMenuItem_Previews: PreviewProvider {
    static var previews: some View {
        ContextMenuItem()
    }
}

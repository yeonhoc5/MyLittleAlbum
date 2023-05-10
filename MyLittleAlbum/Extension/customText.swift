//
//  customText.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/16.
//

import SwiftUI

extension View {
    
    func titleText(_ text: String, font: Font, color: Color, inline: Bool! = false) -> some View {
        VStack(alignment: .leading) {
            if !inline {
                if text.first! != "("
                    && text.last! == ")"
                    && text.filter({ $0 == "(" }).count == 1 {
                    Text(text.split(separator: "(")[0])
                        .lineLimit(1, reservesSpace: false)
                    Text("(" + text.split(separator: "(")[1])
                        .lineLimit(1, reservesSpace: false)
                } else if text.first! == "("
                            && text.last != ")"
                            && text.filter({ $0 == ")" }).count == 1 {
                    Text(text.split(separator: ")")[0] + ")")
                        .lineLimit(1, reservesSpace: false)
                    Text(text.split(separator: ")")[1])
                        .lineLimit(1, reservesSpace: false)
                } else {
                    Text(text)
                }
            } else {
               Text(text)
            }
        }
        .font(font)
        .foregroundColor(color)
    }
    
    
    func spacerRectangle(color: Color, height: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}

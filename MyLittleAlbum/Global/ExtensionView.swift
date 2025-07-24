//
//  ExtensionView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2/24/25.
//

import SwiftUI

extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
            return modifier(self)
        }
    
    func spacerRectangle(color: Color, height: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}
// text
extension View {
    func titleText(_ text: String, font: Font, color: Color, inline: Bool! = false) -> some View {
        VStack(alignment: .leading) {
            if !inline && text != "" {
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
}

// imageScaled
extension View {
    func imageScaledFill(_ name: String, width: CGFloat, height: CGFloat, radius: CGFloat! = 0) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
            .cornerRadius(radius)
    }
    
    func imageScaledFill(systemName: String, width: CGFloat, height: CGFloat, radius: CGFloat! = 0) -> some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
            .cornerRadius(radius)
    }
    @ViewBuilder
    func imageScaledFill(uiImage: UIImage, width: CGFloat, height: CGFloat, radius: CGFloat! = 0,
                         cornerTopL: Bool! = true, cornerBottomL: Bool! = true,
                         cornerBottomT: Bool! = true, cornerTopT: Bool! = true) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: abs(width), height: abs(height))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerTopL ? radius : 0,
                    bottomLeadingRadius: cornerBottomL ? radius : 0,
                    bottomTrailingRadius: cornerBottomT ? radius : 0,
                    topTrailingRadius: cornerTopT ? radius : 0,
                    style: .continuous))
//            .clipped()
//            .cornerRadius(radius)
    }
    
    func imageScaledFit(_ name: String, width: CGFloat, height: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }
    
    func imageScaledFit(systemName: String, width: CGFloat, height: CGFloat) -> some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
    }
    
    func imageNonScaled(systemName: String, width: CGFloat, height: CGFloat, color: Color) -> some View {
        Image(systemName: systemName)
            .resizable()
            .foregroundColor(color)
            .frame(width: width, height: height)
    }
    
    func imageWithScale(systemName: String, scale: Image.Scale = .medium) -> some View {
        Image(systemName: systemName)
            .imageScale(scale)
    }
}

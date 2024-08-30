//
//  ScaledImage.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/11/28.
//

import SwiftUI

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
    func imageScaledFill(uiImage: UIImage?, width: CGFloat, height: CGFloat, radius: CGFloat! = 0) -> some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(radius)
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

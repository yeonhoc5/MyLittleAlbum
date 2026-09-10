//
//  DepthCircle.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/21.
//

import SwiftUI

struct DepthArrow: View {
    // 폴더의 Depth * 동그라미 개수
    var folded: Bool = false
    var isSelected: Bool = false
    var count: Int = 1
    let subCount: Int
    
    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<(count-(subCount > 0 ? 1 : 0)), id: \.self) { _ in
                Color.clear
                    .frame(width: 20, height: 20)
            }
            if subCount > 0 {
                imageScaledFit(systemName: "arrowtriangle.right.fill",
                               width: 10, height: 10)
                .foregroundColor(.blue)
                .padding(5)
                .shadow(color: .gray, radius: 1, x: 1, y: 1)
                .rotationEffect(folded ? .zero : Angle(degrees: 90))
            }
        }
        .background {
            Color.white
        }
    }
}

struct DepthCircle_Previews: PreviewProvider {
    static var previews: some View {
        DepthArrow(count: 4, subCount: 1)
    }
}

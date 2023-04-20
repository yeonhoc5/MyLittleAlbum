//
//  DepthCircle.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/21.
//

import SwiftUI

struct DepthCircle: View {
    // 폴더의 Depth * 동그라미 개수
    var count: Int = 1
    var body: some View {
        HStack {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .foregroundColor(.disabledColor)
                    .padding(8)
                    .frame(width: 20, height: 20)
            }
        }
    }
}

struct DepthCircle_Previews: PreviewProvider {
    static var previews: some View {
        DepthCircle(count: 4)
    }
}

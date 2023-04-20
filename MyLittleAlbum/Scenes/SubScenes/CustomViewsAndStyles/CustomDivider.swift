//
//  CustomDivider.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/27.
//

import SwiftUI

struct CustomDivider: View {
    let color: Color?
    
    var body: some View {
        Rectangle()
            .frame(height: 0.7)
            .foregroundColor(color)
            .padding(.leading, 15)
            .padding(.bottom, 5)
    }
}

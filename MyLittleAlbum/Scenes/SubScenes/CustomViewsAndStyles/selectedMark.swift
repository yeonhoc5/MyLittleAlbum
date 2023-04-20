//
//  selectedMark.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/03.
//

import SwiftUI

struct selectedMark: View {
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(.white)
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(.blue)
                .bold()
                .padding(1.5)

        }
        .frame(width: 20, height: 20)
//        .background(Color.blue)
    }
}

struct selectedMark_Previews: PreviewProvider {
    static var previews: some View {
        selectedMark()
    }
}

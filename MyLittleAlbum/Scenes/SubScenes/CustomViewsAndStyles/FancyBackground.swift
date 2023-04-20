//
//  FancyBackground.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/25.
//

import SwiftUI

struct FancyBackground: View {
    var body: some View {
        Color.fancyBackground
            .ignoresSafeArea()
    }
}

struct FancyBackground_Previews: PreviewProvider {
    static var previews: some View {
        FancyBackground()
    }
}

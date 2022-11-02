//
//  PhotoCell.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI

struct PhotoCell: View {
    var color: Color
    
    var body: some View {
        let size = UIScreen.main.bounds.width / 5
        color
            .frame(width: size, height: size)
            
    }
}

struct PhotoCell_Previews: PreviewProvider {
    static var previews: some View {
        PhotoCell(color: .orange)
    }
}

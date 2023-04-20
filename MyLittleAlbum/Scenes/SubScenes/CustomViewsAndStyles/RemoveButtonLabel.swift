//
//  RemoveButtonLabel.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/24.
//

import SwiftUI

enum ShapeTypes {
    case rectangle, circle
}

struct RemoveButtonLabel: View {
    var width: Double = 20
    var shapeType: ShapeTypes = .rectangle
    
    var body: some View {
        let frontImage = shapeType == .rectangle ? "minus.rectangle.fill":"minus.circle.fill"
        let backImage = shapeType == .rectangle ? "rectangle.fill":"circle.fill"
        ZStack {
            Image(systemName: backImage)
                .resizable()
                .foregroundColor(.white)
            Image(systemName: frontImage)
                .resizable()
                .foregroundColor(.red)
        }
        .frame(width: width, height: width)
        .clipped()
        .shadow(color: .black.opacity(0.5), radius: 0.1, x: 0.2, y: 0.2)
    }
}

struct RemoveButton_Previews: PreviewProvider {
    static var previews: some View {
        RemoveButtonLabel()
    }
}

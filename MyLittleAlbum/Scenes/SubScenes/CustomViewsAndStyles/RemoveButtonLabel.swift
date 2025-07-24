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
    var isProcessing: Bool = false
    
    var body: some View {
        let backImage = shapeType == .rectangle ? "square.fill":"circle.fill"
        ZStack {
            Image(systemName: backImage)
                .resizable()
                .foregroundColor(.red)
            if isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.mini)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "minus")
                    .foregroundColor(.white)
            }
        }
        .frame(width: width, height: width)
        .clipped()
        .shadow(color: .black.opacity(0.5),
                radius: 1, x: 0.2, y: 0.2)
    }
}

struct RemoveButton_Previews: PreviewProvider {
    static var previews: some View {
        RemoveButtonLabel()
    }
}

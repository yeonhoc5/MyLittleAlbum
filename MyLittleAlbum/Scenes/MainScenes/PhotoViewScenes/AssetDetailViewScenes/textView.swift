//
//  textView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 9/9/25.
//

import SwiftUI

struct textView: View {
@State var scale: CGFloat = 1.0
@State var isTapped: Bool = false
var body: some View {
    GeometryReader {reader in
        Image("sampleImage04")
            .resizable()
            .scaledToFit()
            .position(x: reader.frame(in: .local).midX,
                      y: reader.frame(in: .local).midY)
            .scaleEffect(self.scale)
            .scaleEffect(self.isTapped ? 2 : 1, anchor: UnitPoint(x: 0, y: 0))
            .gesture(TapGesture(count: 2)
                .onEnded ({
                    self.isTapped = !self.isTapped
                })
                    .simultaneously(with:
                                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { (value) in
//                            print(value.startLocation)
                        })
                        .onEnded ({ value in
//                            print(value)
                        })
                     )
            .gesture (MagnificationGesture()
                .onChanged{ scale in
                       self.scale = scale.magnitude
    }
    .onEnded({ scaleFinal in
        self.scale = scaleFinal.magnitude
    }))
        }
    }
}
#Preview {
    textView()
}

//
//  ImageVolumeView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 5/1/25.
//

import SwiftUI

struct ImageVolumeView: View {
    @EnvironmentObject var photoData: MLPhotoData
    var body: some View {
        let assets = (photoData.homeAlbum?.frObject(isHidden: false) ?? [])
            .sorted(by: { $0.creationDate > $1.creationDate })
//            .sorted(by: { $0.volume > $1.volume }) ?? []
        List(0..<10) { index in
            let asset = assets[index]
            HStack {
                Text("\(asset.volume)")
            }
        }
    }
}

#Preview {
    ImageVolumeView()
}

//
//  shareLink.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/31.
//

import SwiftUI
import Photos

struct shareLink: View {
    let assetToShare: [String] = []
    
    var body: some View {
        shareButton
    }
    
    
    var shareButton: some View {
        print("shared")
        return ShareLink(items: assetToShare) { _ in
            SharePreview("\(assetToShare.count)개의 항목이 선택됨", image: assetToShare.first!)
        } label: { Text("공유하기") }
    }
}

struct shareLink_Previews: PreviewProvider {
    static var previews: some View {
        shareLink()
    }
}

//
//  FolderLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/29.
//

import SwiftUI

struct FolderLineView: View {
    let title: String!
    let subText: String!
    var isOpen: Bool! = false
    
    var body: some View {
        HStack {
            Image(systemName: isOpen ? "folder" : "folder.fill")
                .imageScale(.large)
                .frame(width: 20)
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.white)
                Text(title)
                    .frame(height: 30)
                    .truncationMode(.tail)
            }
            if subText != nil {
                Spacer()
                Text(subText)
                    .font(.footnote)
                    .foregroundColor(.disabledColor)
            }
        }
    }
}

struct FolderLineView_Previews: PreviewProvider {
    static var previews: some View {
        FolderLineView(title: "마이 리틀 앨범", subText: "[현재 폴더]")
    }
}

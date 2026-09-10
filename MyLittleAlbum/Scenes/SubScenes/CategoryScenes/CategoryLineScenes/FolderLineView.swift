//
//  FolderLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/29.
//

import SwiftUI

struct FolderLineView: View {
    let isCollectionMoveView: Bool
    let title: String!
    let subImage: String!
    var isSelected: Bool = false
    let albumEmpty: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(.white)
            HStack(spacing: 7) {
                Image(systemName: "folder.fill")
                    .imageScale(.large)
                    .frame(width: 20)
                HStack(alignment:.lastTextBaseline, spacing: 2) {
                    Text(title)
                        .frame(height: 30)
                        .truncationMode(.tail)
                        .background {
                            Color.white
                        }
                        .zIndex(1)
                    if !isCollectionMoveView {
                        if isSelected {
                            Group {
                                if albumEmpty {
                                    Text("에는 앨범이 없습니다.")
                                } else {
                                    Text("의 앨범리스트")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fontWeight(.light)
                            .transition(.move(edge: .leading)
                                        .combined(with: .opacity))
                        }
                    }
                }
                Spacer()
                if subImage != nil {
                    imageScaledFit(systemName: subImage,
                                   width: 15,
                                   height: 15)
                        .font(.footnote)
                        .foregroundColor(.disabledColor)
                }
                if isCollectionMoveView && isSelected {
                    imageScaledFit(systemName: "checkmark",
                                   width: 20,
                                   height: 20)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                }
            }
            .foregroundStyle(isSelected ? .blue : .black)
        }
    }
}

struct FolderLineView_Previews: PreviewProvider {
    static var previews: some View {
        FolderLineView(isCollectionMoveView: true,
                       title: "마이 리틀 앨범",
                       subImage: nil,
                       isSelected: true,
                       albumEmpty: true)
    }
}

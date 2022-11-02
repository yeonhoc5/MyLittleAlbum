//
//  PhotoMenu.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI

struct PhotoMenu: View {
    @State var selectMode: Bool = true
    
    var body: some View {
        let size = UIScreen.main.bounds.width / 10
            
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(
                        selectMode ? .primary.opacity(0):Color.gray.opacity(0.7)
                    )
                    .frame(width: size, height: 40)
                    .overlay(
                        selectMode ? nil : Button { } label: {
                        Text("전체 선택")
                            .font(.caption).foregroundColor(.black)
                    })
                    .padding(.leading, 20)
                
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(Color.gray.opacity(0.7))
                    .frame(height: 40)
                    .overlay {
                        Text(selectMode ? "사진 : 100, 동영상: 100":"0개의 항목 선택됨")
                    }
                    
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(Color.gray.opacity(0.7))
                    .frame(width: size,
                           height: 40)
                    .overlay {
                        Button { self.selectMode.toggle() } label: {
                            Text(selectMode ? "선택":"취소")
                                .font(.caption).foregroundColor(.black)
                        }
                    }
                    .padding(.trailing, 20)
        }
    }
}

struct PhotoMenu_Previews: PreviewProvider {
    static var previews: some View {
        PhotoMenu(selectMode: true)
    }
}

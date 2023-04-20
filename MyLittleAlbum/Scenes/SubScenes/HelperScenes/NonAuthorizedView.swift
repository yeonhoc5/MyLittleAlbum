//
//  NonAuthorizedView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/03/23.
//

import SwiftUI

struct NonAuthorizedView: View {
    var body: some View {
        Rectangle()
            .fill(Color.fancyBackground)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
//                        myLittleAlbum
                        HStack {
                            coloredText("\"MY LITTLE ALBUM\"",
                                        color: .white)
                            Text("은")
                        }
                        Text("아이폰의 자체 \"사진\" 앱과 연동하는 앱으로서,\n사용자의 폴더 / 앨범 / 사진 정보를 보여주기 위해")
                        HStack(alignment: .center) {
                            Text("사용자 앨범에 대한")
                            coloredText("\"모든 사진\"", color: .white)
                            Text("권한이 필요합니다.")
                        }
                    }
                    .foregroundColor(Color.gray)
                    .font(Font.system(size: 15))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(10)
                    .font(Font.system(size: 15))
                    Text("\"MY LITTLE ALBUM\"은\n사용자의 어떠한 정보도 저장하지 않습니다.")
                        .foregroundColor(.fancyBackground)
                        .font(Font.system(size: 15, weight: .semibold))
                        .kerning(0.4)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(10)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    Button("권한 설정하러 가기") {
                        UIApplication.shared.open(URL(string: "app-settings:root")!)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                }
            }
    }
    
    var myLittleAlbum: some View {
        HStack(spacing: 0) {
            Group {
                coloredText("M", color: .color1)
                coloredText("Y", color: .color2)
            }
            Text("  ")
            Group {
                coloredText("L", color: .color3)
                coloredText("I", color: .color12)
                coloredText("T", color: .color4)
                coloredText("T", color: .color6)
                coloredText("L", color: .color7)
                coloredText("E", color: .color8)
            }
            Text("  ")
            Group {
                coloredText("A", color: .color9)
                coloredText("L", color: .color10)
                coloredText("B", color: .color11)
                coloredText("U", color: .color5)
                coloredText("M", color: .color13)
            }
            Text(" 은")
                .foregroundColor(.gray)
        }
    }
    
    func coloredText(_ capital: String, color: Color) -> some View {
        Text(capital)
            .bold()
            .foregroundColor(color)
    }
    
}

struct NonAuthorizedView_Previews: PreviewProvider {
    static var previews: some View {
        NonAuthorizedView()
    }
}

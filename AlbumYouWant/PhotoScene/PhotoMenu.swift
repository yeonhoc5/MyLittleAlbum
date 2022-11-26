//
//  PhotoMenu.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos

struct PhotoMenu: View {
    @State var isSelectMode: Bool = false
    @EnvironmentObject var photoData: PhotoData
    var allPhotos: PHFetchResult<PHAsset>!
    
    let width = UIScreen.main.bounds.width / 10
    let height: CGFloat = 40
    let opacity: CGFloat = 0.8
    let barColor: Color = Color.black.opacity(0.7)
    
    var body: some View {
        HStack(spacing: 10) {
            if isSelectMode {
                leftMenuBtn
            }
            centerMenuBar
            rightMenuBtn
        }
    }
    
    var leftMenuBtn: some View {
        colorBar(width: width, height: height)
            .overlay(
                Text("전체 선택")
                    .font(.caption)
                    .foregroundColor(.primaryColorInvert)
            )
            .padding(.leading, 20)
    }
    
    var centerMenuBar: some View {
        let countOfImage: Int = allPhotos.countOfAssets(with: .image)
        let countOfVideo: Int = allPhotos.countOfAssets(with: .video)
        return colorBar(height: height)
            .overlay {
                Text(isSelectMode ? "0개의 항목 선택됨":"사진 : \(countOfImage)  /  동영상 : \(countOfVideo)")
                    .fontWeight(.medium)
                    .foregroundColor(.primaryColorInvert)
            }
            .padding(.leading, isSelectMode ? 0: width + 30)
    }
        
    var rightMenuBtn: some View {
        colorBar(width: width, height: height)
            .overlay {
                Button { self.isSelectMode.toggle() } label: {
                    Text(isSelectMode ? "취소":"선택")
                        .font(.caption)
                        .foregroundColor(.primaryColorInvert)
                }
            }
            .padding(.trailing, 20)
    }
    
    func colorBar(width: CGFloat = .infinity, height: CGFloat) -> some View {
        Color.primary.opacity(0.6)
            .frame(width: width, height: height)
            .cornerRadius(height / 2)
    }
    
}

struct PhotoMenu_Previews: PreviewProvider {
    static var previews: some View {
        PhotoMenu(isSelectMode: true)
            .environmentObject(PhotoData())
    }
}

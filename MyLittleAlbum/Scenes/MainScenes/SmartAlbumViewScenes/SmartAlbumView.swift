//
//  SmarAlbumView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/03.
//

import SwiftUI
import Photos

struct SmartAlbumView: View {

    var smartAlbum: [SmartAlbum] = [.trashCan, .hiddenAsset]
    var smartAlbumTitle: [String] = ["최근 삭제한 항목", "가린 항목"]
    var smartAlbumImage: [String] = ["trash.fill", "eye.slash"]
    
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(0..<smartAlbum.count, id: \.self) { i in
                        NavigationLink {
                            AllPhotosView(albumType: .smartAlbum,
                                          isPrivacy: true,
                                          smartAlbum: smartAlbum[i],
                                          title: smartAlbumTitle[i])
                        } label: {
                            listRow(title: smartAlbumTitle[i],
                                    image: smartAlbumImage[i])
                        }
                        .listRowBackground(Color.white)
                        .foregroundColor(.fancyBackground)
                    }
                } footer: {
                    Text("애플(APPLE)의 정책에 의해,\n[사진] 앱의 설정에서 \"암호사용\" 또는 \"FaceID사용\"을 활성화 한 경우\n[사진] 앱을 제외한 기타 앱에서는 \"최근 삭제한 항목\"과 \"가린 항목\"을 볼 수 없습니다.")
                        .foregroundColor(.gray)
                        .font(Font.system(size: 11))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(7)
                        .padding(.vertical, 10)
                        .padding(.horizontal, -10)
                }
                
            }
            .listStyle(.insetGrouped)
            .listItemTint(.fancyBackground)
            .background(Color.fancyBackground)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("사진 관리")
        }
    }
    
    
}

extension SmartAlbumView {
    func listRow(title: String, image: String, asset: PHAssetMediaType! = nil) -> some View {
        HStack {
            imageScaledFit(systemName: image, width: 20, height: 20)
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(.white)
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}
    
struct SmarAlbumView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selection: .smart, isOpen: true).mainView
            .environmentObject(PhotoData())
    }
}

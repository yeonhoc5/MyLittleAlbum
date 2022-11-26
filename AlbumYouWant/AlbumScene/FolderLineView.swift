//
//  FolderLineView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/26.
//

import SwiftUI
import Photos

struct FolderLineView: View {
//    @EnvironmentObject var photoData: PhotoData
    var phCollection: PHCollectionList!
    @State private var secondaryFoldAndAlbm: PHFetchResult<PHCollection>!
    @State var secondaryFolders: [PHCollectionList]! = []
    @State var secondaryAlbums: [PHAssetCollection]! = []
    var title: String = ""
    @State private var showingLine: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            sectionView(title: title)
            CustomDivider(color: .secondary)
            if showingLine {
                secondaryListView
            }
        }
        .padding(.bottom, 5)
        .onAppear {
            // step0. 재진입시마다 반복되므로 우선 비워주기
            secondaryFolders = []
            secondaryAlbums = []
            // step1. phcolleciton을 [PHCollectionList]로 fetch
            secondaryFoldAndAlbm = PHCollection.fetchCollections(in: phCollection, options: nil)
            // step2. 세컨드 Depth 폴더와 앨범 분리하기
            (0..<secondaryFoldAndAlbm.count).forEach { index in
                if secondaryFoldAndAlbm[index].isKind(of: PHAssetCollection.self) {
                    secondaryAlbums.append(secondaryFoldAndAlbm[index] as! PHAssetCollection)
                } else {
                    secondaryFolders.append(secondaryFoldAndAlbm[index] as! PHCollectionList)
                }
            }
        }
    }
    
    func sectionView(title: String) -> some View {
        HStack {
            Group {
                Text(title)
                    .foregroundColor(.orange)
                    .fontWeight(.heavy)
                    .padding(.leading)
                Text("(\(secondaryFolders.count) / \(secondaryAlbums.count))")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                Spacer()
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showingLine.toggle()
                }
            }
            
            Button(action: { }) {
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 15)
            .buttonStyle(CusotmeBtnStyle(scale: 0.8))
        }
    }
    
    var secondaryListView: some View {
        ScrollView(.horizontal, showsIndicators: false, content: {
            HStack(alignment: .top, spacing: 10) {
                ForEach(0..<secondaryFolders.count, id: \.self) { index in
                    let folder = secondaryFolders[index]
                    CellView(title: "\(folder.localizedTitle ?? "")", cellType: .folder)
                }
                ForEach(0..<secondaryAlbums.count, id: \.self) { index in
                    let album = secondaryAlbums[index]
                    CellView(title: "\(album.localizedTitle ?? "")", cellType: .album)
                }
            }
            .padding([.leading, .trailing], 15)
        })
    }
    
}

struct FolderLineView_Previews: PreviewProvider {
    static var previews: some View {
        FolderLineView()
            .environmentObject(PhotoData())
    }
}

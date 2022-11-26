//
//  AlbumListView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/23.
//

import SwiftUI
import Photos

struct AlbumListView: View {
    @EnvironmentObject var photoData: PhotoData
    var depthAlbums: [PHAssetCollection] = []
//    var color: Color
    @State var modeOfAlbumList: Bool = true
    
    var body: some View {
        let column = Array(repeating: GridItem(.flexible(), spacing: 5, alignment: .leading), count: 5)
        VStack {
            sectionView
            if modeOfAlbumList {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(0..<depthAlbums.count, id: \.self) { index in
                            let album: PHAssetCollection = depthAlbums[index]
                            let allPhotos = fetchAsset(phassetCollection: album)
                            let title = String(album.localizedTitle ?? "")
                            NavigationLink(destination: PhotoView(allPhotos: allPhotos)) {
                                CellView(title: title, cellType: .album, image: "sample", width: 60, height: 40)
                                    .scaledToFit()
                            }
                        }
                    }
                }
                .padding(.leading, 10)

            } else {
                LazyVGrid(columns: column, alignment: .center, spacing: 10) {
                    ForEach(0..<depthAlbums.count, id: \.self) { index in
                        let album: PHAssetCollection = depthAlbums[index]
                        let allPhotos = fetchAsset(phassetCollection: album)
                        let title = String(album.localizedTitle ?? "")
                        NavigationLink(destination: PhotoView(allPhotos: allPhotos)) {
                            CellView(title: title, cellType: .album, image: "sample", width: 60, height: 40)
                                .scaledToFit()
                        }
                    }
                }
                .padding(.leading, 10)
            }
            
        }
        .padding()
    }
    
    func fetchAsset(phassetCollection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(in: phassetCollection, options: nil)
    }
    
    var sectionView: some View {
        let text = modeOfAlbumList ? "펼쳐보기":"한줄보기"
        return HStack {
            Group {
                Text("앨범 리스트")
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
//                    .padding(.leading)
                Text("(\(depthAlbums.count)개)")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                Spacer()
                Text(text)
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.modeOfAlbumList.toggle()
                        }
                    }
            }
        }
    }
}

struct AlbumListView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumListView()
            .environmentObject(PhotoData())
    }
}

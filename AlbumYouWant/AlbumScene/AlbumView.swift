//
//  AlbumView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/13.
//

import SwiftUI
import Photos

struct AlbumView: View {
    @EnvironmentObject var photoData: PhotoData
    @State var depthFoldAndAlbm: PHFetchResult<PHCollection>!
    @State var depthFolders: [PHCollectionList]! = []
    @State var depthAlbums: [PHAssetCollection]! = []
    var isHome: Bool! = true
    
    
    
    var title: String! = ""
    var color: Color! = .orange
    
    var body: some View {
        ScrollView {
            AlbumListView(depthAlbums: depthAlbums)
            FolderListView(depthFolders: depthFolders)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                editBarButton
            }
        }
        .onAppear {
            depthAlbums = []
            depthFolders = []
            if isHome {
                depthFoldAndAlbm = photoData.topLevelCollection
            }
            (0..<depthFoldAndAlbm.count).forEach { index in
                if depthFoldAndAlbm[index].isKind(of: PHAssetCollection.self) {
                    depthAlbums.append(depthFoldAndAlbm[index] as! PHAssetCollection)
                } else {
                    depthFolders.append(depthFoldAndAlbm[index] as! PHCollectionList)
                }
            }
        }
    }
}

extension AlbumView {
    var editBarButton: some View {
        Button { } label: {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.gray)
        }
    }
}


struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView()
            .environmentObject(PhotoData())
    }
}

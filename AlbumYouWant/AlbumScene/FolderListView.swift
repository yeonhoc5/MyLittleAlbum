//
//  CollectionLineView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI
import Photos

struct FolderListView: View {
    
    @EnvironmentObject var photoData: PhotoData
    var depthFolders: [PHCollectionList]! = []
    @State var secDepthFolders: [PHCollectionList]! = []
    @State var secDepthAlbums: [PHAssetCollection]! = []
    @State var showingLine: Bool = true
    var color: Color! = .orange
    
    var body: some View {
        VStack {
            sectionView
                .padding(.bottom, 5)
            
            ForEach(0..<depthFolders.count, id: \.self) { index in
                let folder = depthFolders[index]
                FolderLineView(phCollection: folder, title: "\(folder.localizedTitle ?? "")")
            }
            .padding(.leading, 10)
        }
    }
    
    var sectionView: some View {
        HStack {
            Group {
                Text("폴더 리스트").foregroundColor(.primary).fontWeight(.heavy)
                Text("(\(depthFolders.count)개)").font(.footnote).foregroundColor(.gray).fontWeight(.bold)
                Spacer()
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showingLine.toggle()
                }
            }
        }
        .padding([.horizontal, .top])
    }
}

struct CollectionLineView_Previews: PreviewProvider {
    static var previews: some View {
        FolderListView()
            .environmentObject(PhotoData())
    }
}

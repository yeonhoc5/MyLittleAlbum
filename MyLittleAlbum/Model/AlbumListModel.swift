//
//  AlbumListModel.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/13.
//

import Foundation
import Photos

class AlbumListModel: NSObject, Identifiable, ObservableObject {
    
    var folder: PHCollection!
    @Published var fetchResult = PHFetchResult<PHCollection>()
    @Published var albumArray: [PHAssetCollection] = []
    @Published var colorIndex: Int = 0
    
    init(folder: PHCollectionList!, fetchResult: PHFetchResult<PHCollection>, colorIndex: Int) {
        super.init()
        self.folder = folder
        self.fetchResult = fetchResult
        self.colorIndex = colorIndex
        self.albumArray = Array(fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count))).filter{ $0.isKind(of: PHAssetCollection.self) }.map{ $0 as! PHAssetCollection }
    }
    
}

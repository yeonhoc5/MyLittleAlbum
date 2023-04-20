//
//  MyLittleAlbumApp.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

@main
struct MyLittleAlbum: App {
    var body: some Scene {
        WindowGroup {
            TabBarView()
                .environmentObject(PhotoData())
                .preferredColorScheme(.dark)
        }
    }
}

//
//  TabBarView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

enum Tabs {
    case photo
    case album
    case collection
    case passed
}

struct TabBarView: View {
    @State private var selection: Tabs = .album
    
    var body: some View {
        TabView(selection: $selection) {
            PhotoView(color: .orange)
                .tabItem {
                    Image(systemName: "photo")
                    Text("앨범없는 사진")
                }
                .tag(Tabs.photo)
            Navigation(title: "My Album", color: .orange)
                .tabItem {
                    Image(systemName: "folder")
                    Text("앨범")
                }
                .tag(Tabs.album)
            Navigation(title: "My Collection", color: .purple)
                .tabItem {
                    Image(systemName: "tray")
                    Text("콜렉션")
                }
                .tag(Tabs.collection)
            PhotoView(color: .purple)
                .tabItem {
                    Image(systemName: "shippingbox.fill")
                    Text("창고")
                }
                .tag(Tabs.passed)
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}

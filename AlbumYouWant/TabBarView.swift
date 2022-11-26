//
//  TabBarView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

enum Tabs {
    case photo, album, collection, passed
}

struct TabBarView: View {
    @EnvironmentObject var photoData: PhotoData
    @State private var selection: Tabs = .album
    @State var Alert: Bool = false
    
    var body: some View {
        TabView(selection: $selection) {
            PhotoView(allPhotos: photoData.allPhotos)
                .tabItem(image: "photo", title: "앨범없는 사진")
                .tag(Tabs.photo)
            Navigation(title: "My Album", color: .orange)
                .tabItem(image: "folder", title: "앨범")
                .tag(Tabs.album)
            Navigation(title: "My Collection", color: .purple)
                .tabItem(image: "tray", title: "콜렉션")
                .tag(Tabs.collection)
            PhotoView(allPhotos: photoData.allPhotos)
                .tabItem(image: "shippingbox.fill", title: "창고")
                .tag(Tabs.passed)
        }
    }
}

extension View {
    func tabItem(image: String, title: String) -> some View {
        self.tabItem {
            Image(systemName: image)
            Text(title)
        }
    }
}



struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
            .environmentObject(PhotoData())
    }
}

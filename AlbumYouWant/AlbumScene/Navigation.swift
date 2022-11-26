//
//  ContentView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI

struct Navigation: View {
    var title: String = ""
    var color: Color
//    var path: String = ""
    
    var body: some View {
        NavigationView {
            AlbumView()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                
        }
        .ignoresSafeArea(.all)
        .accentColor(.primary)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Navigation(title: "My Album", color: .orange)
            .environmentObject(PhotoData())
    }
}

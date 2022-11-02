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
            AlbumView(title: title, color: color)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { } label: {
                            Image(systemName: "plus.rectangle.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                        }
                    }
                }
        }
        .ignoresSafeArea(.all)
        .accentColor(.primary)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Navigation(title: "My Album", color: .orange)
    }
}

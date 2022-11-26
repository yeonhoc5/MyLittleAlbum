//
//  PhotoLibraryView.swift
//  AlbumYouWant
//
//  Created by yeonhoc5 on 2022/11/25.
//

import SwiftUI

struct PhotoLibraryView: View {
    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @State private var showErrorPrompt = false
    
    
    var body: some View {
        ZStack {
            libraryView
                .onAppear {
                    requestForAuthorizationIfNecessary()
                }
                .alert(
                    Text("This app requires photo library access to show your photos"),
                    isPresented: $showErrorPrompt
                ) {}
        }
    }
}

extension PhotoLibraryView {
    var libraryView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: .init(.adaptive(minimum: 100), spacing: 1),
                    count: 5
                ), spacing: 1
            ) {
                ForEach(photoLibraryService.results, id: \.self) { asset in
                    Button { }
                label: {
                        PhotoThumbnailView(assetLocalId: asset.localIdentifier)
                    }
                }
            }
        }
    }
}

extension PhotoLibraryView {
    func requestForAuthorizationIfNecessary() {
        guard photoLibraryService.authorizationStatus != .authorized ||
                photoLibraryService.authorizationStatus != .limited
        else { return }
        photoLibraryService.requestAuthorization()
    }
}

struct PhotoLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoLibraryView()
            .environmentObject(PhotoLibraryService())
    }
}

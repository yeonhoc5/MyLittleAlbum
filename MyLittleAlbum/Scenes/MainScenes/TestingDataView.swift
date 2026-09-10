//
//  TestingDataView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/11/25.
//

import SwiftUI

struct TestingDataView: View {
    @EnvironmentObject var photoData: MLPhotoData
    var body: some View {
        VStack {
            Button {
                photoData.loadAlbumData(step: .loadHomeAlbum)
            } label: {
                Text("load all photod")
                    .background {
                        Capsule().foregroundStyle(.white)
                    }
            }
            Button {
                photoData.loadAlbumData(step: .loadAllAlbums)
            } label: {
                Text("load all album")
                    .background {
                        Capsule().foregroundStyle(.white)
                    }
            }
            Button {
                photoData.loadAlbumData(step: .loadTopFolder)
            } label: {
                Text("load top folders")
                    .background {
                        Capsule().foregroundStyle(.white)
                    }
            }
            Button {
                photoData.loadAlbumData(step: .loadSecondaryLines)
            } label: {
                Text("load secondary lines")
                    .background {
                        Capsule().foregroundStyle(.white)
                    }
            }
        }
    }
    func btnView(title: String) -> some View {
        Text("load secondary lines")
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background {
                Capsule().foregroundStyle(.white)
            }
    }
}

#Preview {
    TestingDataView()
}

//
//  InAppPhotosPicker.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/18/25.
//

import SwiftUI
import Photos

struct InAppPhotosPicker: ViewModifier {
  let openMLAlbumID: String
  @Binding var isShowingPhotosPicker: Bool
  let nameSpace: Namespace.ID
  
  let completion: ([MLAsset]) -> Void
  
  func body(content: Content) -> some View {
    content
      .fullScreenCover(isPresented: $isShowingPhotosPicker,
             content: {
        CustomPhotosPicker(
          isShowingPhotosPicker: $isShowingPhotosPicker,
          animationEnded: .constant(true),
          openedMLAlbumID: openMLAlbumID,
          albumType: .picker,
          nameSpace: nameSpace,
          completion: { addedAssets in
            isShowingPhotosPicker = false
            completion(addedAssets)
          }
        )
//        .padding(.bottom, tabbarHeight)
        .interactiveDismissDisabled()
        .presentationBackground(.clear)
      })
  }
}

#Preview {
  ContentView()
    .modifier(InAppPhotosPicker(
      openMLAlbumID: "asdf",
      isShowingPhotosPicker: .constant(true),
      nameSpace: Namespace().wrappedValue,
      completion: { _ in
      })
    )
}

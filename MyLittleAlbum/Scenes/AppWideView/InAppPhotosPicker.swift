//
//  InAppPhotosPicker.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/18/25.
//

import SwiftUI
import Photos

struct InAppPhotosPicker: ViewModifier {
    @EnvironmentObject var photoData: MLPhotoData
    @State var isShowingPhotosPicker: Bool = false
    @State var pickerObject: PickerObject?
    @Namespace var nameSpace
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isShowingPhotosPicker,
                   onDismiss: {
                DispatchQueue.main.async {
                    pickerObject = nil
                }
            }) {
                if let object = pickerObject {
                    CustomPhotosPicker(
                        isShowingPhotosPicker: $isShowingPhotosPicker,
                        albumToEdit: object.editToAlbum,
                        imageCachingManager: object.imageManager
                    )
                    .transition(.opacity)
                    .animation(.easeInOut, value: photoData.homeAlbum != nil)
                } else {
                    Circle().fill(Color.gray)
                        .overlay {
                            Text("\(pickerObject == nil)")
                        }
                }
            }
            .onChange(of: pickerObject, perform: { newValue in
                if newValue != nil {
                    self.isShowingPhotosPicker = true
                }
            })
            .onReceive(NotificationCenter.default
                .publisher(for: .showPhotosPicker)) { object in
                    if let pickerObject = object.object as? PickerObject {
                        self.pickerObject = pickerObject
                    }
                }
    }
}

#Preview {
    ContentView()
        .modifier(InAppPhotosPicker())
}

struct PickerObject: Equatable {
    let editToAlbum: MLAlbum
    let imageManager: PHCachingImageManager
}

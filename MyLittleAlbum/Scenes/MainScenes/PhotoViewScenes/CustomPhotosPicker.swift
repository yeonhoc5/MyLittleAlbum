//
//  CustomPhotosPicker.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/31.
//

import SwiftUI
import Photos

struct CustomPhotosPicker: View {
    @Binding var isShowingPhotosPicker: Bool
    
    @EnvironmentObject var photoData: PhotoData
    @ObservedObject var stateChangeObject: StateChangeObject
    
    @State var album: Album!
    
//    @State var assetArray: [PHAsset]!
    @State var title: String = "앨범 없는 사진함"
    @State var assetCount: Int = 0
    
    @State var edgeToScroll: EdgeToScroll = .none
    
    @State var selectedItemsIndex: [Int] = []
    
    @State var belongingType: BelongingType = .nonAlbum
    @State var filteringType: FilteringType = .all
    @State var settingDone: Bool! = false
    
    var albumToEdit: Album

    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text(title)
                        .foregroundColor(.white)
                    Text("(\(assetCount)개 항목)")
                        .foregroundColor(.gray)
                }
                .font(Font.system(size: 20, weight: .semibold, design: .rounded))
                .bold()
                .padding(.top, 10)
                .padding(.bottom, 20)
                ZStack(alignment: .bottom) {
                    if settingDone == false {
                        RefreshPhotoView(sentence: "Wait.  I'll bring you photos~meow")
                            .offset(y: -100)
                            .scaleEffect(0.9)
                            .background{
                                FancyBackground()
                            }
                            .onAppear {
                                readyToShowMyPhotos(type: belongingType)
                            }
                    } else {
                        PhotosCollectionView(stateChangeObject: stateChangeObject,
                                             albumType: .picker,
                                             album: album,
//                                             filteringType: $filteringType,
                                             edgeToScroll: $edgeToScroll,
                                             isSelectMode: .constant(true),
                                             selectedItemsIndex: $selectedItemsIndex,
                                             isShowingPhotosPicker: .constant(false),
                                             indexToView: .constant(0),
                                             isExpanded: .constant(false),
                                             insertedIndex: [],
                                             removedIndex: [],
                                             changedIndex: [],
                                             currentCount: album.count)
                        PhotosGridMenu(stateChangeObject: stateChangeObject,
                                       albumType: .picker,
                                       album: album,
                                       settingDone: $settingDone,
                                       belongingType: $belongingType,
                                       filteringType: $filteringType,
                                       isSelectMode: .constant(true),
                                       selectedItemsIndex: .constant([]),
                                       edgeToScroll: $edgeToScroll,
                                       isShowingSheet: .constant(false),
                                       isShowingShareSheet: .constant(false))
                            .padding(.bottom, 20)
                    }
                }
                .ignoresSafeArea()
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .onChange(of: self.belongingType, perform: { value in
                    self.settingDone = false
                })
                .onChange(of: album?.filteringType, perform: { newValue in
                    print("picker filteringtype works")
                    DispatchQueue.main.async {
                        withAnimation {
                            switch album?.filteringType {
                            case .video:
                                assetCount = album.countOfVidoe
                            case .image:
                                assetCount = album.countOfImage
                            default:
                                assetCount = album.count
                            }
                        }
                    }
                })
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { toolbarLeading }
                    ToolbarItem(placement: .navigationBarTrailing) { toolbarTrailing }
                }
            }
            .background {
                FancyBackground()
            }
        }
    }
    
    var toolbarLeading: some View {
        Button("취소") {
            dismissPickerView()
        }
    }
    
    var toolbarTrailing: some View {
        Button {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                addAssetIntoAlbum(indexSet: selectedItemsIndex)
            }
        } label: {
            Text("\(selectedItemsIndex.count)개의 항목 앨범에 넣기")
        }
        .disabled(selectedItemsIndex.count == 0)
    }
    
    func dismissPickerView() {
        self.isShowingPhotosPicker = false
        selectedItemsIndex.removeAll()
    }
    
    func addAssetIntoAlbum(indexSet: [Int]) {
        self.isShowingPhotosPicker = false
        var assetArray: [PHAsset] = []
        switch album.filteringType {
        case .all:
            assetArray = album.photosArray
        case .image:
            assetArray = album.photosArray.filter({$0.mediaType == .image})
        case .video:
            assetArray = album.photosArray.filter({$0.mediaType == .video})
        }
        let sortedIndexSet = indexSet.sorted{ $0 < $1 }
        var assets: [PHAsset] = []
        for i in sortedIndexSet {
            assets.append(assetArray[i])
        }
        selectedItemsIndex = []
        DispatchQueue.main.async {
            albumToEdit.addAsset(assets: assets)
            stateChangeObject.assetRemoving = true
        }
        
    }
    
    func readyToShowMyPhotos(type: BelongingType) {
        switch belongingType {
        case .nonAlbum:
            self.album = Album(albumType: .picker,
                               assetArray: photoData.photosArrayNotInAnyAlbum,
                               title: "앨범 없는 사진함",
                               belongingType: .nonAlbum)
        case .album:
            self.album = Album(albumType: .picker,
                               assetArray: photoData.allPhotosArrayInAllAlbum,
                               title: "앨범 있는 사진함",
                               belongingType: .album)
        default:
            self.album = Album(albumType: .picker,
                               assetArray: photoData.allPhotosArray,
                               title: "모든 사진함",
                               belongingType: .all)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                self.title = album.title
                self.assetCount = album.count
                self.settingDone = true
            }
        }
    }
    
    
}

struct CustomPhotosPicker_Previews: PreviewProvider {
    static var previews: some View {
        CustomPhotosPicker(isShowingPhotosPicker: .constant(true),
                           stateChangeObject: StateChangeObject(),
                           album: nil,
                           title: "Not in any Album",
                           albumToEdit: Album(assetArray: [], title: "sample"))
        .environmentObject(PhotoData())
    }
}

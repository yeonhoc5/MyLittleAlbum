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
    let size: CGSize
    
    //    @State var assetArray: [PHAsset]!
    @State var title: String = "앨범 없는 사진함"
    @State var assetCount: Int = 0
    
    @State var edgeToScroll: EdgeToScroll = .none
    
    @State var selectedItemsIndex: [Int] = []
    
    @State var belongingType: BelongingType = .nonAlbum
    @State var filteringType: FilteringType = .all
    @State var filteringTypeChanged: Bool = false
    @State var settingDone: Bool! = false
    
    @Namespace private var nameSpace
    
    var albumToEdit: Album
    
    var body: some View {
        NavigationView {
            VStack {
                if !settingDone {
                    loadingView
                } else {
                    photoPickerView
                }
            }
            .background {
                FancyBackground()
            }
        }
    }
    
}

extension CustomPhotosPicker {
    var loadingView: some View {
        RefreshPhotoView(sentence: "Wait.  I'll bring you photos~meow")
            .scaleEffect(0.9)
            .background{
                FancyBackground()
            }
            .onAppear {
                readyToShowMyPhotos(type: belongingType)
            }
    }
    
    var photoPickerView: some View {
        GeometryReader(content: { geoProxy in
            VStack {
                HStack {
                    Text(title)
                        .foregroundColor(.white)
                    Text("(\(assetCount)개 항목)")
                        .foregroundColor(.gray)
                }
                .font(Font.system(size: 20, weight: .semibold, design: .rounded))
                .bold()
                .padding(.top, 40)
                .padding(.bottom, 20)
                ZStack(alignment: .bottom) {
                    PhotosCollectionView(stateChangeObject: stateChangeObject,
                                         albumType: .picker,
                                         album: album,
                                         edgeToScroll: $edgeToScroll,
                                         filteringTypeChanged: $filteringTypeChanged,
                                         isSelectMode: .constant(true),
                                         selectedItemsIndex: $selectedItemsIndex,
                                         isShowingPhotosPicker: .constant(false),
                                         indexToView: .constant(0),
                                         isExpanded: .constant(false),
                                         insertedIndex: [],
                                         removedIndex: [],
                                         changedIndex: [],
                                         currentCount: album.count,
                                         isSelectingBySwipe: .constant(false),
                                         geoProxy: geoProxy
                    )
                    .frame(width: size.width)
                    GeometryReader { geoProxy in
                        PhotosGridMenu(stateChangeObject: stateChangeObject,
                                       albumType: .picker,
                                       album: album,
                                       albumToEdit: albumToEdit,
                                       settingDone: $settingDone,
                                       belongingType: $belongingType,
                                       filteringType: $filteringType,
                                       filteringTypeChanged: $filteringTypeChanged,
                                       isSelectMode: .constant(true),
                                       selectedItemsIndex: $selectedItemsIndex,
                                       edgeToScroll: $edgeToScroll,
                                       isShowingSheet: .constant(false),
                                       isShowingShareSheet: .constant(false),
                                       isShowingPhotosPicker: $isShowingPhotosPicker,
                                       nameSpace: nameSpace,
                                       width: geoProxy.size.width)
                    }
                    .clipped()
                    .shadow(color: Color.fancyBackground.opacity(0.5),
                            radius: 2, x: 0, y: 0)
                    .padding(.horizontal, tabbarTopPadding)
                    .frame(width: size.width, height: tabbarHeight)
                    .padding(.bottom, 20)
                }
            }
        })
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
        stateChangeObject.photosPickerCanceled = true
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
            albumToEdit.addAsset(assets: assets, stateObject: stateChangeObject)
//            stateChangeObject.assetRemoving = true
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
                           size: .zero,
                           title: "Not in any Album",
                           albumToEdit: Album(assetArray: [], title: "sample"))
        .environmentObject(PhotoData())
    }
}

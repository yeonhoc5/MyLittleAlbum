//
//  PhotosGridView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/31.
//

import SwiftUI
import Photos

struct PhotosGridView: View {
    
    var album: Album
    var isHome: Bool
    var isPicker: Bool! = false
    @Binding var isSelectMode: Bool
    @Binding var indexToView: Int
    @State var isExpended: Bool = false
    var gridCount: Int
    var spacing: CGFloat = 1.0
    var animationID: Namespace.ID
    
    @State var imageManager = PHCachingImageManager()
    
    @State var scrollAtFirst: Bool = true
    @Binding var edgeToScroll: EdgeToScroll
    @Binding var selectedItemsIndex: [Int]
    @Binding var isShowingPhotosPicker: Bool
    
    @Namespace var bottomToScroll
    
//    var selecteAsset: [Any] = []
    
    var body: some View {
//        let cellWidth = (screenSize.width - (spacing * (CGFloat(gridCount - 1)))) / CGFloat(gridCount)
//        let cellPreviewSize = (screenSize.width - 40)
        
        if album.albumFetchResult.count == 0 && (isHome || isPicker) {
            ZStack {
                Color.fancyBackground
                    .ignoresSafeArea()
                Image("arrangeKing")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.9)
            }
        } else {
//            photoGrid(cellWidth: cellWidth, cellPreviewWidth: cellPreviewSize)
        }
    }
    
//    func photoGrid(cellWidth: CGFloat, cellPreviewWidth: CGFloat) -> some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                let coloumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: gridCount)
//                LazyVGrid(columns: coloumns, spacing: spacing) {
//                    ForEach(album.assetArray, id: \.self) { asset in
//                        let size = CGSize(width: cellWidth * scale, height: cellWidth * scale)
//                        let previewSize = CGSize(width: cellPreviewWidth * scale, height: cellPreviewWidth * scale)
//                        if isPicker || isSelectMode {
//                            ZStack(alignment: .bottomLeading) {
//                                thumbnailView(asset: asset.asset, width: cellWidth, size: size, type: asset.type, index: asset.index)
//                                    .opacity(selectedItemsIndex.contains(asset.index) ? 0.7 : 1)
//                                    .onAppear {
//                                        imageManager.startCachingImages(for: [asset.asset], targetSize: previewSize, contentMode: .aspectFill, options: nil)
//                                    }
//                                    .onDisappear {
//                                        imageManager.stopCachingImages(for: [asset.asset], targetSize: previewSize, contentMode: .aspectFill, options: nil)
//                                    }
//                                selectedMark()
//                                    .opacity(selectedItemsIndex.contains(asset.index) ? 1 : 0)
//                                    .padding(5)
//                            }
//                        } else {
//                            if isExpended && indexToView == asset.index {
//                                Rectangle()
//                                    .frame(width: cellWidth, height: cellWidth)
//                                    .foregroundColor(.clear)
//                            } else {
//                                thumbnailView(asset: asset.asset, width: cellWidth, size: size, type: asset.type, index: asset.index)
//                                    .matchedGeometryEffect(id: asset.index, in: animationID)
//                                    .onAppear {
//
//                                        imageManager.startCachingImages(for: [asset.asset], targetSize: previewSize, contentMode: .aspectFill, options: nil)
//                                        imageManager.startCachingImages(for: [asset.asset], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil)
//                                    }
//                                    .onDisappear {
//                                        imageManager.stopCachingImages(for: [asset.asset], targetSize: previewSize, contentMode: .aspectFill, options: nil)
//                                        imageManager.stopCachingImages(for: [asset.asset], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil)
//                                    }
//                                    .contextMenu {
//                                        deleteMenu(asset: asset.asset)
//                                    } preview: {
//                                        AsyncImage(url: nil) { _ in
//                                            thumbnailView(asset: asset.asset, width: cellPreviewWidth, size: previewSize, type: asset.type, index: asset.index)
//                                        }
//                                    }
//                                    .onTapGesture {
//                                        indexToView = asset.index
//                                        withAnimation(.easeInOut(duration: 0.25)) {
//                                            isExpended = true
//                                        }
//                                    }
//                            }
//                        }
//                    }

//                    ForEach(album.photosArray, id: \.self) { asset in
//                        let index = album.photosArray.firstIndex(of: asset)!
//                        let size = CGSize(width: cellWidth * scale, height: cellWidth * scale)
//                        let previewSize = CGSize(width: cellPreviewWidth * scale, height: cellPreviewWidth * scale)
//                        if isPicker || isSelectMode {
//                            ZStack(alignment: .bottomTrailing) {
//    //                            AsyncImage(url: nil) { _ in
//                                thumbnailView(asset: asset, width: cellWidth, size: size, type: asset.mediaType, index: index)
//                                        .aspectRatio(1.0, contentMode: .fill)
//                                        .onAppear(perform: {
//                                            imageManager.startCachingImages(for: [asset], targetSize: previewSize, contentMode: .aspectFill, options: nil)
//                                        })
//    //                            }
//                                        .opacity(selectedItemsIndex.contains(index) ? 0.7 : 1)
//                                    selectedMark()
//                                        .opacity(selectedItemsIndex.contains(index) ? 1 : 0)
//                                        .padding(5)
//                            }
//                            .onTapGesture {
//                                if let index = selectedItemsIndex.firstIndex(of: index) {
//                                    selectedItemsIndex.remove(at: index)
//                                } else {
//                                    selectedItemsIndex.append(index)
//                                }
//                            }
//                        } else {
//                            if isExpended && indexToView == index {
//                                Rectangle()
//                                    .frame(width: cellWidth, height: cellWidth)
//                                    .foregroundColor(.clear)
//                            } else {
//    //                            AsyncImage(url: nil) { _ in
//                                thumbnailView(asset: asset, width: cellWidth, size: size, type: asset.mediaType, index: index)
//                                    .matchedGeometryEffect(id: index, in: animationID)
//                                    .aspectRatio(1.0, contentMode: .fill)
//                                    .onAppear(perform: {
//                                        imageManager.startCachingImages(for: [asset], targetSize: previewSize, contentMode: .aspectFill, options: nil)
//                                    })
//    //                            }
//                                    .contextMenu(menuItems: {
//                                        deleteMenu(asset: asset)
//                                    }, preview: {
//    //                                    AsyncImage(url: nil) { _ in
//                                            thumbnailView(asset: asset, width: cellPreviewWidth, size: previewSize, type: asset.mediaType, index: index)
//                                            .matchedGeometryEffect(id: index, in: animationID)
//                                                .aspectRatio(1.0, contentMode: .fill)
//    //                                    }
//                                    })
//                                    .buttonStyle(ClickScaleEffect())
//                                    .onTapGesture {
//                                        indexToView = index
//                                        withAnimation(.interactiveSpring()) {
//                                            isExpended = true
//                                        }
//                                    }
//                            }
//                        }
//                    }
                
//                    if !isHome && !isSelectMode && !isPicker {
//                        photoPickerView(width: cellWidth)
//                    }
//                }
//                .padding(.top, 10)
//                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.5), value: album.count)
//                underLazyViewToScroll
//            }
//            .onAppear {
//                if scrollAtFirst && (isHome || isPicker) {
//                    proxy.scrollTo(bottomToScroll, anchor: .bottom)
//                }
//                scrollAtFirst = false
//            }
//            .onChange(of: edgeToScroll) { edge in
//                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.5, blendDuration: 0.5)) {
//                    switch edge {
//                    case .top: proxy.scrollTo(0, anchor: .topLeading)
//                    case .bottom: proxy.scrollTo(bottomToScroll, anchor: .bottom)
//                    default: edgeToScroll = .none
//                    }
//                }
//                edgeToScroll = .none
//            }
//            .onDisappear {
//                isSelectMode = false
//                imageManager.stopCachingImagesForAllAssets()
//            }
//        }
//        .overlay(content: {
//            if isExpended {
//                AnotherView(album: album, isExpended: $isExpended, animationID: animationID, indexToView: $indexToView, indexs: indexToView)
//            }
//        })
//    }
}


//struct AnotherView: View {
//    var album: Album
//    @Binding var isExpended: Bool
//    var animationID: Namespace.ID
//    @Binding var indexToView: Int
//    var tabbedIndex: Int
//    
//    let imageManager = PHCachingImageManager()
////    @State var thumbnailArray = [UIImage()]
//    
//    var body: some View {
//        TabView(selection: $indexToView) {
//            ForEach(album.assetArray, id: \.self) { asset in
//                let startIndex = (0...1).contains(indexToView) ? 0 : (asset.index - 1)
//                let endIndex = ((album.count - 2)...(album.count - 1)).contains(indexToView) ? (album.count - 1) : (asset.index + 1)
//                if ((startIndex)...(endIndex)).contains(indexToView) {
//                    Image(uiImage: fetchingImage(asset: asset.asset))
//                        .resizable()
//                        .scaledToFit()
//                        .tag(asset.index)
//                        .matchedGeometryEffect(id: asset.index, in: animationID)
//                        .onAppear {
//                            print("appeared \(asset.index)")
//                        }
//                        .onChange(of: indexToView) { [oldValue = indexToView] newValue in
//                            if newValue < oldValue {
//                                let assetRatio = asset.asset.pixelHeight / asset.asset.pixelWidth
//                                let width = screenSize.width * 2
//                                let height = CGFloat(width) * CGFloat(assetRatio)
//                                let size = CGSize(width: width, height: height)
//                                let options = PHImageRequestOptions()
//                                options.deliveryMode = .opportunistic
//                                options.isSynchronous = true
//                                options.isNetworkAccessAllowed = true
//                                
//                                let addingIndex = (0...5).contains(newValue) ? 0 : (newValue - 5)
//                                let subtractingIndex = ((album.count - 5)...(album.count - 1)).contains(newValue) ? (album.count - 1) : (newValue + 5)
//                                
//                                DispatchQueue.main.async {
//                                    imageManager.startCachingImages(for: [album.photosArray[addingIndex]], targetSize: size, contentMode: .aspectFit, options: options)
//                                    imageManager.stopCachingImages(for: [album.photosArray[subtractingIndex]], targetSize: size, contentMode: .aspectFit, options: options)
//                                }
//                            } else {
//                                let assetRatio = asset.asset.pixelHeight / asset.asset.pixelWidth
//                                let width = screenSize.width * 2
//                                let height = CGFloat(width) * CGFloat(assetRatio)
//                                let size = CGSize(width: width, height: height)
//                                let options = PHImageRequestOptions()
//                                options.deliveryMode = .opportunistic
//                                options.isSynchronous = true
//                                options.isNetworkAccessAllowed = true
//                                
//                                let addingIndex = ((album.count - 5)...(album.count - 1)).contains(newValue) ? (album.count - 1) : (newValue + 5)
//                                let subtractingIndex = (0...5).contains(newValue) ? 0 : (newValue - 5)
//                                
//                                DispatchQueue.main.async {
//                                    imageManager.startCachingImages(for: [album.photosArray[addingIndex]], targetSize: size, contentMode: .aspectFit, options: options)
//                                    imageManager.stopCachingImages(for: [album.photosArray[subtractingIndex]], targetSize: size, contentMode: .aspectFit, options: options)
//                                }
//                                
//                            }
//                        }
//                } else {
//                    Color.yellow
//                }
//            }
//        }
//        .tabViewStyle(.page)
//        .onAppear {
//            let options = PHImageRequestOptions()
//            options.deliveryMode = .opportunistic
//            options.isSynchronous = true
//            options.isNetworkAccessAllowed = true
//            
//            let startIndex = [0, 1, 2, 3, 4].contains(tabbedIndex) ? 0 : (tabbedIndex - 5)
//            let endIndex = ((album.count - 5)...(album.count - 1)).contains(tabbedIndex) ? (album.count - 1) : (tabbedIndex + 5)
//            
//            DispatchQueue.main.async {
//                for i in startIndex...endIndex {
//                    let assetRatio = album.photosArray[i].pixelHeight / album.photosArray[i].pixelWidth
//                    let width = screenSize.width * 2
//                    let height = CGFloat(width) * CGFloat(assetRatio)
//                    imageManager.startCachingImages(for: [album.photosArray[i]], targetSize: CGSize(width: width, height: height), contentMode: .aspectFit, options: options)
//                }
//                print("cached IndexSet: \(startIndex...endIndex)")
//            }
//        }
//        .onDisappear {
//            let imageManger = PHCachingImageManager()
//            imageManger.stopCachingImagesForAllAssets()
//        }
//    }
//    
//    func startCachingImage(assets: [PHAsset]) {
//        
//        
//        
//    }
//    
//    
//    func imageView(asset: PHAsset) -> some View {
////        AsyncImage(url: nil) { _ in
//            Image(uiImage: UIImage())
//                .resizable()
//                .scaledToFit()
////        }.
//    }
//    
//    func fetchingImage(asset: PHAsset) -> UIImage {
//        var returnImage: UIImage!
//        let options = PHImageRequestOptions()
//        options.deliveryMode = .opportunistic
//        options.isSynchronous = true
//        options.isNetworkAccessAllowed = true
//        
//        
//        let assetRatio = asset.pixelHeight / asset.pixelWidth
//        let width = screenSize.width * 2
//        let height = CGFloat(width) * CGFloat(assetRatio)
//        let size = CGSize(width: width, height: height)
//        print(album.photosArray.firstIndex(of: asset)!)
//        print("screenSize: \(screenSize.width) : \(screenSize.height)")
//        print("fetchedSize: \(width) : \(height) ???")
//        imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { assetImage, _ in
//            if let image = assetImage {
//                returnImage = image
//            }
//        }
//        return returnImage
//    }
//    
//}


// subViews
extension PhotosGridView {
    
    @ViewBuilder
    func thumbnailView(asset: PHAsset, width: CGFloat, size: CGSize, type: PHAssetMediaType, index: Int) -> some View {
        if let image = loadImage(asset: asset, thumbNailSize: size) {
            ZStack(alignment: .bottomTrailing) {
                imageScaledFill(uiImage: image, width: width, height: width)
                if type == .video && !selectedItemsIndex.contains(index) {
                    videoDurationView(asset: asset)
                }
            }
        }
    }
    
    func selectModeView(index: Int) -> some View {
        Color.black.opacity( selectedItemsIndex.contains(index) ? 0.5 : 0.001)
            .onTapGesture {
                withAnimation {
                    if let index = selectedItemsIndex.firstIndex(of: index) {
                        selectedItemsIndex.remove(at: index)
                    } else {
                        selectedItemsIndex.append(index)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing, content: {
                if selectedItemsIndex.contains(index) {
                    selectedMark()
                        .padding(5)
                }
            })
    }
    // 비이오 Asset에 재생시간 표시 뷰
    func videoDurationView(asset: PHAsset) -> some View {
        let duration = asset.duration
        let minute: Int = Int(duration) / 60
        let second: Int = Int(round(duration)) % 60
        return Text("\(minute):\(second < 10 ? "0\(second)":"\(second)")")
            .font(.footnote)
            .bold()
            .foregroundColor(.white)
            .padding(3)
    }
    // grid View 아래에 여백 추가용 ( grid 메뉴 위까지 올리기)
    var underLazyViewToScroll: some View {
        Rectangle()
            .id(bottomToScroll)
            .foregroundColor(.clear)
            .frame(height: isHome && album.count % 5 != 0 ? 130:100)
    }
    
    // 앨범에서 사진 추가하기 버튼
    func photoPickerView(width: Double) -> some View {
        Button {
            isShowingPhotosPicker = true
        } label: {
            Color.gray.opacity(0.1)
                .overlay {
                    Text("+").font(.title).foregroundColor(Color.gray)
                }
                .frame(width: width, height: width)
        }
    }
    
    // context Menu : 앨범에서 빼기 / 기기에서 삭제하기
    func deleteMenu(asset: PHAsset) -> some View {
        VStack {
            if !isHome {
                Button {
//                    removeAssetFromAlbum(assets: [asset])
                } label: {
                    ContextMenuItem(title: "앨범에서 빼기", image: "photo")
                }
            }
            Button(role: .destructive) {
//                deleteAsset(assets: [asset])
            } label: {
                ContextMenuItem(title: "기기에서 삭제하기", image: "trash")
            }
        }
    }
}

//functions at PHAsset
extension PhotosGridView {
    // 이미지 읽기
    func loadImage(asset: PHAsset, thumbNailSize: CGSize) -> UIImage? {
        var image = UIImage()
        let requestOptions = PHImageRequestOptions()
        requestOptions.version = .current
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .exact
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
            imageManager.requestImage(for: asset, targetSize: thumbNailSize, contentMode: .aspectFill, options: requestOptions) { assetImage, _ in
                if let assetImage = assetImage {
                    image = assetImage
                }
            }
        return image
    }
    
    
}


//struct PhotosGridView_Previews: PreviewProvider {
//    static var previews: some View {
//        PhotosGridView(allPhotos: photoD, gridCount: <#T##Int#>, width: <#T##CGFloat#>, scale: <#T##CGFloat#>, spacing: <#T##CGFloat#>)
//    }
//}

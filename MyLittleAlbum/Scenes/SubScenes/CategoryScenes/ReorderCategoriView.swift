//
//  ReorderCategoriScene.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/27.
//

import SwiftUI
import Photos

struct ReorderCategoriView: View {
    @EnvironmentObject var photoData: MLPhotoData
    @State var selectType: CollectionType = .album
    @Binding var reorderObject: ReorderObject!
    let pageIdentifier: String
    
    @Namespace var listRow
    
    var body: some View {
        // 앨범
        NavigationView {
            VStack(spacing: 20) {
                titleView
                capsuleIndicator
                orderListView
                btnCancelAndClose
                    .padding([.horizontal, .bottom], 20)
            }
            .background(Color.fancyBackground)
            .navigationTitle("순서 조정하기")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


// extension 1. subviews
extension ReorderCategoriView {
    
    var titleView: some View {
        Group {
            if let pageFolder = photoData.folders[pageIdentifier] {
                Text("대상 폴더 : ")
                    .font(.system(size: 18, weight: .regular, design: .default))
                + Text("[\(pageFolder.phCollectionList == nil ? "최상위" : pageFolder.title)]")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                + Text(" 폴더")
                    .font(.system(size: 18, weight: .regular, design: .default))
            } else {
                Text("")
            }
        }
        .foregroundColor(.white)
        .frame(width: screenSize.width - 44, alignment: .leading)
        .padding(.top, 10)
    }
    
    var capsuleIndicator: some View {
        GeometryReader { proxy in
            ZStack {
                Capsule()
                    .foregroundColor(.white)
                    .overlay {
                        currenIndicator(proxy: proxy)
                    }
                HStack(spacing: 0) {
                    showListButton(type: .album, text: "앨범리스트", proxy: proxy)
                        .foregroundColor(selectType == .album ? .white:.fancyBackground)
                        .font(Font.system(.headline, design: .rounded, weight: selectType == .album ? .bold : .medium))
                    showListButton(type: .folder, text: "폴더리스트", proxy: proxy)
                        .foregroundColor(selectType == .folder ? .white:.fancyBackground)
                        .font(Font.system(.headline, design: .rounded, weight: selectType == .folder ? .bold : .medium))
                    showListButton(type: .none, text: "통합리스트", proxy: proxy)
                        .foregroundColor(selectType == .none ? .white:.fancyBackground)
                        .font(Font.system(.headline, design: .rounded, weight: selectType == .none ? .bold : .medium))
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 22)
    }
    
    func currenIndicator(proxy: GeometryProxy) -> some View {
        let color = selectType == .album ? colorSet[0] : (selectType == .folder ? colorSet[1] : colorSet[25])
        let currenIndex = selectType == .album ? 0 : (selectType == .folder ? 1 : 2)
        let width = (proxy.size.width - 5) / 3
        return Capsule()
            .foregroundColor(color)
            .frame(width: width, height: 35)
            .offset(x: width * CGFloat(currenIndex - 1) , y: 0)
    }
    
    var orderListView: some View {
        GeometryReader { proxy in
            TabView(selection: $selectType) {
                ForEach(CollectionType.allCases, id: \.self) { type in
                    titleListView(type: type, size: proxy.size, animationId: listRow)
                        .tag(type)
                        .frame(height: proxy.size.height)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .mask {
                RoundedRectangle(cornerRadius: 15)
                    .frame(width: screenSize.width - 44, height: proxy.size.height)
            }
        }
    }
    
    func showListButton(type: CollectionType, text: String, proxy: GeometryProxy) -> some View {
        Button {
            withAnimation {
                selectType = type
            }
        } label: {
            Text(text)
        }
        .frame(width: (proxy.size.width - 5) / 3, alignment: .center)
    }

    var btnCancelAndClose: some View {
        Button {
            DispatchQueue.main.async {
                withAnimation {
                    self.reorderObject = nil
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                Text("닫 기")
                    .foregroundStyle(.black)
            }
        }
        .foregroundStyle(.white)
        .frame(height: 50)
        .buttonStyle(ClickScaleEffect())
    }
}

extension ReorderCategoriView {
    @ViewBuilder
    func titleListView(type: CollectionType, size: CGSize, animationId: Namespace.ID) -> some View {
        if let pageFolder = photoData.folders[pageIdentifier] {
            let collection = pageFolder.fetchResult
            let count = switch type {
                        case .album: pageFolder.albumsArray.count
                        case .folder: pageFolder.foldersArray.count
                        case .none: pageFolder.fetchResult.count
                        }
            let filterType = type == .album
                        ? PHAssetCollection.self
                        : (type == .folder ? PHCollectionList.self : PHCollection.self)
            if count > 0 {
                List {
                    ForEach(0..<collection.count, id: \.self) { index in
                        if collection[index].isKind(of: filterType) {
                            let reCheckType: CollectionType = collection[index].isKind(of: PHAssetCollection.self) ? .album : .folder
                            let circleIndex = findCircleIndex(
                                checkType: reCheckType,
                                fetchResult: collection,
                                collection: collection[index])
                            rowLine(type: reCheckType,
                                    collection: collection[index],
                                    index: circleIndex)
                                .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
                                .listRowBackground(Color.white)
                                .id(collection[index].localIdentifier)
                        }
                    }
                    .onMove { from, to in
                        let additional = to > from.first! ? 1 : 0
                        print("----------\(from.first ?? 0)뻔째 인덱스가 \(to - additional)번째 인덱스로")
                        pageFolder.moveCollection(from: from, to: to - additional) { bool in
                            if bool {
                                if let fromIndex = from.first {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        moveArray(pageFolder: pageFolder,
                                                  from: collection[fromIndex],
                                                  to: collection[to - additional])
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.white)
            } else {
                let type: CollectionType = (pageFolder.fetchResult.count == 0 ? .none : (pageFolder.albumsArray.isEmpty ? .album : .folder))
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        NoCollectionPhotoView(selectedType: selectType, type: type)
                        emptyText
                    }
                }
                
            }
        } else {
            EmptyView()
        }
    }
    func moveArray(pageFolder: MLFolder, from: PHCollection, to: PHCollection) {
        if let fromFolder = from as? PHCollectionList,
           let toFolder = to as? PHCollectionList,
           let arrayFrom = pageFolder.foldersArray.firstIndex(of: fromFolder),
           let arrayTo = pageFolder.foldersArray.firstIndex(of: toFolder) {
            let desti = arrayTo > arrayFrom ? arrayTo + 1 : arrayTo
            DispatchQueue.main.async {
                withAnimation {
                    pageFolder.foldersArray
                        .move(fromOffsets: [arrayFrom], toOffset: desti)
                }
            }
        } else if
            let fromAlbum = from as? PHAssetCollection,
            let toAlbum = to as? PHAssetCollection,
            let arrayFrom = pageFolder.albumsArray.firstIndex(of: fromAlbum),
            let arrayTo = pageFolder.albumsArray.firstIndex(of: toAlbum) {
            let desti = arrayTo > arrayFrom ? arrayTo + 1 : arrayTo
               DispatchQueue.main.async {
                   withAnimation {
                       pageFolder.albumsArray
                           .move(fromOffsets: [arrayFrom], toOffset: desti)
                   }
               }
        }
    }
    
    func findCircleIndex(checkType: CollectionType, fetchResult: PHFetchResult<PHCollection>, collection: PHCollection) -> Int {
        let arrayCollection = Array(fetchResult.objects(at: IndexSet(0..<fetchResult.count)))
        let renewAlbum = arrayCollection.filter{ $0.isKind(of: PHAssetCollection.self)}.map{ $0 as! PHAssetCollection }
        let renewFolder = arrayCollection.filter{ $0.isKind(of: PHCollectionList.self)}.map{ $0 as! PHCollectionList }
        
        return checkType == .album ?
        renewAlbum.firstIndex(of: collection as! PHAssetCollection)! + 1
        : renewFolder.firstIndex(of: collection as! PHCollectionList)! + 1
    }
    
    
    var emptyText: some View {
        Group {
            if let pageFolder = photoData.folders[pageIdentifier] {
                let adverb = pageFolder.fetchResult.count != 0 ? "여기" : (selectType == .album ? "여기" : (selectType == .folder ? "여긴" : "정말"))
                let also = pageFolder.fetchResult.count != 0 ? "" : (selectType == .album ? "" : "도")
                let meow = pageFolder.fetchResult.count != 0 ? "냥" : (selectType == .album ? "냥" : (selectType == .folder ? "냐옹" : "냐~옹!"))
                let collection = selectType == .folder ? "폴더" : (selectType == .album ? "앨범" : "아무것")
                let text = "\(adverb) \(collection)\(also) 없다\(meow)"
                return Text(text)
                    .foregroundColor(.fancyBackground)
            } else {
                return Text("")
            }
        }
    }
    
    func rowLine(type: CollectionType, collection: PHCollection, index: Int) -> some View {
        HStack {
            Circle()
                .foregroundColor(type == .folder 
                                 ? colorSet[1]
                                 : (type == .album ? colorSet[0]: colorSet[2]))
                .frame(width: 30, height: 30)
                .overlay {
                    Text("\(index)")
                        .foregroundColor(.white)
                        .font(Font.system(size: 15, weight: .medium, design: .rounded))
                        .bold()
                }
            Text(collection.localizedTitle ?? "")
                .font(Font.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color.fancyBackground.opacity(0.85))
                .padding(.leading, 5)
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.gray)
        }
    }
    
}
extension ReorderCategoriView {
    
//    func moveCollection(from: IndexSet, to: Int, completion: @escaping (PHFetchResult<PHCollection>?) -> Void) {
//        var moveRequest: PHCollectionListChangeRequest?
//        PHPhotoLibrary.shared().performChanges ({
//            if pageFolder.isHome {
//                moveRequest = PHCollectionListChangeRequest(forTopLevelCollectionListUserCollections: pageFolder.fetchResult)
//            } else {
//                moveRequest = PHCollectionListChangeRequest(for: pageFolder.folder, childCollections: pageFolder.fetchResult)
//            }
//            moveRequest?.moveChildCollections(at: from, to: to)
//        }) { (success, error) in
//            print("Finished removing the album from the folder. \(success ? "Success" : String(describing: error))")
//            completion(pageFolder.fetchResult)
//        }
//        
//    }
    
    
}

//struct ReorderCategoriScene_Previews: PreviewProvider {
//    static var previews: some View {
//        ReorderCategoriScene()
//            .environmentObject(PhotoData())
//    }
//}

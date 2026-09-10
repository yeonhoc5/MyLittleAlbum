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
  @Binding var reorderObject: ReorderObject!
  let pageIdentifier: String
  let folderType: FolderType
  @State var selectType: CollectionType = .album
  @Namespace var listRow
  
  var body: some View {
    // 앨범
    NavigationStack {
      VStack(spacing: 20) {
        titleView
        capsuleIndicator
        orderListView
        btnCancelAndClose
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
          if folderType == .userFolder {
            showListButton(type: .none, text: "통합리스트", proxy: proxy)
              .foregroundColor(selectType == .none ? .white:.fancyBackground)
              .font(Font.system(.headline, design: .rounded, weight: selectType == .none ? .bold : .medium))
          }
        }
      }
    }
    .frame(height: 40)
    .padding(.horizontal, 22)
  }
  
  func currenIndicator(proxy: GeometryProxy) -> some View {
    let color = selectType == .album
                ? colorSet[0] : (selectType == .folder
                                 ? colorSet[1] : colorSet[25])
    let currenIndex: CGFloat = selectType == .album
                    ? 0 : (selectType == .folder ? 1 : 2)
    let width = (proxy.size.width - 5) / (folderType == .userFolder ? 3 : 2)
    let offset = folderType == .userFolder
                            ? (currenIndex - 1)
                            : (currenIndex - 0.5)
    return Capsule()
      .foregroundColor(color)
      .frame(width: width, height: 35)
      .offset(x: width * CGFloat(offset) , y: 0)
  }
  
  var orderListView: some View {
    GeometryReader { proxy in
      TabView(selection: $selectType) {
        ForEach(CollectionType.allCases, id: \.self) { type in
          listTitleView(type: type,
                        size: proxy.size,
                        animationId: listRow)
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
    .frame(width: (proxy.size.width - 5) / (folderType == .userFolder ? 3 : 2),
           alignment: .center)
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
        RoundedRectangle(cornerRadius: 20)
        Text("닫 기")
          .foregroundStyle(.black)
      }
    }
    .foregroundStyle(.white)
    .frame(height: 50)
    .padding([.horizontal, .bottom], 20)
    .buttonStyle(ClickScaleEffect())
  }
}

extension ReorderCategoriView {
  @ViewBuilder
  func listTitleView(type: CollectionType,
                     size: CGSize,
                     animationId: Namespace.ID) -> some View {
    if let pageFolder = photoData
                .mlFolder(type: folderType, pageIdentifier) {
      let count = switch type {
      case .album: pageFolder.albumsArray.count
      case .folder: pageFolder.foldersArray.count
      case .none: pageFolder.fetchResultA.count
      }
      if count > 0 {
        List {
          if folderType == .userFolder {
            userList(pageFolder: pageFolder, type: type)
          } else {
            shareList(pageFolder: pageFolder, type: type)
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.white)
      } else {
        let type: CollectionType = (pageFolder.fetchResultA.count == 0 ? .none : (pageFolder.albumsArray.isEmpty ? .album : .folder))
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
  
  func userList(pageFolder: MLFolder,
                type: CollectionType) -> some View {
    let collection = pageFolder.fetchResultA
      .objects(at: IndexSet(0..<pageFolder.fetchResultA.count))
    let filterType = type == .album
                      ? PHAssetCollection.self
                      : (type == .folder
                         ? PHCollectionList.self
                         : PHCollection.self)
    return ForEach(collection, id: \.self) { sub in
      if sub.isKind(of: filterType) {
        let reCheckType: CollectionType = sub
          .isKind(of: PHAssetCollection.self)
        ? .album : .folder
        let sub = SubCollection(id: sub.localIdentifier, title: sub.localizedTitle ?? "", type: type)
        let circleIndex = findCircleIndex(
          checkType: reCheckType,
          pageFolder: pageFolder,
          collection: sub)
        rowLine(type: reCheckType,
                collection: sub,
                index: circleIndex)
      }
    }
    .onMove { from, to in
      let additional = to > from.first! ? 1 : 0
      pageFolder.moveCollection(from: from, to: to - additional) { bool in
        if bool {
          if let fromIndex = from.first {
            let fromID = collection[fromIndex].localIdentifier
            let toID = collection[to - additional].localIdentifier
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              moveArray(pageFolder: pageFolder,
                        fromID: fromID,
                        toID: toID) { }
            }
          }
        }
      }
    }
  }
  func shareList(pageFolder: MLFolder,
                 type: CollectionType) -> some View {
    let collection = type == .album
                    ? pageFolder.albumsArray
                    : pageFolder.foldersArray
    return ForEach(collection, id: \.self) { sub in
      let circleIndex = findCircleIndex(
                          checkType: type,
                          pageFolder: pageFolder,
                          collection: sub)
      rowLine(type: type, collection: sub, index: circleIndex)
    }
    .onMove { from, to in
      let additional = to > from.first! ? 1 : 0
      if let fromIndex = from.first {
        let fromID = collection[fromIndex].id
        let toID = collection[to - additional].id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          moveArray(pageFolder: pageFolder,
                    fromID: fromID,
                    toID: toID) {
            photoData.reOrderCategory(id: pageFolder.id,
                                      type: type,
                                      fromID: fromID,
                                      toID: toID)
          }
        }
      }
    }
  }
  
  func moveArray(pageFolder: MLFolder,
                 fromID: String,
                 toID: String,
                 completion: @escaping () -> Void) {
    if let arrayFrom = pageFolder.foldersArray
                          .compactMap({ $0.id })
                          .firstIndex(of: fromID),
       let arrayTo = pageFolder.foldersArray
                          .compactMap({ $0.id })
                          .firstIndex(of: toID) {
      let desti = arrayTo > arrayFrom ? arrayTo + 1 : arrayTo
      DispatchQueue.main.async {
        withAnimation {
          pageFolder.foldersArray
            .move(fromOffsets: [arrayFrom], toOffset: desti)
        }
        completion()
      }
    } else if
      let arrayFrom = pageFolder.albumsArray
                        .compactMap({ $0.id })
                        .firstIndex(of: fromID),
      let arrayTo = pageFolder.albumsArray
                        .compactMap({ $0.id })
                        .firstIndex(of: toID) {
      let desti = arrayTo > arrayFrom ? arrayTo + 1 : arrayTo
      DispatchQueue.main
        .asyncAfter(deadline: .now() + 0.5) {
        withAnimation {
          pageFolder.albumsArray
            .move(fromOffsets: [arrayFrom], toOffset: desti)
        }
        completion()
      }
    }
  }
  
  func findCircleIndex(checkType: CollectionType,
                       pageFolder: MLFolder,
                       collection: SubCollection) -> Int {
    let renewAlbum = pageFolder.albumsArray
    let renewFolder = pageFolder.foldersArray
    
    return checkType == .album ?
    renewAlbum.firstIndex(where: { $0.id == collection.id })! + 1
    : renewFolder.firstIndex(where: { $0.id == collection.id })! + 1
  }
  
  
  var emptyText: some View {
    Group {
      if let pageFolder = photoData.folders[pageIdentifier] {
        let fetchCount = pageFolder.fetchResultA.count
        let adverb = fetchCount != 0 ? "여기" : (selectType == .album ? "여기" : (selectType == .folder ? "여긴" : "정말"))
        let also = fetchCount != 0 ? "" : (selectType == .album ? "" : "도")
        let meow = fetchCount != 0 ? "냥" : (selectType == .album ? "냥" : (selectType == .folder ? "냐옹" : "냐~옹!"))
        let collection = selectType == .folder ? "폴더" : (selectType == .album ? "앨범" : "아무것")
        let text = "\(adverb) \(collection)\(also) 없다\(meow)"
        return Text(text)
          .foregroundColor(.fancyBackground)
      } else {
        return Text("")
      }
    }
  }
  
  func rowLine(type: CollectionType,
               collection: SubCollection,
               index: Int) -> some View {
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
            .contentTransition(.numericText())
        }
      Text(collection.title)
        .font(Font.system(size: 17, weight: .medium, design: .rounded))
        .foregroundColor(Color.fancyBackground.opacity(0.85))
        .padding(.leading, 5)
      Spacer()
      Image(systemName: "line.3.horizontal")
        .foregroundStyle(.gray)
    }
    .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 40))
    .listRowBackground(Color.white)
    .id(collection.id)
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

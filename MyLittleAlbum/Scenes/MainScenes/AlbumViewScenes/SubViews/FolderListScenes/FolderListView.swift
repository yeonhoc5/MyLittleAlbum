//
//  CollectionLineView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/10/12.
//

import SwiftUI
import Photos
import LottieUI

struct FolderListView: View {
  @EnvironmentObject var photoData: MLPhotoData
  @ObservedObject var pageFolder: MLFolder
  @Binding var isPhotosView: Int
  // ui 프라퍼티
  let pageIndex: Int
  let screenWidth: CGFloat
  var isEditingMode: Bool
  var nameSpace: Namespace.ID
  var albumViewNameSpace: Namespace.ID
  let scrollProxy: ScrollViewProxy
  @State var foldedFolder: [String] = []
  @State var processingCollection: SubCollection!
  
  var body: some View {
    subListView(pageFolder: pageFolder,
                idEditingMode: isEditingMode)
    .padding(.top, 5)
  }
}

extension FolderListView {
  func subListView(pageFolder: MLFolder!,
                   idEditingMode: Bool) -> some View {
    let secondaryWidth = (screenWidth - 20 - CGFloat(listCount * 10)) / CGFloat(listCount + 1)
    let lineHeight = cellHeight(width: secondaryWidth,
                                uiMode: photoData.uiMode,
                                cellType: .folder)
    return VStack(spacing: 0) {
      ForEach(pageFolder?.foldersArray ?? [],
              id: \.self) { subFolder in
        let isFolded = !self.foldedFolder.contains(subFolder.id)
        let index = (pageFolder?.foldersArray ?? [])
                          .firstIndex(of: subFolder) ?? 0
        nextFolderView(uiMode: photoData.uiMode,
                       subFolder: subFolder,
                       index: index,
                       secondaryWidth: secondaryWidth,
                       height: lineHeight,
                       isFolded: isFolded,
                       lineView: { folderIndex in
          Group {
            if let secondaryF = photoData.mlFolder(type: pageFolder.folderType, subFolder.id) {
              SecondaryLineView(
                pageFolder: secondaryF,
                subFolder: subFolder,
                isHome: pageFolder.phCollectionList == nil,
                index: folderIndex,
                screenWidth: screenWidth,
                secondaryWidth: secondaryWidth,
                lineHeight: lineHeight,
                isFolded: isFolded,
                isPhotosView: $isPhotosView,
                nameSpace: nameSpace,
                albumViewNameSpace: albumViewNameSpace,
                isEditingMode: isEditingMode
              )
              .onChange(of: secondaryF.fetchResultA.count,
                        perform: { [oldValue = secondaryF.fetchResultA.count] newValue in
                if newValue > oldValue {
                  withAnimation {
                    scrollProxy
                      .scrollTo(secondaryF.id,
                                anchor: .center)
                  }
                }
              })
            } else {
              FancyBackground()
            }
          }
        })
        .transition(.asymmetric(insertion: .move(edge: .leading),
                                removal: .opacity))
      }
    }
    .onChange(of: photoData.uiMode) { newValue in
      if newValue != .classic {
        dispatchAnimation {
          foldedFolder.removeAll()
        }
      }
    }
  }
}

extension FolderListView {
  @ViewBuilder
  func nextFolderView(uiMode: UIMode,
                      subFolder: SubCollection,
                      index: Int,
                      secondaryWidth: CGFloat,
                      height: CGFloat,
                      isFolded: Bool,
                      lineView: @escaping (Int) -> some View) -> some View {
    let folderIndex = pageIndex + ((index + 1) * 4)
    switch uiMode {
    case .classic:
      VStack(alignment: .leading, spacing: 0) {
        classicNextFolderView(subFolder: subFolder,
                              isFolded: isFolded)
        .zIndex(1)
        .padding(.horizontal , 10)
        lineView(folderIndex)
      }
    default:
      ZStack(alignment: .leading) {
        fancyModernNextFolderview(subFolder: subFolder,
                                  index: folderIndex,
                                  secondaryWidth: secondaryWidth,
                                  height: height)
        .disabled(isEditingMode)
        .overlay(alignment: .topLeading) {
          btnDelete(subFolder: subFolder)
            .offset(x: -1, y: -1)
        }
        .contextMenu(menuItems: {
          EditCollectionMenuView(
            pageFolder: pageFolder,
            processing: $processingCollection,
            isEditMode: .constant(false),
            subCollection: subFolder,
            isSecondary: false,
            index: index,
            nameSpace: nameSpace) { subCollection in
              deleteFolderInDepth(subFolder: subCollection)
            }
        })
        .padding(.vertical, 5)
        .padding(.leading, 10)
        .zIndex(1)
        lineView(folderIndex)
      }
    }
  }
  
  func classicFolderLineView(pageFolder: MLFolder!, view: some View, mode: Bool, width: CGFloat) -> some View {
    let spacing = (self.screenWidth - (CGFloat(listCount+1) * width)) / CGFloat(listCount+1)
    let albumCount = pageFolder?.albumsArray.count ?? 0
    let folderCount = pageFolder?.foldersArray.count ?? 0
    let column = Array(
      repeating: GridItem(spacing: mode ? spacing : 10),
      count: albumCount + folderCount >= listCount+1
      ? (mode ? (listCount+1) : albumCount + folderCount)
      : albumCount + folderCount)
    return scrollViewWidthReader(.horizontal,
                                 scrollDisalble: mode) { proxy in
      LazyVGrid(columns: column)  {
        view
      }
      .transition(.scale(scale: 1, anchor: .topTrailing))
      .id("minialbumEdge")
    }
  }
  
  
  func classicNextFolderView(subFolder: SubCollection,
                             isFolded: Bool) -> some View {
    let folder = photoData.mlFolder(type: pageFolder.folderType,
                                    subFolder.id)
    let folderCount = folder?.foldersArray.count ?? 0
    let albumCount = folder?.albumsArray.count ?? 0
    return VStack {
      HStack {
        Group {
          Image(systemName: "arrowtriangle.down.fill")
            .foregroundColor(.orange).font(.system(size: 12))
            .rotationEffect(Angle(radians: isFolded ? -.pi/2 : 0))
          Text(subFolder.title)
            .foregroundColor(.orange).fontWeight(.bold)
            .contentTransition(.numericText())
          Text("(\(folderCount) / \(albumCount))")
            .font(.footnote).foregroundColor(.gray)
            .contentTransition(.numericText())
        }
        .frame(height: 20)
        .onTapGesture {
          dispatchAnimation {
            foldFolder(subFolder: subFolder)
          }
        }
        Spacer()
        Group {
          if !isEditingMode {
            Menu {
              EditCollectionMenuView(
              pageFolder: pageFolder,
              processing: $processingCollection,
              isEditMode: .constant(false),
              subCollection: subFolder,
              isSecondary: false,
              index: 0,
              nameSpace: nameSpace) { subColl in
                deleteFolderInDepth(subFolder: subColl)
              }
              
            } label: {
              Image(systemName: iconModify)
                .foregroundColor(.secondary)
            }
          } else {
            btnDelete(subFolder: subFolder)
          }
        }
        .frame(height: 15)
        .buttonStyle(ClickScaleEffect(scale: 0.8))
        .transition(.scale)
      }
      .zIndex(1)
      CustomDivider(color: .secondary)
    }
  }
  
  func fancyModernNextFolderview(subFolder: SubCollection,
                                 index: Int,
                                 secondaryWidth: CGFloat,
                                 height: CGFloat) -> some View {
    return NavigationLink {
      if let pageFolder = photoData.mlFolder(type: pageFolder.folderType, subFolder.id) {
        AlbumView(pageFolder: pageFolder,
                  isPhotosView: $isPhotosView,
                  pageIndex: index,
//                  isShowingSettingView: .constant(false),
                  isShowingMessageView: .constant(false),
                  tutorialOn: .constant(false),
                  nameSpace: nameSpace)
        
      }
    } label: {
      ZStack(alignment: .center) {
        RoundedRectangle(cornerRadius: 10)
          .foregroundColor(.folder)
        if #available(iOS 18.0, *) {
          let title = photoData.mlFolder(type: pageFolder.folderType, subFolder.id)?.title ?? subFolder.title
          Text(title)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .contentTransition(.numericText())
            .padding(.all, 5)
        } else {
          if let folder = photoData.mlFolder(type: pageFolder.folderType, subFolder.id) {
            FolderTitleView(folder: folder)
          } else {
            Text(subFolder.title)
              .multilineTextAlignment(.center)
              .foregroundColor(.white)
              .contentTransition(.numericText())
              .padding(.all, 5)
          }
        }
      }
      .shadow(radius: 2)
    }
    .buttonStyle(ClickScaleEffect())
    .frame(width: abs(secondaryWidth * 0.6), height: abs(height))
    .transition(.scale)
  }
}

// iOS 17용 - observedObject 아닐 시 변화 감지 못함
struct FolderTitleView: View {
  @ObservedObject var folder: MLFolder
  var body: some View {
    Text(folder.title)
      .multilineTextAlignment(.center)
      .foregroundColor(.white)
      .contentTransition(.numericText())
      .padding(.all, 5)
  }
}

// editfoldercontext funcs
extension FolderListView {
  func btnDelete(subFolder: SubCollection) -> some View {
    Button {
      processingCollection = subFolder
      deleteFolderInDepth(subFolder: subFolder)
    } label: {
      RemoveButtonLabel(shapeType: .rectangle,
                        isProcessing: processingCollection == subFolder)
    }
    .opacity(isEditingMode ? 1:0)
    .scaleEffect(isEditingMode ? 1:0.1, anchor: .center)
    .buttonStyle(ClickScaleEffect())
  }
  
  func deleteFolderInDepth(subFolder: SubCollection)  {
    if let folder = photoData.mlFolder(type: pageFolder.folderType,
                                       subFolder.id) {
      if folder.folderType == .userFolder {
        pageFolder
          .deleteFolder(folder: folder.phCollectionList) { bool in
          dispatchAnimation {
            if bool {
              photoData.removeFolderValue(folder: folder.phCollectionList) {
                NotificationCenter.default
                  .post(name: .outsideFetchChange,
                        object: "myPhotos")
              }
            }
            self.processingCollection = nil
          }
        }
      } else {
        let object = AlertObject(
          alertCase: .delShareCategory,
          folderType: .shareCategory,
          albumID: nil,
          folderID: folder.id,
          title: subFolder.title,
          parent: pageFolder.id)
        NotificationCenter.default
          .post(name: .showAlert, object: object)
      }
    }
  }
  func foldFolder(subFolder: SubCollection)  {
    if let index = self.foldedFolder.firstIndex(of: subFolder.id) {
      withAnimation {
        let _ = self.foldedFolder.remove(at: index)
      }
    } else {
      withAnimation {
        foldedFolder.append(subFolder.id)
      }
    }
  }
}

enum SheetType {
  case reOrder, moveCollection, moveAsset, photosPicker
}

struct CollectionLineView_Previews: PreviewProvider {
  static var previews: some View {
    AlbumView(pageFolder: MLFolder(collectionList: nil),
              isPhotosView: .constant(0),
              pageIndex: 0,
//              isShowingSettingView: .constant(false),
              isShowingMessageView: .constant(false),
              tutorialOn: .constant(false),
              nameSpace: Namespace().wrappedValue)
    .environmentObject(MLPhotoData())
  }
}

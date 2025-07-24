//
//  CustomTabBarView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/07.
//

import SwiftUI

// MARK: - 1. Tabbar View
struct CustomTabBarView: View {
    @Binding var selectedTab: Tabs
    // 애니메이션 재실행 프라퍼티
    @StateObject var launchScreenManager: LaunchScreenManager
    @Binding var isOpen: Bool
    @Binding var maskingScale: CGFloat
    @Binding var albumTabTapped: Bool
    var isPhotosView: Int
    var actionTab1: () -> Void
    var actionTab2: () -> Void
    var actionTab3: () -> Void
    var actionTab4: () -> Void
    @Namespace var nameSpace
    
    var body: some View {
        GeometryReader { geoProxy in
            let width = geoProxy.size.width
            HStack {
                if device != .phone && isPhotosView == 0 {
                    Rectangle().fill(.clear)
                        .frame(width: width / 5)
                }
                ZStack {
                    // 기기별 백그라운드
                    tabbarBackground(device: device)
                    // 탭버튼 3개
                    HStack {
                        Spacer()
                        customTabItem(tab: .photo, title: "나의 포토") {
                            actionTab1()
                        }
                        Spacer()
                        customTabItem(tab: .album, title: "나의 앨범") {
                            actionTab2()
                        }
                        Spacer()
//                        customTabItem(tab: .share, title: "공유 앨범") {
//                            actionTab3()
//                        }
//                        Spacer()
                        customTabItem(tab: .other, title: "사진 관리") {
                            actionTab4()
                        }
                        Spacer()
                    }
                    .padding(.bottom, device == .phone ? 20 : 0)
                    .padding(.top, 5)
                }
                if device != .phone {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: isPhotosView == 0
                                        ? width / 5 : (width / 3) * 2)
                }
            }
        }
        .frame(height: tabbarHeight)
        .padding(device == .pad ? (safeAraBottom ?? 0) + 5 : 0)
    }
}

// MARK: - 2. subViews
extension CustomTabBarView {
    func tabbarBackground(device: UIUserInterfaceIdiom) -> some View {
        let color = device == .phone
                    ? Color.fancyBackground
                    : Color.white.opacity(0.9)
        return Group {
            switch device {
            case .phone: Rectangle()
            default:
                RoundedRectangle(cornerRadius: 10)
                    .clipped()
                    .shadow(color: .fancyBackground.opacity(0.5),
                            radius: 2, x: 0, y: 0)
            }
        }
        .foregroundStyle(color)
    }
    func customTabItem(tab: Tabs,
                       title: String,
                       actionOnLongPress: @escaping () -> Void) -> some View {
        let icon: String = switch tab {
        case .photo: selectedTab == .photo
            ? "photo.on.rectangle.angled" : "photo.on.rectangle"
        case .album: selectedTab == .album
            ? "film.stack" : "film"
        case .share: selectedTab == .share
            ? "icloud.fill" : "icloud"
        case .other: selectedTab == .other
            ? "list.star" : "list.bullet"
        }
        return VStack(spacing: 4) {
            imageWithScale(systemName: icon, scale: .large)
                .frame(width: 30, height: 20)
                .transition(.opacity)
//                .modify {
//                    if #available(iOS 17.0, *) {
//                        $0.contentTransition(
//                            .symbolEffect(.replace)
//                        )
//                    } else {
//                        $0.contentTransition(.interpolate)
//                    }
//                }
            Text(title).font(
                .system(
                    size: 9,weight: .semibold, design: .rounded
                )
            )
        }
        .frame(width: 50)
        .scaleEffect(selectedTab == tab ? 1.2 : 1)
        .foregroundColor(selectedTab == tab
                            ? (device == .phone ? .white : .black)
                            : .gray)
        .onTapGesture {
            withAnimation(.snappy()) {
                if selectedTab != tab {
                    selectedTab = tab
                } else if selectedTab == .album {
                    self.albumTabTapped = true
                }
            }
        }
        .onLongPressGesture(minimumDuration: 2) {
            actionOnLongPress()
        }
    }
}


struct CustomTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0, content: {
            CustomTabBarView(selectedTab: .constant(.album),
                             launchScreenManager: LaunchScreenManager(),
                             isOpen: .constant(true),
                             maskingScale: .constant(4),
                             albumTabTapped: .constant(false),
                             isPhotosView: 0) {
                print("action 1")
            } actionTab2: {
                print("action 2")
            } actionTab3: {
                print("action 3")
            } actionTab4: {
                print("action 4")
            }
        })
        .ignoresSafeArea(edges: .bottom)
    }
}

//
//  CustomTabBarView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/07.
//

import SwiftUI

// MARK: - 1. Tabbar View
struct CustomTabBarView: View {
    @EnvironmentObject var photoData: PhotoData
    @Binding var selectedTab: Tabs
    // 애니메이션 재실행 프라퍼티
    @StateObject var launchScreenManager: LaunchScreenManager
    @Binding var isOpen: Bool
    @Binding var maskingScale: CGFloat
    var isPhotosView: Bool
    
    var body: some View {
//        let width = device == .phone 
//        ? screenWidth
//        : (!isPhotosView ? screenWidth * 0.5 : (screenWidth / 4))
        GeometryReader { geoProxy in
            let width = geoProxy.size.width
            HStack {
                if device != .phone && !isPhotosView{
                    Rectangle()
                        .fill(.clear)
                        .frame(width: width / 5)
                        .clipped()
                        .shadow(color: Color.fancyBackground.opacity(0.5), radius: 2, x: 0, y: 0)
                }
                ZStack {
                    // 기기별 백그라운드
                    tabbarBackground(device: device)
                    // 탭버튼 3개
                    HStack {
                        Spacer()
                        customTabItem(tab: .photo, title: "나의 포토") {
                            // 런치 스크린 재생 이벤트 트리거
                            showLaunchVideo()
                        }
                        Spacer()
                        customTabItem(tab: .album, title: "나의 앨범") {
                            // 앨범 대표 사진 체인지 이벤트 트리거
                            changeRandomNums()
                        }
                        Spacer()
                        customTabItem(tab: .other, title: "사진 관리") {
                        }
                        Spacer()
                    }
                    .padding(.bottom, device == .phone ? 20 : 0)
                    .padding(.top, 5)
                    
                }
                if device != .phone {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: !isPhotosView ? width / 5 : (width / 4) * 3)
                }
            }
        }
        .frame(height: tabbarHeight)
        .padding(tabbarBottomPadding)
    }
}

// MARK: - 2. subViews
extension CustomTabBarView {
    func tabbarBackground(device: UIUserInterfaceIdiom) -> some View {
        let color = device == .phone ? Color.fancyBackground : Color.white.opacity(0.9)
        return Group {
            switch device {
            case .phone:
                Rectangle()
            default:
                RoundedRectangle(cornerRadius: 10)
            }
        }
        .foregroundStyle(color)
    }
    func customTabItem(tab: Tabs, title: String, 
                       actionOnLongPress: @escaping () -> Void) -> some View {
        let icon: String = switch tab {
        case .photo: selectedTab == .photo
            ? "photo.on.rectangle.angled" : "photo.on.rectangle"
        case .album: selectedTab == .album
            ? "film.stack" : "film"
        case .other: selectedTab == .other
            ? "list.star" : "list.bullet"
        }
        return VStack(spacing: 4) {
            imageWithScale(systemName: icon, scale: .large)
                .frame(width: 30, height: 20)
            Text(title)
                .font(.system(size: 9, 
                              weight: .semibold,
                              design: .rounded))
        }
        .frame(width: 50)
        .scaleEffect(selectedTab == tab ? 1.2 : 1)
        .foregroundColor(selectedTab == tab ? (device == .phone ? .white : .black) : .gray)
        .onTapGesture {
            withAnimation(.interactiveSpring()) {
                if selectedTab != tab {
                    selectedTab = tab
                } else if selectedTab == .album && selectedTab == tab {
                        photoData.scrollToTop = true
                }
            }
        }
        .onLongPressGesture(minimumDuration: 2) {
            actionOnLongPress()
        }
    }
}

// MARK: - 3. functions
extension CustomTabBarView {
    // 1. 런치스크린 리플레이
    func showLaunchVideo() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isOpen = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            launchScreenManager.state = .first
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.easeIn(duration: 0.2)) {
                maskingScale = 0.8
            }
        }
    }
    // 2. 랜덤 숫자 체인지 (-> 앨범 대표 사진 바꾸기)
    func changeRandomNums() {
        withAnimation(.easeInOut(duration: 0.7)) {
            photoData.getRandomNum()
        }
    }
}

struct CustomTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0, content: {
            Rectangle()
                .fill(Color.fancyBackground)
            CustomTabBarView(selectedTab: .constant(.album),
                             launchScreenManager: LaunchScreenManager(),
                             isOpen: .constant(true),
                             maskingScale: .constant(4),
                             isPhotosView: false
            )
            .environmentObject(PhotoData())
        })
        .ignoresSafeArea(edges: .bottom)
    }
}

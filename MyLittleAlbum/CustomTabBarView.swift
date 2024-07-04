//
//  CustomTabBarView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/07.
//

import SwiftUI

// MARK: - 1. Main Struct
struct CustomTabBarView: View {
    @StateObject var launchScreenManager: LaunchScreenManager
    @EnvironmentObject var photoData: PhotoData
    @Binding var selectedTab: Tabs
    @Binding var isOpen: Bool
    @Binding var maskingScale: CGFloat
    
    var body: some View {
        let photoIcon = selectedTab == .photo ? "photo.on.rectangle.angled" : "photo.on.rectangle"
        let albumIcon = selectedTab == .album ? "film.stack" : "film"
        let smartIcon = selectedTab == .smart ? "list.star" : "list.bullet"
        
        ZStack {
            if device == .phone {
                Rectangle()
                    .foregroundColor(.fancyBackground)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.white.opacity(0.3))
            }
            HStack {
                Spacer()
                customTabItem(tab: .photo, image: photoIcon, title: "나의 포토")
                    .onLongPressGesture(minimumDuration: 2) {
                        // 런치 스크린 재생 이벤트 트리거
                        showLaunchVideo()
                    }
                Spacer()
                customTabItem(tab: .album, image: albumIcon, title: "나의 앨범")
                    .onLongPressGesture(minimumDuration: 2) {
                        // 앨범 대표 사진 체인지 이벤트 트리거
                        changeRandomNums()
                    }
                    .simultaneousGesture(scrollGesture)
                Spacer()
                customTabItem(tab: .smart, image: smartIcon, title: "사진 관리")
                Spacer()
                
            }
            .padding(.bottom, device == .phone ? 20 : 0)
            .padding(.top, 5)
        }
        .frame(width: device == .phone ? screenSize.width : 600, height: 80)
        .padding(.bottom, device == .phone ? 0 : 30)
    }
}


// MARK: - 2. subViews
extension CustomTabBarView {
    func customTabItem(tab: Tabs, image: String, title: String) -> some View {
        VStack(spacing: 4) {
            imageWithScale(systemName: image, scale: .large)
                .frame(width: 30, height: 20)
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
        }
        .frame(width: 100)
        .scaleEffect(selectedTab == tab ? 1.2 : 1)
        .foregroundColor(selectedTab == tab ? .white:.gray)
        .onTapGesture {
            withAnimation(.interactiveSpring()) {
                if selectedTab != tab {
                    selectedTab = tab
                }
            }
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
    
    var scrollGesture: some Gesture {
        TapGesture(count: 1)
            .onEnded { _ in
                 
            }
    }
}

struct CustomTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBarView(launchScreenManager: LaunchScreenManager(),
                         selectedTab: .constant(.album),
                         isOpen: .constant(true),
                         maskingScale: .constant(4))
        .environmentObject(PhotoData())
    }
}

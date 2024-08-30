//
//  DigitalShowView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 12/11/23.
//

import SwiftUI
import Photos

struct DigitalShowView: View {
    @EnvironmentObject var photoData: PhotoData
    @State var photosArray: [PHAsset] = []
    @State var digitalShowNumber: Int = 0
    @State var timer: Timer!
    var nameSpace: Namespace.ID
    @State var isShowingDigitalShowGuide: Bool = false
    
    @State var guideScale = 1.0
    @State var guideOpacity = 1.0
    @State var stopShow: Bool = false
    @State var startString = "의 디지털 액자 모드를 실행합니다."
    @State var endString = "디지털 액자 모드를 종료합니다."
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ZStack {
            backgroundView(nameSpace: nameSpace)
            if photosArray.count > 0 {
                DigitalView(asset: self.photosArray[digitalShowNumber],
                            stopShow: stopShow)
                    .onAppear(perform: {
                        self.startDigitalShow()
                        self.showDigitalShowGuide()
                    })
            }
        }
        .overlay(alignment: .bottom) {
            guideView
                .padding(.bottom, device == .phone ? 20 : 30)
                .offset(y: isShowingDigitalShowGuide ? 0 : 200)
        }
        .gesture(TapGesture(count: 2).onEnded({ _ in
            if !stopShow {
                withAnimation {
                    self.endDigitalShow()
                }
            }
        }))
        .onTapGesture {
            self.showDigitalShowGuide()
        }
        .overlay(alignment: .topTrailing, content: {
            btnEndShow
                .padding(.trailing, 20)
                .padding(.top, device == .phone ? 0 : 20)
                .offset(y: isShowingDigitalShowGuide ? 0 : -100)
        })
        .onChange(of: scenePhase) { newValue in
            if newValue != .active {
                if let timer = self.timer {
                    timer.invalidate()
                }
            } else {
                startDigitalShow()
            }
        }
    }
}

struct DigitalView: View {
    var asset: PHAsset
    var stopShow: Bool = false
    @State var widthIsCreteria: Bool = false
    
    var body: some View {
        if !stopShow {
            GeometryReader { proxy in
                let fetchedImage = self.fetchingImage(asset: asset, size: proxy.size)
                ZStack {
                    Image(uiImage: fetchedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .blur(radius: 30.0)
                    Image(uiImage: fetchedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width,
                               height: proxy.size.height)
                        .transition(.slide)
                }
            }
            .ignoresSafeArea()
        } else {
            Color.clear
        }
        
    }
    
    func fetchingImage(asset: PHAsset, size: CGSize) -> UIImage {
        let imageManager = PHCachingImageManager()
        let assetRatio = CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
        let screenRatio = size.height / size.width
        widthIsCreteria = assetRatio <= screenRatio
        var returnImage: UIImage!
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        let creteriaSize = (widthIsCreteria
                     ? size.width
                     : size.height) * scale
        let size = CGSize(width: widthIsCreteria ? creteriaSize : .infinity,
                          height: widthIsCreteria ? .infinity : creteriaSize)
        
        imageManager.requestImage(for: asset,
                                  targetSize: size,
                                  contentMode: .aspectFit,
                                  options: options) { assetImage, _ in
            if let image = assetImage {
                returnImage = image
            }
        }
        return returnImage
    }
}

extension DigitalShowView {
    func backgroundView(nameSpace: Namespace.ID) -> some View {
        RoundedRectangle(cornerRadius: 20.0)
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .matchedGeometryEffect(id: "digitalShow", in: nameSpace)
            .overlay {
                if !stopShow {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("앨범")
                            Text("\"\(photoData.digitalPhotoAlbums.first?.title ?? "")\"")
                                .font(.system(size: 30, weight: .bold))
                        }
                        Text(!stopShow ? startString : endString)
                    }
                    .scaleEffect(guideScale)
                    .opacity(guideOpacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            makePhotosArray()
                            withAnimation {
                                if !stopShow {
                                    guideScale = 4.0
                                }
                            }
                        }
                        if !stopShow {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                guideScale = 1.0
                                guideOpacity = 0.0
                            }
                        }
                    }
                } else {
                    Text(endString)
                }
            }
    }
    
    var btnEndShow: some View {
        Button {
            if !stopShow {
                withAnimation {
                    self.endDigitalShow()
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThickMaterial)
                    .frame(width: 50, height: 40)
                Text("종료")
                    .foregroundStyle(.white)
            }
        }
    }
    
    var guideView: some View {
        VStack(alignment: .leading, spacing: 10, content: {
            Text("1. 디지털액자 사용 시 화면 자동 꺼짐이 해제됩니다.")
            if device == .phone {
                Text("2. 디지털액자를 종료하려면 [종료] 버튼을 누르거나\n화면을 2번 탭해주세요.")
            } else {
                Text("2. 디지털액자를 종료하려면 [종료] 버튼을 누르거나 화면을 2번 탭해주세요.")
            }
        })
        .padding(20)
        .background(content: {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
        })
    }
    
    func makePhotosArray() {
        for i in photoData.digitalPhotoAlbums {
            self.photosArray += photoData.isHiddenAsset
                    ? i.hiddenAssetsArray : i.photosArray
        }
        self.photosArray = photoData.digitalShowRandom 
        ? self.photosArray.shuffled() : self.photosArray
    }
}

extension DigitalShowView {
    func startDigitalShow() {
        self.timer = Timer.scheduledTimer(withTimeInterval: Double(transitionRange[photoData.transitionIndex]),
                                          repeats: true) { _ in
            withAnimation {
                if self.photosArray.count > 1 {
                    self.digitalShowNumber
                    = (self.digitalShowNumber + 1)
                    % self.photosArray.count
                }
            }
        }
    }
    
    func endDigitalShow() {
        withAnimation {
            self.stopShow = true
            self.isShowingDigitalShowGuide = false
            self.photosArray = []
            photoData.digitalPhotoAlbums = []
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                photoData.isShowingDigitalShow = false
            }
        }
        
        if timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
        self.digitalShowNumber = 0
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    func showDigitalShowGuide() {
        withAnimation {
            self.isShowingDigitalShowGuide.toggle()
        }
        if isShowingDigitalShowGuide == true {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    if isShowingDigitalShowGuide == true {
                        self.isShowingDigitalShowGuide = false
                    }
                }
            }
        }
    }
    
    func slideGesture() -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                if value.translation.width < -100 {
                    withAnimation {
                        self.digitalShowNumber
                        = (self.digitalShowNumber + 1)
                        % self.photosArray.count
                    }
                } else if value.translation.width > 100 {
                    if self.digitalShowNumber > 0 {
                        withAnimation {
                            self.digitalShowNumber -= 1
                        }
                    } else {
                        withAnimation {
                            self.digitalShowNumber = self.photosArray.count - 1
                        }
                    }
                }
                self.timer = nil
                startDigitalShow()
            }
    }
}

#Preview {
    DigitalShowView(nameSpace: Namespace().wrappedValue)
        .environmentObject(PhotoData())
}

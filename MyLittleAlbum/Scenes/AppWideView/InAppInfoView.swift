//
//  InAppInfoView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 5/1/25.
//

import SwiftUI

struct InAppInfoView: ViewModifier {
    @State var infoState: Info = .none
    let radius: CGFloat = 20.0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if infoState == .hiddenAssets {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(.thinMaterial)
                            .ignoresSafeArea()
                        infoView(infoState: infoState)
                            .animation(.easeInOut, value: infoState != .none)
                            .transition(.flip.combined(with: .scale))
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showInfoView)) { info in
                if let object = info.object as? Info {
                    DispatchQueue.main.async {
                        self.infoState = object
                    }
                }
            }
    }
}

#Preview {
    Color.fancyBackground
        .ignoresSafeArea()
        .modifier(
            InAppInfoView(infoState: .hiddenAssets)
        )
        .colorScheme(.dark)
}


enum Info {
    case none
    case hiddenAssets
}

extension InAppInfoView {
    func infoView(infoState: Info) -> some View {
        return Group {
            if let info = getInfo(cases: .hiddenAssets) {
                VStack {
                    VStack {
                        Text(info.title)
                            .font(.title)
                            .bold()
                            .padding(.bottom, 3)
                            .foregroundStyle(Color.fancyBackground)
                        Text(info.semiTitle)
                            .font(.callout)
                            .font(Font.system(size: 10, design: .rounded))
                            .foregroundStyle(Color.color17)
                            .padding(.bottom, 25)
                        VStack(alignment: .leading, spacing: 10) {
                            Group {
                                Text(info.priorText)
                                VStack(alignment: .trailing) {
                                    Image(info.middelPhoto)
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(radius / 2)
                                    Text(info.photoCaption)
                                        .foregroundStyle(Color.color17)
                                        .font(.caption)
                                }
                                .padding(10)
                                Text(info.latterText)
                            }
                        }
                        .font(.body)
                        .lineSpacing(10)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    ZStack {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: radius,
                            bottomTrailingRadius: radius,
                            topTrailingRadius: 0,
                            style: .continuous)
                            .foregroundStyle(
                                .white.opacity(0.7)
                            )
                            
                        Text("확 인")
                    }
                    .frame(height: 60)
                    .onTapGesture {
                        DispatchQueue.main.async {
                            withAnimation {
                                self.infoState = .none
                            }
                        }
                    }
                }
                .foregroundStyle(.black)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: radius)
                            .foregroundStyle(.gray.opacity(0.7))
                    }
                }
                .padding(40)
                .frame(maxWidth: widthLimit)
            } else {
                EmptyView()
            }
        }
    }
    
    func getInfo(cases : Info) -> InfoObject! {
        return InfoObject(
            title: "가려진 사진 안내",
            semiTitle: "가려진 사진이 있음에도 없다고 나오나요?",
            priorText: "Apple의 정책상, 기본 사진 앱에서 \"Face ID(또는 암호) 사용\"을 켜면\n사진App(애플 자체 앱)을 제외한 앱에서는 가려진 사진을 볼 수 없습니다.",
            middelPhoto: "faceID",
            photoCaption: "기기의 [설정 > 앱 > 사진App]",
            latterText: "[마이 리틀 앨범]에서 가려진 사진을 관리하려면, 위 설정을 off해 주세요."
        )
    }
}
struct InfoObject {
    let title: String
    var semiTitle: String = ""
    var priorText: String = ""
    var middelPhoto: String = ""
    var photoCaption: String = ""
    var latterText: String = ""
}

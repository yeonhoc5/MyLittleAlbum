//
//  SectionFundamentalView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/4/24.
//
import SwiftUI

struct SectionFundamentalView<Header: View>: View {
    var header: Header
    @Binding var uiMode: UIMode
    @Binding var useOpeningAni: Bool
    @Binding var settingList: SettingList
    @Binding var useKnock: Bool
    
    @Binding var isShowingSettingGuide: Bool
    
    init(header: @escaping () -> Header,
         uiMode: Binding<UIMode>,
         useOpeningAni: Binding<Bool>,
         settingList: Binding<SettingList>,
         useKnock: Binding<Bool>,
         isShowingSettingGuide: Binding<Bool>) {
        self.header = header()
        self._uiMode = uiMode
        self._useOpeningAni = useOpeningAni
        self._settingList = settingList
        self._useKnock = useKnock
        self._isShowingSettingGuide = isShowingSettingGuide
        settingSegmentAppearance()
    }
    
    var body: some View {
        Section {
            // 1. ui 스킨 설정
            settingUI
            // 2. 오프닝 애니메이션 사용 설정
            SettingToggleView(number: 2, title: "오프닝 애니메이션",
                              value: $useOpeningAni,
                              addGuide: true,
                              showGuide: $isShowingSettingGuide,
                              settingGuide: $settingList,
                              guideList: .opening)
            // 3. 노크 기능 사용 설정
            SettingToggleView(number: 3, title: "노크 기능",
                              value: $useKnock,
                              addGuide: true,
                              showGuide: $isShowingSettingGuide,
                              settingGuide: $settingList,
                              guideList: .knock)
            // 4. (2, 3 내용) 가이드
            if isShowingSettingGuide {
                settingGuide(item: settingList)
                    .overlay(alignment: .topTrailing) {
                        closeButton()
                    }
            }
        } header: {
            header
        }
        .listRowBackground(Color.white)
    }
}

#Preview {
    SettingView(isShowingSettingView: .constant(true))
        .environmentObject(PhotoData())
}


extension SectionFundamentalView {
    var settingUI: some View {
        VStack(content: {
            HStack(spacing: 30) {
                Text("❶  스킨 설정")
                Picker(selection: $uiMode) {
                    ForEach(UIMode.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                } label: {
                    Text("❶  스킨 설정")
                }
                .pickerStyle(.segmented)
            }
            GeometryReader(content: { geometry in
                let size = geometry.size
                ZStack(alignment: .center, content: {
                    Rectangle()
                        .foregroundStyle(.clear)
                    SkinSampleView(uiMode: uiMode,
                                   size: CGSizeMake(size.width,
                                                    size.height))
                        .clipped()
                        .shadow(radius: 1)
                        .scaleEffect(0.7)
                })
            })
            .frame(height: 200)
        })
    }
    
    func settingGuide(item: SettingList) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(content: {
                Text(settingList.rawValue)
                    .foregroundColor(Color.white)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            })
            switch settingList {
            case .opening:
                Text("기능을 끄면 앱이 열리는 시간은 조금 빨라지겠지만\n하찮고도 귀여운 둥이(고양이)의 용맹한 울부짖음은 볼 수 없습니다. (소리도 납니다.)")
            case .knock:
                VStack {
                    Text("각 앨범 오른쪽 상단에 똑똑똑(3번) 노크를 하면\n해당 앨범의 가려진 사진을 볼 수 있습니다.\n(인증 후 볼 수 있습니다.)")
                    Image("knock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: screenSize.width * 0.8)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
        .font(.callout)
        .foregroundColor(Color.white.opacity(0.7))
        .animation(.bouncy(),
                   value: settingList )
        .listRowBackground(Color.white.opacity(0.1))
    }
    
    func closeButton() -> some View {
        Image(systemName: "x.circle.fill")
            .foregroundStyle(.white)
            .font(.system(size: 23))
            .onTapGesture {
                withAnimation {
                    isShowingSettingGuide = false
                }
            }
    }
    
    func settingSegmentAppearance() {
        // 시그먼트
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor.white
        appearance.backgroundColor = .white
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
    }
}

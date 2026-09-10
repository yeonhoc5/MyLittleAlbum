//
//  SectionFundamentalView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/4/24.
//
import SwiftUI

struct SectionFundamentalView<Header: View>: View {
  @EnvironmentObject var photoData: MLPhotoData
  var header: Header
  @Binding var startView: Tabs
  @Binding var uiMode: UIMode
  @Binding var useOpeningAni: Bool
  @Binding var settingList: SettingList
  @Binding var useKnock: Bool
  
  @Binding var isShowingSettingGuide: Bool
  
  init(header: @escaping () -> Header,
       startView: Binding<Tabs>,
       uiMode: Binding<UIMode>,
       useOpeningAni: Binding<Bool>,
       settingList: Binding<SettingList>,
       useKnock: Binding<Bool>,
       isShowingSettingGuide: Binding<Bool>) {
    self.header = header()
    self._startView = startView
    self._uiMode = uiMode
    self._useOpeningAni = useOpeningAni
    self._settingList = settingList
    self._useKnock = useKnock
    self._isShowingSettingGuide = isShowingSettingGuide
    settingSegmentAppearance()
    settingToggleAppearance()
  }
  
  var body: some View {
    Section {
//      settingStartView(change: photoData.startView != self.startView)
      // 1. ui 스킨 설정
      settingUI(change: photoData.uiMode != self.uiMode)
      // 2. 오프닝 애니메이션 사용 설정
      SettingToggleView(number: 2, title: "오프닝 애니메이션",
                        isOn: $useOpeningAni,
                        change: photoData.useOpeningAni != self.useOpeningAni,
                        addGuide: true,
                        showGuide: $isShowingSettingGuide,
                        settingGuide: $settingList,
                        guideList: .opening)
      // 3. 노크 기능 사용 설정
      SettingToggleView(number: 3, title: "노크 기능",
                        isOn: $useKnock,
                        change: photoData.useKnock != self.useKnock,
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

extension SectionFundamentalView {
  func settingStartView(change: Bool) -> some View {
    HStack(spacing: 30) {
      Text("❶  시작 화면")
        .foregroundStyle(change ? Color.blue : Color.black)
      Picker(selection: $startView) {
        ForEach([Tabs.album], id: \.self) {
          Text($0.rawValue)
        }
      } label: {
        Text("❶  시작 화면")
      }
      .pickerStyle(.segmented)
    }
  }
  func settingUI(change: Bool) -> some View {
    VStack(content: {
      HStack(spacing: 30) {
        Text("❶  스킨 설정")
          .foregroundStyle(change ? Color.blue : Color.black)
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
          TabView(selection: $uiMode) {
            ForEach(UIMode.allCases, id: \.self) { uimode in
              SkinSampleView(uiMode: uimode,
                             size: CGSize(width: size.width,
                                          height: size.height))
              .clipped()
              .shadow(radius: 1)
              .scaleEffect(0.7)
              .tag(uimode)
            }
          }
          .animation(.easeInOut, value: uiMode)
          .tabViewStyle(.page(indexDisplayMode: .never))
        })
      })
      .mask({
        Rectangle()
          .fill(LinearGradient(
            gradient: Gradient(colors: [
              .white.opacity(0),
              .white.opacity(0.5),
              .white.opacity(0.85),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(1), .white.opacity(1),
              .white.opacity(0.85),
              .white.opacity(0.5),
              .white.opacity(0)]),
            startPoint: .leading, endPoint: .trailing))
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
          Text("각 앨범 하단의 상태바에 똑똑똑(3번) 노크를 하면\n해당 앨범의 가려진 사진을 볼 수 있습니다.\n(인증 후 볼 수 있습니다.)")
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
  
  func settingToggleAppearance() {
    // Toggle Switch
//    let appearance = UISwitch.appearance()
//    appearance.onTintColor = .orange // Sets the on color
//    appearance.tintColor = .red    // Sets the off color (track color when off)
//    appearance.thumbTintColor = .white // Sets the thumb color
  }
  
}

#Preview {
  SettingView(isShowing: .constant(true),
              tutorialOn: .constant(false))
    .environmentObject(PhotoData())
}

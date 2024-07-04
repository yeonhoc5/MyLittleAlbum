//
//  FunctionSettingView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/4/24.
//
import SwiftUI

struct FunctionSettingView<Header: View>: View {
    var header: Header
    @Binding var uiMode: UIMode
    @Binding var useOpeningAni: Bool
    @Binding var settingList: SettingList
    @Binding var useKnock: Bool
    @Binding var transitionIndex: Int
    
    @Binding var isShowingSettingGuide: Bool
    
    init(header: @escaping () -> Header,
         uiMode: Binding<UIMode>,
         useOpeningAni: Binding<Bool>,
         settingList: Binding<SettingList>,
         useKnock: Binding<Bool>,
         transitionIndex: Binding<Int>,
         isShowingSettingGuide: Binding<Bool>) {
        self.header = header()
        self._uiMode = uiMode
        self._useOpeningAni = useOpeningAni
        self._settingList = settingList
        self._useKnock = useKnock
        self._transitionIndex = transitionIndex
        self._transitionIndex = transitionIndex
        self._isShowingSettingGuide = isShowingSettingGuide
    }
    
    var body: some View {
        Form {
            Section {
                settingUI
                settingOpeningAni
                settingKnock
                settingDigitalShow(time: transitionRange[transitionIndex])
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
        .foregroundStyle(Color.fancyBackground)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    SettingView(isShowingSettingView: .constant(true))
        .environmentObject(PhotoData())
}


extension FunctionSettingView {
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
                .onAppear(perform: {
                    let appearance = UISegmentedControl.appearance()
                    appearance.selectedSegmentTintColor = .orange
                    appearance.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                })
            }
            SkinSampleView(uiMode: uiMode)
                .scaleEffect(0.5)
                .frame(width: 200, height: 150)
        })
    }
    
    var settingOpeningAni: some View {
        HStack {
            Toggle(isOn: $useOpeningAni, label: {
                HStack {
                    Text("❷  오프닝 애니메이션 설정")
                    Button(action: {
                        withAnimation {
                            settingList = .opening
                            isShowingSettingGuide = true
                        }
                    }, label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(Color.blue)
                    })
                    .foregroundColor(Color.blue)
                    Spacer()
                    Text(useOpeningAni ? "on" : "off")
                        .foregroundColor(.gray)
                        .frame(width: 30, alignment: .leading)
                        .animation(.bouncy, value: useOpeningAni)
                }
                
            })
            .toggleStyle(.switch)
            .tint(useOpeningAni ? .orange : .gray)
        }
    }
    
    var settingKnock: some View {
        HStack {
            Toggle(isOn: $useKnock, label: {
                HStack {
                    Text("❸  노크 기능 설정")
                    Button(action: {
                        withAnimation {
                            settingList = .knock
                            isShowingSettingGuide = true
                        }
                    }, label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(Color.blue)
                    })
                    .foregroundColor(Color.blue)
                    Spacer()
                    Text(useKnock ? "on" : "off")
                        .foregroundColor(.gray)
                        .frame(width: 30, alignment: .leading)
                        .animation(.bouncy, value: useKnock)
                }
            })
            .tint(.orange)
        }
    }
    
    func settingDigitalShow(time: Int) -> some View {
        HStack(content: {
            Stepper(value: $transitionIndex,
                    in: 0...(transitionRange.count-1),
                    step: 1) {
                HStack {
                    Text("❹  디지털액자 전환 주기")
                    Spacer()
                    HStack(spacing: 3, content: {
                        Text("\(time < 60 ? time : (time < 3600 ? time/60 : (time < 86400 ? time/3600 : 1)))")
                            .foregroundColor(Color.blue)
                            .bold()
                        Text("\(time < 60 ? "초" : (time < 3600 ? "분" : (time < 86400 ? "시간" : "일")))")
                    })
                    Spacer()
                }
            }
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
}

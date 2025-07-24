//
//  SectionDigitalView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/9/24.
//

import SwiftUI

struct SectionDigitalView<Header: View>: View {
    var header: Header
    @Binding var isRandom: Bool
    let randomChanged: Bool
    let currentIndex: Int
    @Binding var changedIndex: Int
    
    init(header: @escaping () -> Header,
         isRandom: Binding<Bool>,
         randomChanged: Bool,
         currentIndex: Int,
         changedIndex: Binding<Int>) {
        self.header = header()
        self._isRandom = isRandom
        self.randomChanged = randomChanged
        self.currentIndex = currentIndex
        self._changedIndex = changedIndex
    }
    
    var body: some View {
        Section {
            // 디지털 액자 - 사진 전환 시간
            settingTransitionTime
            // 디지털 액자 - 사진 전환 : 랜덤 / 순서대로
            settingPlayOrder(isRandom: $isRandom)
        } header: {
            header
        }
        .listRowBackground(Color.white)
    }
}

extension SectionDigitalView {
    var settingTransitionTime: some View {
        let current = transitionRange[currentIndex]
        let toChange = transitionRange[changedIndex]
        return HStack(content: {
            Stepper(value: $changedIndex,
                    in: 0...(transitionRange.count-1),
                    step: 1) {
                HStack {
                    Text("❶  전환 주기")
                    Spacer()
                    HStack(spacing: 3, content: {
                        Text(timeString(current))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(Color.black)
                        Text(timeUnit(current))
                        Group {
                            if currentIndex != changedIndex {
                                Text(" → ")
                                Text(timeString(toChange))
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundColor(Color.blue)
                                Text(timeUnit(toChange))
                                    .foregroundColor(Color.blue)
                            }
                        }
                        .contentTransition(.numericText())
                    })
                    .animation(.easeOut, value: currentIndex != changedIndex)
                    .transition(.opacity)
                    Spacer()
                }
            }
        })
    }
    func timeString(_ time: Int) -> String {
        return String(time < 60
                      ? time : (time < 3600
                                ? time/60 : (time < 86400 ? time/3600 : 1)))
    }
    func timeUnit(_ time: Int) -> String {
        return time < 60 ? "초" : (time < 3600 ? "분" : (time < 86400 ? "시간" : "일"))

    }
    func settingPlayOrder(isRandom: Binding<Bool>) -> some View {
        HStack(spacing: 30) {
            Text("❷  순서")
            Picker(selection: $isRandom) {
                Group {
                    Text("차례대로")
                        .tag(false)
                    Text("랜덤")
                        .tag(true)
                }
                .font(.caption)
            } label: {
                Text("❷  사진 플레이 순서")
            }
            .pickerStyle(.segmented)
        }
    }
}

#Preview {
    SettingView(isShowingSettingView: .constant(true))
        .environmentObject(PhotoData())
}

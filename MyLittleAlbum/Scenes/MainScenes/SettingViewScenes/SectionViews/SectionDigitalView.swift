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
    @Binding var transitionIndex: Int
    
    init(header: @escaping () -> Header,
         isRandom: Binding<Bool>,
         transitionIndex: Binding<Int>) {
        self.header = header()
        self._isRandom = isRandom
        self._transitionIndex = transitionIndex
    }
    
    var body: some View {
        Section {
            // 디지털 액자 - 사진 전환 시간
            settingTransitionTime(time: transitionRange[transitionIndex])
            // 디지털 액자 - 사진 전환 : 랜덤 / 순서대로
            settingPlayOrder(isRandom: $isRandom)
        } header: {
            header
        }
        .listRowBackground(Color.white)
    }
}

extension SectionDigitalView {
    func settingTransitionTime(time: Int) -> some View {
        HStack(content: {
            Stepper(value: $transitionIndex,
                    in: 0...(transitionRange.count-1),
                    step: 1) {
                HStack {
                    Text("❶  사진 전환 주기")
                    Spacer()
                    HStack(spacing: 3, content: {
                        Text("\(time < 60 ? time : (time < 3600 ? time/60 : (time < 86400 ? time/3600 : 1)))")
                            .foregroundColor( Color.blue)
                            .bold()
                        Text("\(time < 60 ? "초" : (time < 3600 ? "분" : (time < 86400 ? "시간" : "일")))")
                    })
                    Spacer()
                }
            }
        })
    }
    func settingPlayOrder(isRandom: Binding<Bool>) -> some View {
        HStack(spacing: 30) {
            Text("❷  사진 순서")
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

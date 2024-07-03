//
//  FunctionSettingView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/2/24.
//

import SwiftUI

struct FunctionSettingView: View {
    @Binding var uiMode: UIMode
    
    var body: some View {
        Form {
            Section {
                settingUI
                settingOpeningAni
                settingKnock
                settingDigitalShow(time: transitionRange[transitionIndex])
            } header: {
                headerText(str: "1.  기능 설정")
            }
            .listRowBackground(Color.white)
        }
        .foregroundStyle(Color.fancyBackground)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    FunctionSettingView()
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
            sampleView
                .scaleEffect(0.5)
                .frame(width: 200, height: 150)
        })
    }
    
    
    
    
}

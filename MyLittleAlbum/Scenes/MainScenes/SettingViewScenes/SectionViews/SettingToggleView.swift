//
//  SettingToggleView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 7/9/24.
//

import SwiftUI

struct SettingToggleView: View {
    var number: Int
    var title: String
    @Binding var value: Bool

    var textTrue: String = "On"
    var textFalse: String = "Off"
    
    var addGuide: Bool = false
    @Binding var showGuide: Bool
    @Binding var settingGuide: SettingList
    var guideList: SettingList = .opening
    
    var body: some View {
        HStack {
            Toggle(isOn: $value, label: {
                HStack {
                    Text("\(numbering(int: number))  \(title)")
                    if addGuide {
                        Button(action: {
                            withAnimation {
                                settingGuide = guideList
                                showGuide = true
                            }
                        }, label: {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(Color.blue.opacity(0.7))
                        })
                        .foregroundColor(Color.blue)
                    }
                    Spacer()
                    Text(value ? textTrue : textFalse)
                        .foregroundColor(.blue)
                        .bold()
                        .frame(width: 30, alignment: .leading)
                }
            })
            .toggleStyle(.switch)
            .tint(value ? .blue.opacity(0.7) : .white)
        }
    }
    
    
    func numbering(int: Int) -> String {
        let numbsers = ["❶", "❷", "❸", "❹", "❺", "❻", "❼", "❽", "❾"]
        return numbsers[(int - 1) % numbsers.count]
    }
}

#Preview {
    SettingToggleView(number: 1, 
                      title: "토글뷰",
                      value: .constant(true),
                      showGuide: .constant(false),
                      settingGuide: .constant(.opening),
                      guideList: .opening
                      
    )
}

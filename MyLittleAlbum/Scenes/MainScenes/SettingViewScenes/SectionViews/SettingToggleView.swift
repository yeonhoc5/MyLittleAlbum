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
  @Binding var isOn: Bool
  let change: Bool
  
  var textTrue: String = "oN"
  var textFalse: String = "oFF"
  
  var addGuide: Bool = false
  @Binding var showGuide: Bool
  @Binding var settingGuide: SettingList
  var guideList: SettingList = .opening
  
  var body: some View {
    HStack {
      Toggle(isOn: $isOn, label: {
        HStack {
          Text("\(numbering(int: number))  \(title)")
            .foregroundStyle(change ? Color.blue : Color.black)
          if addGuide {
            Button(action: {
              withAnimation {
                if settingGuide != guideList {
                  settingGuide = guideList
                  showGuide = true
                } else {
                  showGuide = false
                }
              }
            }, label: {
              Image(systemName: "questionmark.circle")
                .foregroundStyle(Color.blue)
            })
          }
          Spacer()
          Text(isOn ? textTrue : textFalse)
            .bold()
            .frame(width: 30, alignment: .leading)
        }
      })
      .tint(Color.color19)
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
                    isOn: .constant(true),
                    change: false,
                    showGuide: .constant(false),
                    settingGuide: .constant(.opening),
                    guideList: .opening
                    
  )
}

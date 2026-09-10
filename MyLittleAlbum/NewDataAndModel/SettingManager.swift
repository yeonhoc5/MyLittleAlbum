//
//  SettingManager.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 8/19/26.
//

import Foundation

struct SettingState {
  var startTab: Tabs = .album
  var uiMode: UIMode = .modern
  var useOpeningAni: Bool = false
  var useKnock: Bool = true
  var isRandomPlay: Bool = true
  var transitionIndex: Int = 2
}

class SettingManager: Observable, ObservableObject {
  var settingState = SettingState() {
    didSet {
      
    }
  }
  
  init() {
    
  }
  
  
  private func saveSetting() {
    
  }
}

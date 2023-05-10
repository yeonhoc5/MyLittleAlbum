//
//  LaunchScreenManager.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/01/18.
//

import Foundation
import SwiftUI

enum LaunchScreenPhase {
    case ready
    case first
    case second
    case third
    case forth
    case complete
}

class LaunchScreenManager: ObservableObject {
    @Published var state: LaunchScreenPhase = .ready
    @Published var isOpend: Bool = false
    
    deinit {
    }
}

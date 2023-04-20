//
//  ColorTest.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import SwiftUI

struct ColorTest: View {
    let color: Color
    var body: some View {
            Circle()
                .frame(width: 50, height: 50)
                .foregroundColor(color)
    }
}

struct ColorTest_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack {
                ColorTest(color: .color1)
                ColorTest(color: .color2)
                ColorTest(color: .color3)
                ColorTest(color: .color4)
            }
            HStack {
                ColorTest(color: .color5)
                ColorTest(color: .color6)
                ColorTest(color: .color7)
                ColorTest(color: .color8)
            }
            HStack {
                ColorTest(color: .color9)
                ColorTest(color: .color10)
                ColorTest(color: .color11)
                ColorTest(color: .color12)
            }
            HStack {
                ColorTest(color: .color13)
                ColorTest(color: .color14)
                ColorTest(color: .color15)
                ColorTest(color: .color16)
            }
            
            HStack {
                ColorTest(color: .color17)
                ColorTest(color: .color18)
                ColorTest(color: .color19)
                ColorTest(color: .color20)
            }
            
            HStack {
                
                ColorTest(color: .color21)
                ColorTest(color: .color22)
                ColorTest(color: .color23)
                ColorTest(color: .color24)
            }
            
            HStack {
                ColorTest(color: .color25)
                ColorTest(color: .color26)
                ColorTest(color: .color27)
                ColorTest(color: .color28)
                
                
            }
            
        }
    }
}

extension Color {
    static let primaryColorInvert = Color(UIColor.systemBackground)

    static let fancyBackground = Color(red: 0/255, green: 8/255, blue: 30/255)
    static let folder = Color(red: 0, green: 42/255, blue: 99/255)
    
    static let color1 = Color(red: 230/255, green: 90/255, blue: 72/255)
    static let color2 = Color(red: 243/255, green: 185/255, blue: 0/255)
    static let color3 = Color(red: 0/255, green: 150/255, blue: 168/255)
    static let color4 = Color(red: 209/255, green: 122/255, blue: 127/255)
    
    static let color5 = Color(red: 82/255, green: 145/255, blue: 0/255)
    static let color6 = Color(red: 37/255, green: 120/255, blue: 224/255)
    static let color7 = Color(red: 140/255, green: 54/255, blue: 167/255)
    static let color8 = Color(red: 0/255, green: 186/255, blue: 206/255)
    
    
    static let color9 = Color(red: 249/255, green: 118/255, blue: 220/255)
    static let color10 = Color(red: 137/255, green: 150/255, blue: 255/255)
    static let color11 = Color(red: 197/255, green: 198/255, blue: 40/255)
    static let color12 = Color(red: 239/255, green: 234/255, blue: 145/255)

    
    static let color13 = Color(red: 255/255, green: 92/255, blue: 118/255)
    static let color14 = Color(red: 0/255, green: 85/255, blue: 0/255)
    static let color15 = Color(red: 249/255, green: 204/255, blue: 105/255)
    static let color16 = Color(red: 212/255, green: 54/255, blue: 0/255)
    
    
    static let color17 = Color(red: 148/255, green: 203/255, blue: 236/255)
    static let color18 = Color(red: 212/255, green: 64/255, blue: 163/255)
    static let color19 = Color(red: 52/255, green: 178/255, blue: 102/255)
    static let color20 = Color(red: 164/255, green: 21/255, blue: 3/255)
    
    
    static let color21 = Color(red: 151/255, green: 95/255, blue: 139/255)
    static let color22 = Color(red: 40/255, green: 100/255, blue: 188/255)
    static let color23 = Color(red: 0/255, green: 219/255, blue: 182/255)
    static let color24 = Color(red: 154/255, green: 43/255, blue: 111/255)

    
    static let color25 = Color(red: 109/255, green: 128/255, blue: 139/255)
    static let color26 = Color(red: 102/255, green: 198/255, blue: 92/255)
    static let color27 = Color(red: 147/255, green: 0/255, blue: 66/255)
    static let color28 = Color(red: 30/255, green: 65/255, blue: 175/255)
    
    
    
    static let disabledColor = Color(red: 196/255, green: 196/255, blue: 196/255)
    static let selectedColor = colorSet[1]
    static let nonSelectedColor = Color.fancyBackground
}

//
//  ColorTest.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2022/12/11.
//

import SwiftUI

let colorSet: [Color] = [.color1, .color2, .color3, .color4, .color5,
                         .color6, .color7, .color8, .color9, .color10,
                         .color11, .color12, .color13, .color14, .color15,
                         .color16, .color17, .color18, .color19, .color20,
                         .color21, .color22, .color23, .color24, .color25,
                         .color26, .color27, .color28]


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
                Text("stack1")
                ColorTest(color: .color1)
                ColorTest(color: .color2)
                ColorTest(color: .color3)
                ColorTest(color: .color4)
            }
            HStack {
                Text("stack2")
                ColorTest(color: .color5)
                ColorTest(color: .color6)
                ColorTest(color: .color7)
                ColorTest(color: .color8)
            }
            HStack {
                Text("stack3")
                ColorTest(color: .color9)
                ColorTest(color: .color10)
                ColorTest(color: .color11)
                ColorTest(color: .color12)
            }
            HStack {
                Text("stack4")
                ColorTest(color: .color13)
                ColorTest(color: .color14)
                ColorTest(color: .color15)
                ColorTest(color: .color16)
            }
            
            HStack {
                Text("stack5")
                ColorTest(color: .color17)
                ColorTest(color: .color18)
                ColorTest(color: .color19)
                ColorTest(color: .color20)
            }
            
            HStack {
                Text("stack6")
                ColorTest(color: .color21)
                ColorTest(color: .color22)
                ColorTest(color: .color23)
                ColorTest(color: .color24)
            }
            
            HStack {
                Text("stack7")
                ColorTest(color: .color25)
                ColorTest(color: .color26)
                ColorTest(color: .color27)
                ColorTest(color: .color28)
                
                
            }
            
        }
    }
}

extension Color {
    static func rgbColor(_ red: Double, _ green : Double, _ blue: Double) -> Color {
        return Color(red: red/255, green: green/255, blue: blue/255)
    }
    static let primaryColorInvert = Color(UIColor.systemBackground)

    static let fancyBackground = rgbColor(0, 8, 30)
    static let folder = rgbColor(0, 42, 99)
    static let addButton = rgbColor(0, 40, 90)
    static let lightGray = rgbColor(180, 180, 180)

//  static let heart = Color.color1
    static let heart = Color(red: 255/255, green: 105/255, blue: 33/255)
//    static let heart = LinearGradient(colors: [], startPoint: <#T##UnitPoint#>, endPoint: <#T##UnitPoint#>)
    
    static let color1 = rgbColor(230, 90, 72)
    static let color2 = rgbColor(243, 185, 0)
    static let color3 = rgbColor(0, 150, 168)
    static let color4 = rgbColor(209, 122, 127)
    
  static let color5 = rgbColor(82, 145, 0);
    static let color6 = rgbColor(37, 120, 224)
    static let color7 = rgbColor(140, 54, 167)
    static let color8 = rgbColor(0, 186, 206)
    
    static let color9 = rgbColor(249, 118, 220)
    static let color10 = rgbColor(137, 150, 255)
    static let color11 = rgbColor(197, 198, 40)
    static let color12 = rgbColor(239, 234, 145)
    
    static let color13 = rgbColor(255, 92, 118)
    static let color14 = rgbColor(0, 85, 0)
    static let color15 = rgbColor(249, 204, 105)
    static let color16 = rgbColor(212, 54, 0)
    
    static let color17 = rgbColor(148, 203, 236)
    static let color18 = rgbColor(212, 64, 163)
    static let color19 = rgbColor(52, 178, 102)
    static let color20 = rgbColor(164, 21, 3)
    
    static let color21 = rgbColor(151, 95, 139)
    static let color22 = rgbColor(40, 100, 188)
    static let color23 = rgbColor(0, 219, 182)
    static let color24 = rgbColor(154, 43, 111)

    static let color25 = rgbColor(109, 128, 139)
    static let color26 = rgbColor(102, 198, 92)
    static let color27 = rgbColor(147, 0, 66)
    static let color28 = rgbColor(30, 65, 175)
    
    
    static let disabledColor = rgbColor(196, 196, 196)
    static let selectedColor = colorSet[1]
    static let nonSelectedColor = Color.fancyBackground
}

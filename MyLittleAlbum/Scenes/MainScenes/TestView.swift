//
//  TestView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 3/26/25.
//

import SwiftUI

extension View {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

struct TestView: View {
    @State var text1: Int = 0
    @State var text2: Int = 1
    
    var body: some View {
        VStack {
            HStack {
                View1(text: text1)
                View2(text: text2)
            }
            .frame(height: 150)
            HStack {
                Button {
                    text1 += 1
                } label: {
                    Capsule()
                }
                Button {
                    text2 += 1
                } label: {
                    Capsule()
                }
            }
            
            .frame(height: 150)
        }
        .padding(20)
        .background {
            Color.black
        }
    }
}

struct View1: View {
    let text: Int
    var body: some View {
        imageNonScaled(systemName: "folder.fill",
                       width: 200,
                       height: 150,
                       color: .random)
            .offset(y: 1)
            .overlay {
                Text("\(text)")
            }
    }
}
struct View2: View {
    let text: Int
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(Color.random)
            .overlay {
                Text("\(text)")
            }
    }
}

#Preview {
    TestView()
}

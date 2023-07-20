//
//  CustomProgressView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/08.
//

import SwiftUI

struct CustomProgressView: View {
    @ObservedObject var stateChangeObject: StateChangeObject
    var color: Color! = .color1
    var size: CGFloat! = 120
    var blurStyle: UIBlurEffect.Style = .systemThickMaterialLight
    
    var body: some View {
        BlurView(style: blurStyle)
            .frame(width: size, height: size)
            .cornerRadius(10)
            .opacity(0.9)
            .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 0)
            .overlay {
                if stateChangeObject.assetChanged == .completed {
                    progressDoneView
                } else {
                    progressView
                }
            }
    }
}

extension CustomProgressView {

    var progressDoneView: some View {
        Image(systemName: "checkmark")
            .font(Font.system(size: 55))
            .foregroundColor(.color1)
            .onAppear {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        stateChangeObject.assetChanged = .done
                    }
                }
            }
    }
    
    
    var progressView: some View {
        ProgressView()
            .progressViewStyle(.circular)
//            .scaleEffect(1.5)
            .tint(color)
    }
}


struct CustomProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let stateObject = StateChangeObject()
        FancyBackground()
            .overlay {
                CustomProgressView(stateChangeObject: stateObject)
                    .onAppear {
                        stateObject.assetChanged = .completed
                    }
            }
            .preferredColorScheme(.dark)
    }
}

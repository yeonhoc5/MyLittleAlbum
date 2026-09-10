//
//  CustomProgressView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/04/08.
//

import SwiftUI

struct CustomProgressView: View {
    var progressName: String = ""
    @Binding var progressState: ProgressViewState
    var color: Color! = .color1
    var size: CGFloat! = 120
    var nameSpace: Namespace.ID
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.ultraThickMaterial)
                .colorScheme(.light)
                .frame(width: size, height: size)
                .opacity(0.9)
                .shadow(color: .gray.opacity(0.5),
                        radius: 5, x: 0, y: 0)
        }
        .overlay {
            Group {
                switch progressState {
                case .start: progressView
                case .done: progressDoneView
                default: EmptyView()
                }
            }
            .transition(.scale)
        }
    }
}

extension CustomProgressView {

    var progressDoneView: some View {
        Image(systemName: "checkmark")
            .font(Font.system(size: 45))
            .foregroundColor(.color1)
            .onAppear {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
            }
    }
    
    
    var progressView: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.large)
            .scaleEffect(0.7)
            .tint(color)
    }
}


struct CustomProgressView_Previews: PreviewProvider {
    static var previews: some View {
        FancyBackground()
            .overlay {
                CustomProgressView(
                    progressName: "코딩",
                    progressState: .constant(.done),
                    nameSpace: Namespace().wrappedValue)
            }
            .preferredColorScheme(.dark)
    }
}

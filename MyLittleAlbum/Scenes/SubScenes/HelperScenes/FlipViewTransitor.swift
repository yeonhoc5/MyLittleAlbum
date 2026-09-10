//
//  FlipViewTransitor.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/13/24.
//

import SwiftUI

struct FlipViewTransitor<ContentA: View, ContentB: View>: View {
    let isModeChange: Bool
    let flipView: () -> ContentA
    let flipReverseView: () -> ContentB
    
    var body: some View {
        ZStack {
            if isModeChange {
                flipReverseView()
                    .transition(.flip)
            } else {
                flipView()
                    .transition(.flipReverse)
            }
        }
    }
}

struct FlipTransition: ViewModifier, Animatable {
    var progress: CGFloat = 0
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content
            .opacity(progress < 0
                     ? (-progress < 0.5 ? 1 : 0)
                     : (progress < 0.5 ? 1 : 0))
            .rotation3DEffect(
                .degrees(180 * progress),
                axis: (x: 1, y: 0, z: 0))
    }
}

extension AnyTransition {
    static let flip: AnyTransition = .modifier(
        active: FlipTransition(progress: 1),
        identity: FlipTransition())
    static let flipReverse: AnyTransition = .modifier(
        active: FlipTransition(progress: -1),
        identity: FlipTransition())
}

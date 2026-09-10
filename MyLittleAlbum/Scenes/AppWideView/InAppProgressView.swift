//
//  InAppProgressView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 11/18/24.
//

import SwiftUI

enum ProgressName: String {
    case takeInAlbum = "앨범에 넣기"
    case takeOutAlbum = "앨범에서 빼기"
    case moveAnotherAlbum = "다른 앨범으로 이동"
    case hide = "가리기"
    case unhide = "가리기 해제"
    case delete = "삭제"
}


struct InAppProgressView: ViewModifier {
    let notificationName: Notification.Name
    @State var progressState: ProgressViewState = .end
    @Namespace var progress
    @State var progressName: String = ""
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if progressState != .end {
                    CustomProgressView(
                        progressName: progressName,
                        progressState: $progressState,
                        nameSpace: progress
                    )
                    .transition(.opacity)
                }
            }
            .onReceive(NotificationCenter.default
                .publisher(for: notificationName)) { object in
                    if let progress = object.object as? String {
                        self.progressName = progress
                    }
                    DispatchQueue.global(qos: .userInitiated)
                        .async {
                            withAnimation {
                                progressState = .start
                            }
                        }
            }
            .onReceive(NotificationCenter.default
                .publisher(for: .showProgressDoneView)) { _ in
                    if progressState != .done {
                        DispatchQueue.global(qos: .userInitiated)
                            .async {
                                withAnimation {
                                    progressState = .done
                                }
                            }
                        DispatchQueue.global(qos: .unspecified)
                            .asyncAfter(deadline: .now() + 1) {
                                withAnimation {
                                    progressState = .end
                                }
                        }
                    }
                }
            .onReceive(NotificationCenter.default
                .publisher(for: .showProgressEndView)) { _ in
                if progressState != .end {
                    DispatchQueue.global(qos: .unspecified).async {
                        withAnimation {
                            progressState = .end
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default
                .publisher(for: .showProgressEndDetailView)) { _ in
                if progressState != .end {
                    DispatchQueue.global(qos: .unspecified).async {
                        withAnimation {
                            progressState = .end
                        }
                    }
                }
            }
    }
}


enum ProgressViewState {
    case start
    case done
    case end
}

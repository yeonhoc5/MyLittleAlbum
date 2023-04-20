//
//  ShareSheet.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 2023/02/01.
//

import SwiftUI
import UIKit
import Photos

//struct ShareSheet: UIViewControllerRepresentable {
//    var shareItem: [Any] = []
//    var applicationActivities: [UIActivity]? = nil
//    @Environment(\.presentationMode) var presentationMode
//
//    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
//        let controller = UIActivityViewController(activityItems: shareItem, applicationActivities: applicationActivities)
//        controller.completionWithItemsHandler = { (activityType, completed, returnItems, error) in
//            self.presentationMode.wrappedValue.dismiss()
//        }
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {
//
//    }
//
//}

struct Photo: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.image)
        }
    public var image: Image
    public var caption: String
    public var url: URL!
}

//struct ShareSheet_Previews: PreviewProvider {
//    static var previews: some View {
//        ShareSheet()
//    }
//}

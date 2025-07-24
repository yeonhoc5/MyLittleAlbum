//
//  NotificationExtenstion.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/3/25.
//

import Foundation
import Photos


extension Notification.Name {
    static let someAlbumFetchChange = Notification.Name("someAlbumFetchChange")
    static let updatePhotosInAlbums = Notification.Name("updatePhotosInAlbums")
    // 미디어 디테일 뷰
    static let showDetailView = Notification.Name("showDetailView")
    static let endDetailView = Notification.Name("endDetailView")
    // 디지털 쇼 뷰
    static let showDigitalShow = Notification.Name("showDigitalShow")
    static let endDigitalShow = Notification.Name("endDigitalShow")
    // 알럿 뷰
    static let showAlert = Notification.Name("showAlert")
    static let showMessage = Notification.Name("showMessage")
    // 프로그레스뷰
    static let showProgressingView = Notification.Name("progressStart")
    static let showProgressDoneView = Notification.Name("progressDone")
    static let showProgressEndView = Notification.Name("progressEnd")
    // sheet 3개 (미디어 이동 / 폴더앨범 이동 / 폴더앨범 순서조정)
    static let showMoveAssetSheet = Notification.Name("showMoveAssetSheet")
    static let showMoveCollectionSheet = Notification.Name("showMoveCollectionSheet")
    static let showReorderSheet = Notification.Name("showReorderSheet")
    static let showPhotosPicker = Notification.Name("showPhotosPicker")
}

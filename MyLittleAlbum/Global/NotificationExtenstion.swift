//
//  NotificationExtenstion.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/3/25.
//

import Foundation
import Photos


extension Notification.Name {
    // 미디어 디테일 뷰
    static let detailViewRemoveAsset = Notification.Name("detailViewDeleteAsset")
    // 디지털 쇼 뷰
    static let showDigitalShow = Notification.Name("showDigitalShow")
    static let endDigitalShow = Notification.Name("endDigitalShow")
    // 알럿 뷰
    static let showAlert = Notification.Name("showAlert")
    static let showMessage = Notification.Name("showMessage")
    static let showAlertInDetailView = Notification.Name("showAlertInDetailView")
    // 프로그레스뷰
        // 콜렉션뷰 사진 작업
    static let assetWorkStart = Notification.Name("assetWorkStart")
    static let assetWorkDone = Notification.Name("assetWorkDone")
    // 기본 뷰
    static let showProgressingView = Notification.Name("progressStart")
    static let showProgressDoneView = Notification.Name("progressDone")
    static let showProgressEndView = Notification.Name("progressEnd")
    // 디테일뷰
    static let showProgressingDetailView = Notification.Name("progressStartDetail")
    static let showProgressDoneDetailView = Notification.Name("progressDoneDetail")
    static let showProgressEndDetailView = Notification.Name("progressEndDetail")
    // sheet 3개 (미디어 이동 / 폴더앨범 이동 / 폴더앨범 순서조정)
    static let showMoveAssetSheet = Notification.Name("showMoveAssetSheet")
    static let showMoveAssetSheetInDetailView = Notification.Name("showMoveAssetSheetInDetailView")
    static let showMoveCollectionSheet = Notification.Name("showMoveCollectionSheet")
    static let showReorderSheet = Notification.Name("showReorderSheet")
    static let showPhotosPicker = Notification.Name("showPhotosPicker")
    static let showInfoView = Notification.Name("showInfoView")
    
    // album FetchResult change
    static let innerFetchChange = Notification.Name("innerFetchChange")
    static let outsideFetchChange = Notification.Name("outsideFetchChange")
    static let changeRprstPhotos = Notification.Name("changeRprstPhotos")
    static let assetChanged = Notification.Name("assetChanged")
}

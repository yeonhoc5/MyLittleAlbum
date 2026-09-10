//
//  AssetShareManager.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 6/22/26.
//

import UIKit
import Photos

class AssetShareManager {
  static let shared = AssetShareManager()
  
  func prepareAssetForSharing(_ assets: [PHAsset],
                              completion: @escaping ([URL]) -> Void) {
    var urls: [URL] = []
    for asset in assets {
      if asset.mediaType == .image {
        // Handle Images
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        PHImageManager.default()
          .requestImageDataAndOrientation(for: asset,
                                          options: options) { data, _, _, info in
          guard let data = data else {
            return
          }
          var fileExtension = "jpg"
          if let uti = info?["PHImageFileURLKey"] as? URL {
            fileExtension = uti.pathExtension
          }
          
          // Save to local temp directory
          let tempURL = FileManager.default
              .temporaryDirectory
              .appendingPathComponent(UUID().uuidString)
              .appendingPathExtension(fileExtension)
          do {
            try data.write(to: tempURL)
            urls.append(tempURL)
          } catch {
            return
          }
        }
        
      } else if asset.mediaType == .video {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        // Request export session to get a clean file container
        PHImageManager.default()
          .requestExportSession(forVideo: asset,
                                options: options,
                                exportPreset: AVAssetExportPresetPassthrough) { exportSession, _ in
          guard let exportSession = exportSession
            else { return }
          
          let tempURL = FileManager.default
              .temporaryDirectory
              .appendingPathComponent(UUID().uuidString)
              .appendingPathExtension("mp4")
          
          exportSession.outputURL = tempURL
          exportSession.outputFileType = .mp4
          exportSession.exportAsynchronously {
            if exportSession.status == .completed {
              urls.append(tempURL)
            } else {
              return
            }
          }
        }
      } else {
        return
      }
      if urls.count == assets.count {
        completion(urls)
      }
    }
  }
}

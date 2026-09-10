//
//  GridCell.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/7/25.
//

import SwiftUI
import Photos


class GridCell: UICollectionViewCell {
  var id: String!
  var asset: MLAsset!
  var width: CGFloat!
  var imageManager: PHCachingImageManager!
  
  lazy var imageView: UIImageView! = {
    let imgView = UIImageView()
    imgView.contentMode = .scaleAspectFill
    imgView.layer.cornerRadius = 1
    imgView.clipsToBounds = true
    return imgView
  }()
  
  lazy var durationLabel: UILabel! = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 12, weight: .bold, width: .standard)
    label.textAlignment = .right
    label.textColor = .white
    return label
  }()
  //  lazy var gifLabelView: UILabel! = {
  //    let label = UILabel()
  //    label.text = "GIF"
  //    label.font = .systemFont(ofSize: 12, weight: .heavy, width: .standard)
  //    label.textAlignment = .center
  //    label.textColor = .black
  //    label.backgroundColor = .white
  //    label.layer.cornerRadius = 3
  //    return label
  //  }()
  
  lazy var checkMarkView: UIImageView! = {
    let checkMark = "checkmark.circle.fill"
    let checkMarkView = UIImageView(image: UIImage(systemName: checkMark))
    checkMarkView.backgroundColor = .white
    checkMarkView.layer.opacity = 0
    return checkMarkView
  }()
  
  lazy var favoriteMarkView: UIImageView! = {
    let maskView = UIImageView(image: UIImage(systemName: iconFavorite))
    maskView.contentMode = .scaleAspectFit
    let favoriteView = UIImageView(image: UIImage(named: "CrayonRed"))
//    let favoriteView = UIImageView(image: UIImage(named: "starMark2"))
    favoriteView.mask = maskView
    favoriteView.layer.masksToBounds = true
    favoriteView.contentMode = .scaleAspectFit
//    favoriteView.layer.opacity = 0.5
    return favoriteView
  }()
  
  lazy var pickerButtonView: UIImageView! = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "plus")
    imageView.tintColor = UIColor(Color.white.opacity(0.5))
    return imageView
  }()
  lazy var blurStackView: UIStackView! = {
    let stack = UIStackView()
    let effect = UIBlurEffect(style: .systemThickMaterialLight)
    let blur = UIVisualEffectView(effect: effect)
    blur.frame = stack.bounds
    blur.layer.cornerRadius = 3
    blur.clipsToBounds = true
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    stack.insertSubview(blur, at: 0)
    return stack
  }()
  lazy var volumeView: UILabel! = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 9, weight: .semibold)
    label.textAlignment = .center
    label.numberOfLines = 1
    label.textColor = UIColor(Color.fancyBackground)
    label.layer.cornerRadius = 3
    label.clipsToBounds = true
    return label
  }()
  
  func changeImage(image: UIImage) {
    DispatchQueue.main.async {
      self.imageView.image = image
    }
  }
  
  var duration: TimeInterval! {
    didSet {
      let duration: Int = Int(duration / 1.0)
      let hour: String = duration >= 3600 ? "\(duration / 3600):" : ""
      let minute: String = "\(((duration) % 3600) / 60):"
      let second: String = (duration) % 60 >= 10 ? "\((duration) % 60)" : "0\((duration) % 60)"
      durationLabel.text = hour + minute + second
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    durationLabel.text = nil
    [checkMarkView, favoriteMarkView, blurStackView]
      .forEach { view in
        view?.layer.opacity = 0
    }
  }
  
  deinit {
    self.imageManager = nil
  }
  
  // MARK: Setting View
  func settingCellBase(asset: MLAsset, cellWidth: CGFloat) {
    self.id = asset.id
    self.asset = asset
    self.width = cellWidth
    contentView.layer.backgroundColor = UIColor(.fancyBackground).cgColor
    //
    contentView.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 1).cgPath
    contentView.layer.shadowColor = UIColor.gray.cgColor
    contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
    contentView.layer.shadowOpacity = 0.3
    contentView.layer.shadowRadius = 0.5
    contentView.layer.masksToBounds = false
    contentView.layer.shouldRasterize = true
    contentView.layer.rasterizationScale = UIScreen.main.scale
  }
  func settingCell(isVideoCell: Bool = false,
                   isSelected: Bool,
                   isVolumeView: Bool) {
    let padding: CGFloat = width / 20
    let markWidth: CGFloat = width / 4.5
    phImageQueue.async {
      self.loadFullImage()
    }
    [imageView, checkMarkView, favoriteMarkView, blurStackView].forEach {
      addSubview($0)
    }
    // 0. image View
    imageView.frame = CGRect(x: 0, y: 0,
                             width: width,
                             height: width)
    // 1. favoriteMark View
    favoriteMarkView.frame = CGRect(x: padding,
                                    y: padding,
                                    width: markWidth,
                                    height: markWidth)
    favoriteMarkView.mask?.frame = favoriteMarkView.bounds
    favoriteMarkView.clipsToBounds = false
    // 2. checkMark View
    checkMarkView.frame = CGRect(x: width - (markWidth + padding),
                                 y: width - (markWidth + padding),
                                 width: markWidth,
                                 height: markWidth)
    checkMarkView.layer.cornerRadius = checkMarkView.frame.width / 2
    // 4. voulum View
    blurStackView.frame = CGRect(
                  x: padding + markWidth,
                  y: padding,
                  width: width - (padding + markWidth + padding),
                  height: markWidth
                )
    if isVolumeView {
      volumeView.frame = blurStackView.bounds
      volumeView.autoresizingMask = [.flexibleWidth,
                                     .flexibleHeight]
      blurStackView.insertSubview(volumeView, at: 1)
      let formatter = ByteCountFormatter()
      formatter.countStyle = .file
      formatter.allowedUnits = [.useKB, .useMB, .useGB]
      let sizeText = formatter.string(fromByteCount: asset.volume)
      volumeView.text = sizeText
    }
    if isVideoCell {
      // 4. durationLable at VideoCell
      addSubview(durationLabel)
      durationLabel.frame = CGRect(x: width * 0.05,
                                   y: width - (width / 4),
                                   width: width * 0.9,
                                   height: width / 5)
      durationLabel.layer.shadowColor = UIColor.black.cgColor
      durationLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
      durationLabel.layer.shadowOpacity = 1
      durationLabel.layer.shadowRadius = 7
      duration = asset.duration
    }
    //      if asset.isGif {
    //        addSubview(gifLabelView)
    //        gifLabelView.frame = CGRect(x: width * 13/28,
    //                                     y: 1 / 28 * width,
    //                                     width: width * 0.5,
    //                                     height: width / 5)
    //        gifLabelView.layer.shadowColor = UIColor.black.cgColor
    //        gifLabelView.layer.shadowOffset = CGSize(width: 1, height: 1)
    //        gifLabelView.layer.shadowOpacity = 1
    //        gifLabelView.layer.shadowRadius = 7
    //      }
    DispatchQueue.main.async { [unowned self] in
      withAnimation {
        self.imageView.alpha = isSelected ? 0.4 : 1
        self.checkMarkView.alpha = isSelected ? 1 : 0
        self.favoriteMarkView.alpha = (self.asset?.isFavorite ?? false) ? 1 : 0
        self.blurStackView.alpha = isVolumeView ? 1 : 0
        if isVideoCell {
          self.durationLabel.alpha = isSelected ? 0 : 1
        }
      }
    }
  }
  
  func settingPickerCell(cellWidth: CGFloat, isHidden: Bool) {
    self.width = cellWidth
    self.isHidden = isHidden
    let point = (cellWidth / 2) - (cellWidth / 8)
    addSubview(pickerButtonView)
    pickerButtonView.frame = CGRect(x: point, y: point,
                                    width: width/4,
                                    height: width/4)
    self.backgroundColor = .gray.withAlphaComponent(0.15)
  }
  
  func settingSpaceCell() {
    self.backgroundColor = .clear
  }
  
  func loadFullImage() {
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .opportunistic
    requestOptions.resizeMode = .exact
    requestOptions.isSynchronous = true
    requestOptions.isNetworkAccessAllowed = true
    self.imageManager?
      .requestImage(for: self.asset.phAsset,
                    targetSize: CGSize(width: width * scale,
                                       height: width * scale),
                    contentMode: .aspectFill,
                    options: requestOptions,
                    resultHandler: { [weak self] image, _ in
        guard let self = self else { return }
        DispatchQueue.main.async {
          withAnimation {
            self.imageView.image = image
          }
        }
      })
  }
}

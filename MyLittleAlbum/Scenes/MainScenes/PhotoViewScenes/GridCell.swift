//
//  GridCell.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 1/7/25.
//

import SwiftUI
import Photos

class GridCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String!
    var asset: MLAsset!
    var animationID: Namespace.ID!
    var width: CGFloat!
    var imageManager: PHCachingImageManager!
    
    var changed: Bool = false
    
    lazy var imageView: UIImageView! = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    lazy var durationLabel: UILabel! = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold, width: .standard)
        label.textAlignment = .right
        label.textColor = .white
       return label
    }()
    
    lazy var checkMarkView: UIImageView! = {
        let checkMark = "checkmark.circle.fill"
        let checkMarkView = UIImageView(image: UIImage(systemName: checkMark))
        checkMarkView.backgroundColor = .white
        checkMarkView.layer.opacity = 0
        return checkMarkView
    }()
    
    lazy var favoriteMarkView: UIImageView! = {
        let favoriteView = UIImageView(image: UIImage(systemName: iconFavorite))
        favoriteView.tintColor = UIColor(.white)
        favoriteView.contentMode = .scaleAspectFit
        favoriteView.layer.shadowColor = UIColor.black.cgColor
        favoriteView.layer.shadowOffset = CGSize(width: 0, height: 0)
        favoriteView.layer.shadowOpacity = 1
        favoriteView.layer.shadowRadius = 0.8
        favoriteView.layer.opacity = 0
        return favoriteView
    }()
    
    lazy var pickerButtonView: UIImageView! = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "plus")
        imageView.tintColor = UIColor(Color.white.opacity(0.5))
        return imageView
    }()
    
    var thumbnailImage: UIImage! {
        didSet {
            UIView.animate(withDuration: 1) {
                self.imageView.image = self.thumbnailImage
            }
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
        [checkMarkView, favoriteMarkView].forEach { view in
            view.alpha = 0
        }
    }
    
    // MARK: Setting View
    func settingCell(isVideoCell: Bool = false, isSelected: Bool) {
        phImageQueue.async {
            self.loadFullImage()
        }
        [imageView, checkMarkView, favoriteMarkView].forEach {
            addSubview($0)
        }
        // 1. image View
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: width)
        imageView.layer.cornerRadius = 1
        imageView.clipsToBounds = true
        // 2. checkMark View
        checkMarkView.frame = CGRect(x: width - (width / 3.5), y: width - (width / 3.5),
                                     width: width / 4, height: width / 4)
        checkMarkView.layer.cornerRadius = checkMarkView.frame.width / 2
        checkMarkView.layer.shadowColor = UIColor.black.cgColor
        checkMarkView.layer.shadowOffset = CGSize(width: 1, height: 1)
        checkMarkView.layer.shadowOpacity = 1
        checkMarkView.layer.shadowRadius = 7
        checkMarkView.clipsToBounds = true
        // 3. favoriteMark View
        favoriteMarkView.frame = CGRect(x: 1 / 28 * width, y: 1 / 28 * width,
                                        width: width / 4.5, height: width / 4.5)
        
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
        DispatchQueue.main.async { [unowned self] in
            withAnimation {
                self.imageView.alpha = isSelected ? 0.4 : 1
                self.checkMarkView.alpha = isSelected ? 1 : 0
                self.favoriteMarkView.alpha = (self.asset?.isFavorite ?? false) ? 1 : 0
                if isVideoCell {
                    self.durationLabel.alpha = isSelected ? 0 : 1
                }
            }
        }
    }
    
    func settingPickerCell() {
        addSubview(pickerButtonView)
        pickerButtonView.frame = CGRect(
            x: width / 2 - width / 8, y: width / 2 - width / 8,
            width: width / 4, height: width / 4)
        self.backgroundColor = .gray.withAlphaComponent(0.15)
    }
    
    func settingSpaceCell() {
        self.backgroundColor = .clear
    }
    
    func loadFullImage() {
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .opportunistic
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        self.imageManager
            .requestImage(for: self.asset.phAsset,
                          targetSize: CGSize(width: width * scale,
                                             height: width * scale),
                          contentMode: .aspectFill,
                          options: requestOptions,
                          resultHandler: { image, _ in
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.5) {
                        self.thumbnailImage = image
                    }
                }
            })
    }
}

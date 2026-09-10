//
//  BottomBlurCollectionView.swift
//  MyLittleAlbum
//
//  Created by yeonhoc5 on 9/8/26.
//

import UIKit

class BottomBlurredCollectionView: UICollectionView {
  let blurHeight: CGFloat
  private var blurView: UIVisualEffectView?
  private let maskLayer = CAGradientLayer() // ⭐️ 그라데이션 마스크 레이어 추가
  
  init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout, blurHeight: CGFloat) {
    self.blurHeight = blurHeight
    super.init(frame: frame, collectionViewLayout: layout)
    self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: blurHeight, right: 0)
    self.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: blurHeight, right: 0)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func didMoveToWindow() {
    super.didMoveToWindow()
    
    guard let superview = self.superview,
            blurView == nil
    else { return }
    
    // 1. 블러 뷰 생성
    let blurEffect = UIBlurEffect(style: .systemThickMaterialDark)
    let effectView = UIVisualEffectView(effect: blurEffect)
    effectView.translatesAutoresizingMaskIntoConstraints = false
    
    superview.addSubview(effectView)
    self.blurView = effectView
    
    // 2. 오토레이아웃 제약 설정
    NSLayoutConstraint.activate([
      effectView.leadingAnchor
        .constraint(equalTo: superview.leadingAnchor),
      effectView.trailingAnchor
        .constraint(equalTo: superview.trailingAnchor),
      effectView.bottomAnchor
        .constraint(equalTo: superview.bottomAnchor),
      effectView.heightAnchor
        .constraint(equalToConstant: blurHeight)
    ])
    
    // 3. ⭐️ 그라데이션 마스크 설정 (위쪽은 투명, 아래쪽은 불투명)
    // CGColor 생성 시 알파값만 조절하여 블러의 강도를 페이드 처리합니다.
    maskLayer.colors = [
      UIColor.black.withAlphaComponent(0.0).cgColor, // 맨 위: 완전 투명 (블러 없음)
      UIColor.black.withAlphaComponent(0.3).cgColor, // 중간: 살짝 블러
      UIColor.black.withAlphaComponent(0.8).cgColor,
      UIColor.black.withAlphaComponent(1.0).cgColor
    ]
    // 그라데이션의 분기점 비율 (취향에 맞게 조절 가능)
    maskLayer.locations = [0.0, 0.2, 0.3, 1.0]
    
    // 블러 뷰의 자체 layer 마스크로 지정
    effectView.layer.mask = maskLayer
  }
  
  // ⭐️ 화면 회전이나 레이아웃이 바뀔 때 마스크 크기도 함께 맞춰줍니다.
  override func layoutSubviews() {
    super.layoutSubviews()
    if let blurView = blurView {
      // 레이아웃 스레드 안전성을 위해 bounds를 정확히 트래킹
      maskLayer.frame = blurView.bounds
    }
  }
}

//
//  SpaceLabel.swift
//  custom_ui
//  适用于居中需要两边或者上下留白的label
//  留空Label 默认左右 各10pt 可自定
//  Created by duzhe on 2017/5/20.
//  Copyright © 2017年 duzhe. All rights reserved.
//

import UIKit

public class SpaceLabel: UILabel {
  
  /// 垂直空间 默认为 0
  public var verticalSpace: CGFloat = 0
  
  /// 默认左右各10各像素 这里设置的是总像素
  public var horizontalSpace: CGFloat = 20

  // 适当留白
  override public var intrinsicContentSize : CGSize {
    let originalSzie = super.intrinsicContentSize
    return CGSize(width: originalSzie.width+horizontalSpace, height: originalSzie.height+verticalSpace)
  }

}

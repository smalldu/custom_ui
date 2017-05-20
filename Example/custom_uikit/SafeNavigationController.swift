//
//  SafeNavigationController.swift
//  custom_uikit
//
//  Created by duzhe on 2017/5/20.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

public class SafeNavigationController: UINavigationController , UINavigationControllerDelegate  {
  /// 防止多次push问题
  private var _isSwitching = false
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.delegate = self
  }
  
  public override init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
  }
  
  public override func viewDidLoad() {
    self.interactivePopGestureRecognizer?.delegate = self
  }
  
  // MARK: - override push and pop method to prevent something
  
  override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
    if _isSwitching {
      return
    }
    if animated {
//      self.interactivePopGestureRecognizer?.isEnabled = false
    }
    _isSwitching = true
    print("push")
    super.pushViewController(viewController, animated: animated)
  }
  
  public override func popViewController(animated: Bool) -> UIViewController? {
    if animated {
//      self.interactivePopGestureRecognizer?.isEnabled = false
    }
    return super.popViewController(animated: animated)
  }
  
  public override func popToRootViewController(animated: Bool) -> [UIViewController]? {
    if animated {
//      self.interactivePopGestureRecognizer?.isEnabled = false
    }
    return super.popToRootViewController(animated: animated)
  }
  public override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
    if animated {
//      self.interactivePopGestureRecognizer?.isEnabled = false
    }
    return super.popToViewController(viewController, animated: animated)
  }
  
  public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
    print("finish")
    self._isSwitching = false
//    self.interactivePopGestureRecognizer?.isEnabled = true
  }
  
  
}

// MARK: - UIGestureRecognizerDelegate
extension SafeNavigationController: UIGestureRecognizerDelegate {
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if self.viewControllers.count < 1 || self.visibleViewController == self.viewControllers.first {
      return false
    }
    return true
  }
  
}









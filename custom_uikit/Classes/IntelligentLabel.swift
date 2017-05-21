//
//  IntelligentLabel.swift
//  TextFomater
//
//  Created by duzhe on 2017/5/17.
//  Copyright © 2017年 duzhe. All rights reserved.
//

import UIKit

public enum ITLinkDetectionType {
  case url
  case phone
  case none
}

public class IntelligentLabel: UILabel {
  struct LinkItem {
    var detectType: ITLinkDetectionType = .none
    var value: String
    var range: NSRange
  }
  typealias URLCallBack = (_ url:URL?) -> Void
  /// 属性文本存储
  fileprivate var textStorage:NSTextStorage!
  /// 负责文本“字形”布局
  fileprivate var layoutManager:NSLayoutManager!
  /// 设定文本绘制范围
  fileprivate var textContainer:NSTextContainer!
  
  /// 存储链接 Range 数组
  fileprivate var linkItems:[LinkItem] = []
  fileprivate var isTouchMoved: Bool = false
  fileprivate var _urlHandler: URLCallBack?
  
  func handUrl(_ urlHandler: URLCallBack?){
    self._urlHandler = urlHandler
  }
  
  fileprivate var selectedItem:LinkItem? {
    didSet{
      // 设置选中状态背景色和移除
      if let selectedItem = selectedItem{
        textStorage.addAttribute(NSBackgroundColorAttributeName, value: selectedLinkBackgroundColor, range: selectedItem.range)
      }else{
        if let item = oldValue {
          textStorage.removeAttribute(NSBackgroundColorAttributeName, range: item.range)
        }else{
          textStorage.removeAttribute(NSBackgroundColorAttributeName, range: NSMakeRange(0, textStorage.length))
        }
      }
      setNeedsDisplay()
    }
  }
  
  /// 选中链接的背景色
  public var selectedLinkBackgroundColor = UIColor(white: 0.9, alpha: 1)
  /// 链接颜色
  public var urlColor = UIColor.blue
  
  //MARK: - 重写的属性
  override  public var text: String? {
    didSet{
      updateTextStoreWithAttr(NSAttributedString(string: text ?? ""))
    }
  }
  public override var attributedText: NSAttributedString? {
    didSet{
      if let attributedText = attributedText{
        updateTextStoreWithAttr(attributedText)
      }
    }
  }
  
  public override var numberOfLines: Int {
    didSet{
      textContainer?.maximumNumberOfLines = numberOfLines
    }
  }
  
  public override var frame: CGRect {
    didSet{
      textContainer?.size = self.bounds.size
    }
  }
  public override var bounds: CGRect{
    didSet{
      textContainer?.size = self.bounds.size
    }
  }
  
  //MARK: - 构造函数
  override init(frame: CGRect) {
    super.init(frame: frame)
    prepareTextSystem()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    prepareTextSystem()
  }
  
  override public func drawText(in rect: CGRect) {
    let glyphRange = layoutManager.glyphRange(for: textContainer)
//    let glyphRange = NSMakeRange(0, textStorage.length)
    let glyphsPosition = self.calcGlyphsPositionInView()
    print("draw - \(glyphRange.length) draw - \(glyphsPosition)")
    
    // draw Glyphs 字形
    layoutManager.drawBackground(forGlyphRange: glyphRange, at: CGPoint.zero)
    layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: CGPoint.zero)
  }
  
  /// 计算 xy offset 文字的起点
  func calcGlyphsPositionInView()->CGPoint{
    var textOffset = CGPoint.zero
    
    var textBounds = layoutManager.usedRect(for: textContainer)
    textBounds.size.width = ceil(textBounds.size.width)
    textBounds.size.height = ceil(textBounds.size.height)
    
    if textBounds.height < self.bounds.height {
      let paddingHeight = (self.bounds.size.height - textBounds.size.height) / 2
      textOffset.y = paddingHeight
    }
    return textOffset
  }
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    //指定绘制文本的区域
    textContainer.size = bounds.size
    print("size === \(bounds.size)")
  }
}

extension IntelligentLabel {
  
  /// 准备文本系统
  func prepareTextSystem() {
    textContainer = NSTextContainer()
    textContainer.lineFragmentPadding = 0
    textContainer.maximumNumberOfLines = self.numberOfLines
    print("\(self.numberOfLines)=====")
    textContainer.lineBreakMode = self.lineBreakMode
    textContainer.size = self.frame.size
    
    layoutManager = NSLayoutManager()
    layoutManager.delegate = self
    layoutManager.addTextContainer(textContainer)
    
    textContainer.layoutManager = layoutManager

    self.isUserInteractionEnabled = true
    // 准备文本内容
    prepareTextContent()
  }
  
  /// 准备文本内容 - 使用textStorage 接管label 的内容
  func prepareTextContent() {
    if let attributedText = attributedText{
      updateTextStoreWithAttr(attributedText)
    }else if let text = text{
      updateTextStoreWithAttr(NSAttributedString(string: text))
    }else{
      updateTextStoreWithAttr(NSAttributedString(string: ""))
    }
    self.setNeedsDisplay()
  }
  
  
  /// 为textStorage设置属性自
  ///
  /// - Parameter attributeString: attributeString
  func updateTextStoreWithAttr(_ attributeString:NSAttributedString){
    var newAttributeString:NSAttributedString!
    if attributeString.length != 0{
      newAttributeString = IntelligentLabel.sanitizeAttributedString(attributeString)
    }else{
      return
    }
    if newAttributeString.length != 0{
      newAttributeString = prepareRangesforLink(attributeString)
      newAttributeString = addLinkAttributesToAttributedString(newAttributeString)
    }else{
      return
    }
    textStorage = NSTextStorage()
    textStorage.setAttributedString(newAttributeString)
    // 设置对象的关系
    textStorage.addLayoutManager(layoutManager)
    layoutManager.textStorage = textStorage
  }
  
  func prepareRangesforLink(_ text:NSAttributedString)->NSAttributedString{
    linkItems.removeAll()
    return prepareRangesForURLs(text)
  }
  
  
  /// 接续链接
  func prepareRangesForURLs(_ text:NSAttributedString)->NSAttributedString{
    let muAttr = NSMutableAttributedString(attributedString: text)
    // 使用detector find urls in the text
    do {
      let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue )
      let plainText = text.string
      let matches = detector.matches(in: plainText, options: NSRegularExpression.MatchingOptions(rawValue: 0) , range: NSMakeRange(0, text.length))
      var forIndex = 0
      var start = -1
      
      for match in matches {
        let matchRange = match.range
        if start == -1{
          start = matchRange.location
        }else{
          start = matchRange.location - forIndex
        }
        if match.resultType == .link {
          let replaceStr = "网页链接"
          let startIndex = plainText.index(plainText.startIndex, offsetBy: matchRange.location)
          let endIndex = plainText.index(startIndex, offsetBy: matchRange.length)
          let substringForMatch = plainText.substring(with: startIndex..<endIndex)
          muAttr.replaceCharacters(in: NSMakeRange(start, matchRange.length), with: replaceStr)
          
          let attchImage = NSTextAttachment()
          attchImage.image = UIImage(named: "hyperlink")
          // 设置图片大小
          attchImage.bounds = CGRect(x: 0 , y: -3, width: 14, height: 14)
          let imageAttr = NSAttributedString(attachment: attchImage)
          muAttr.insert(imageAttr, at: start)
          
          // 加一个attach的位置
          let range = NSMakeRange(start, replaceStr.characters.count+1)
          let item = LinkItem(detectType: ITLinkDetectionType.url , value: substringForMatch, range: range)
          self.linkItems.append(item)
          print("yes->\(substringForMatch)")
          forIndex += substringForMatch.characters.count - replaceStr.characters.count+1
        }
      }
      print(muAttr.string)
      return muAttr
    } catch let err {
      print(err.localizedDescription)
      return text
    }
  }
  
  
  /// 为linked string添加属性
  ///
  /// - Parameter string: string
  func addLinkAttributesToAttributedString(_ string:NSAttributedString)->NSAttributedString{
    let atrributedString = NSMutableAttributedString(attributedString: string)
    for item in self.linkItems {
      if item.detectType == .url {
        atrributedString.addAttribute(NSForegroundColorAttributeName , value: urlColor , range: item.range)
      }
    }
    return atrributedString
  }
  
  
}

// MARK: - 正则表达式函数
extension IntelligentLabel: NSLayoutManagerDelegate{
  
  func linkAtPoint(_ point:CGPoint) -> LinkItem? {
    if textStorage.length == 0{
      return nil
    }
    var location = point
    let textOffset = self.calcGlyphsPositionInView()
    location.x -= textOffset.x
    location.y -= textOffset.y
    
    //获取当前点中字符的索引
    let index = layoutManager.glyphIndex(for: point, in: textContainer)
    
    for item in self.linkItems {
      if NSLocationInRange(index, item.range) {
        print("yes")
        return item
      }
    }
    return nil
  }
  
  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //1.获取用户点击的位置
    guard  let location = touches.first?.location(in: self) else {
      return
    }
    isTouchMoved = false
    
    if let touchedItem = linkAtPoint(location) {
      self.selectedItem = touchedItem
    }else{
      super.touchesBegan(touches, with: event)
    }
  }
  
  override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    isTouchMoved = true
  }
  
  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    if isTouchMoved {
      self.selectedItem = nil
    }
    guard let selectedItem = selectedItem else {
      return
    }
    // 处理事件
    if selectedItem.detectType == .url {
      print("handle event url ===> \( selectedItem.value )")
      self._urlHandler?(URL(string: selectedItem.value))
    }
    self.selectedItem = nil
  }
  
  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    self.selectedItem = nil
  }
  
  public func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
    var range:NSRange = NSMakeRange(0, 0)
    let linkURL = layoutManager.textStorage?.attribute(NSLinkAttributeName, at: charIndex, effectiveRange: &range)
    return !(linkURL != nil && charIndex>range.location && charIndex <= NSMaxRange(range))
  }
  
  public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    // 计算需要的bounds ， 保存当前的size
    let savedTextContainerSize = textContainer.size
    let savedTextContainerNumberOfLines = textContainer.maximumNumberOfLines
    
    // 使用新的bounds和number of lines
    textContainer.size = bounds.size
    textContainer.maximumNumberOfLines = numberOfLines
    
    // 测量新状态下的文本大小
    var textBounds = layoutManager.usedRect(for: textContainer)
    
    textBounds.origin = bounds.origin
    textBounds.size.width = ceil(textBounds.width)
    textBounds.size.height = ceil(textBounds.height)
    
    if textBounds.size.height < bounds.size.height {
      let offSetY = (bounds.size.height - textBounds.size.height)/2.0
      textBounds.origin.y = offSetY
    }
    
    textContainer.size = savedTextContainerSize
    textContainer.maximumNumberOfLines = savedTextContainerNumberOfLines
    return textBounds
  }
}




extension IntelligentLabel {
  
  static func sanitizeAttributedString(_ attributeString:NSAttributedString)->NSAttributedString{
    var range:NSRange = NSMakeRange(0, 0)
    if let paragraphStyle = attributeString.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: &range) as? NSParagraphStyle {
      // remove the line break
      if let mutableParagraphStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
        mutableParagraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        // apply new style 
        let restyled = NSMutableAttributedString(attributedString: attributeString)
        restyled.addAttribute(NSParagraphStyleAttributeName, value: mutableParagraphStyle, range: NSMakeRange(0, restyled.length) )
        return restyled
      }
    }
    return attributeString
  }

}

















//
//  ViewController.swift
//  custom_uikit
//
//  Created by duzhe on 05/20/2017.
//  Copyright (c) 2017 duzhe. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var spaceLabel: SpaceLabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    spaceLabel.verticalSpace = 20
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
}


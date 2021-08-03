//
//  AppViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class AppViewController: UIViewController, PrimerTextFieldViewDelegate {
    
    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
//            Primer.shared.show(flow: .default)
//        }
    }

}

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
    
    @IBOutlet weak var primerTextField: PrimerCardNumberFieldView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        primerTextField.backgroundColor = .orange
        primerTextField.delegate = self
    }
    
    func isTextValid(_ isValid: Bool?) {
        print("isTextValid: \(isValid)")
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork) {
        print(cardNetwork)
    }
}

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
    @IBOutlet weak var expiryDateFieldView: PrimerExpiryDateFieldView!
    @IBOutlet weak var cvvFieldView: PrimerCVVFieldView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        primerTextField.backgroundColor = .lightGray
        primerTextField.delegate = self
        expiryDateFieldView.backgroundColor = .lightGray
        expiryDateFieldView.delegate = self
        cvvFieldView.backgroundColor = .lightGray
        cvvFieldView.placeholder = "CVV"
        cvvFieldView.delegate = self
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork) {
        print(cardNetwork)
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        print("isTextValid: \(isValid)")
    }
}

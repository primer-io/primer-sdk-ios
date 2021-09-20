//
//  AppViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class AppViewController: UIViewController {
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNumberTextField.text = "07538121305"
    }
    
    @IBAction func initializePrimerButtonTapped(_ sender: Any) {
        let mcvc = MerchantCheckoutViewController.instantiate(phoneNumber: phoneNumberTextField.text)
        navigationController?.pushViewController(mcvc, animated: true)
    }
    
}

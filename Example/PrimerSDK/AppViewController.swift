//
//  AppViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class AppViewController: UIViewController {
    
    @IBOutlet weak var environmentSwitch: UISegmentedControl!
    private var selectedEnvironment: Environment = .sandbox
    @IBOutlet weak var customerIdTextField: UITextField!
    
    @IBAction func environmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedEnvironment = .sandbox
        case 1:
            selectedEnvironment = .staging
        case 2:
            selectedEnvironment = .production
        default:
            break
        }
    }
    
    @IBAction func initializeButtonTapped(_ sender: Any) {
        let mvc = MerchantCheckoutViewController.instantiate(environment: selectedEnvironment, customerId: customerIdTextField.text)
        navigationController?.pushViewController(mvc, animated: true)
    }
    
}

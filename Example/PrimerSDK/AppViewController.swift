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
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var performPaymentSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performPaymentSwitch.isOn = true
        environmentSwitch.selectedSegmentIndex = 1
    }
    
    @IBAction func environmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedEnvironment = .dev
        case 1:
            selectedEnvironment = .sandbox
        case 2:
            selectedEnvironment = .staging
        case 3:
            selectedEnvironment = .production
        default:
            break
        }
    }
    
    @IBAction func initializeButtonTapped(_ sender: Any) {
        var amount: Int?
        if let strVal = amountTextField.text,
           let dblVal = Double(strVal) {
            amount = Int(dblVal*100)
        }
        
        let customerId = (customerIdTextField.text ?? "").isEmpty ? "customer_id" : customerIdTextField.text
        let mvc = MerchantCheckoutViewController.instantiate(environment: selectedEnvironment, customerId: customerId, amount: amount, performPayment: performPaymentSwitch.isOn)
        navigationController?.pushViewController(mvc, animated: true)
    }
    
}

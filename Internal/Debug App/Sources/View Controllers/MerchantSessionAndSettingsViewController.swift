//
//  MerchantSessionAndSettingsViewController.swift
//  Debug App
//
//  Created by Evangelos Pittas on 7/2/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit

class MerchantSessionAndSettingsViewController: UIViewController {
    
    @IBOutlet weak var testingModeSegmentedControl: UISegmentedControl!
    
    // MARK: Stack Views
    
    @IBOutlet weak var environmentStackView: UIStackView!
    @IBOutlet weak var apiKeyStackView: UIStackView!
    @IBOutlet weak var clientTokenStackView: UIStackView!
    @IBOutlet weak var sdkSettingsStackView: UIStackView!
    @IBOutlet weak var orderStackView: UIStackView!
    @IBOutlet weak var customerStackView: UIStackView!
    @IBOutlet weak var surchargeStackView: UIStackView!
    
    // MARK: Inputs
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func render() {
        if testingModeSegmentedControl.selectedSegmentIndex == 0 {
            environmentStackView.isHidden = false
            apiKeyStackView.isHidden = false
            clientTokenStackView.isHidden = true
            sdkSettingsStackView.isHidden = false
            orderStackView.isHidden = false
            customerStackView.isHidden = false
            surchargeStackView.isHidden = false
            
        } else if testingModeSegmentedControl.selectedSegmentIndex == 1 {
            environmentStackView.isHidden = false
            apiKeyStackView.isHidden = false
            clientTokenStackView.isHidden = false
            sdkSettingsStackView.isHidden = false
            orderStackView.isHidden = true
            customerStackView.isHidden = true
            surchargeStackView.isHidden = true
            
        } else if testingModeSegmentedControl.selectedSegmentIndex == 2 {
            environmentStackView.isHidden = true
            apiKeyStackView.isHidden = true
            clientTokenStackView.isHidden = true
            sdkSettingsStackView.isHidden = false
            orderStackView.isHidden = false
            customerStackView.isHidden = false
            surchargeStackView.isHidden = false
        }
    }
    
    
    
    
    
    
    
    
    
    @IBAction func testingModeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        render()
    }
}

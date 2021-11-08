//
//  AppViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class AppViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var environmentControl: UISegmentedControl!
    @IBOutlet weak var customerIdTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var performPaymentSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        environmentControl.selectedSegmentIndex = 1
        environmentControl.accessibilityIdentifier = "env_control"
        customerIdTextField.accessibilityIdentifier = "customer_id_txt_field"
        phoneNumberTextField.accessibilityIdentifier = "phone_number_txt_field"
        phoneNumberTextField.text = nil
        phoneNumberTextField.accessibilityIdentifier = "phone_number_txt_field"
        countryCodeTextField.text = CountryCode.gb.rawValue
        countryCodeTextField.accessibilityIdentifier = "country_code_txt_field"
        currencyTextField.text = Currency.GBP.rawValue
        currencyTextField.accessibilityIdentifier = "currency_txt_field"
        amountTextField.text = "0.01"
        amountTextField.accessibilityIdentifier = "amount_txt_field"
        performPaymentSwitch.isOn = true
        performPaymentSwitch.accessibilityIdentifier = "perform_payment_switch"
        
        let countryPicker = UIPickerView()
        countryPicker.accessibilityIdentifier = "country_picker"
        countryPicker.tag = 0
        countryCodeTextField.inputView = countryPicker
        countryPicker.dataSource = self
        countryPicker.delegate = self
        
        let currencyPicker = UIPickerView()
        currencyPicker.accessibilityIdentifier = "currency_picker"
        currencyPicker.tag = 1
        currencyTextField.inputView = currencyPicker
        currencyPicker.dataSource = self
        currencyPicker.delegate = self
    }
    
    @IBAction func initializePrimerButtonTapped(_ sender: Any) {
        var env: Environment!
        switch environmentControl.selectedSegmentIndex {
        case 0:
            env = .dev
        case 1:
            env = .sandbox
        case 2:
            env = .staging
        case 3:
            env = .production
        default:
            break
        }
        
        var amount: Int?
        if let amountStr = amountTextField.text, let amountDbl = Double(amountStr) {
            amount = Int(amountDbl * 100)
        }
        
        let mcvc = MerchantCheckoutViewController.instantiate(
            environment: env,
            customerId: customerIdTextField.text,
            phoneNumber: phoneNumberTextField.text,
            countryCode: CountryCode(rawValue: countryCodeTextField.text ?? ""),
            currency: Currency(rawValue: currencyTextField.text ?? ""),
            amount: amount,
            performPayment: performPaymentSwitch.isOn)
        
        navigationController?.pushViewController(mcvc, animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 0 {
            return CountryCode.allCases.count
        } else {
            return Currency.allCases.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return CountryCode.allCases[row].rawValue
        } else {
            return Currency.allCases[row].rawValue
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            countryCodeTextField.text = CountryCode.allCases[row].rawValue
        } else {
            currencyTextField.text = Currency.allCases[row].rawValue
        }
    }
}

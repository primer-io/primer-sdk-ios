//
//  AppViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

var environment: Environment = .sandbox
var customDefinedApiKey: String?
var metadataTestCase: String?
var paymentHandling: PrimerPaymentHandling = .auto
var clientSessionRequestBody: ClientSessionRequestBody!
var performPaymentAfterVaulting: Bool = true

class AppViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var environmentControl: UISegmentedControl!
    @IBOutlet weak var checkoutHandlingControl: UISegmentedControl!
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var metadataTestCaseTextField: UITextField!
    @IBOutlet weak var customerIdTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var performPaymentSwitch: UISwitch!
    
    var amount: Int? {
        if let amountStr = amountTextField.text {
            return Int(amountStr)
        } else {
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        environmentControl.selectedSegmentIndex = environment.intValue
        environmentControl.accessibilityIdentifier = "env_control"
        checkoutHandlingControl.selectedSegmentIndex = paymentHandling == .auto ? 0 : 1
        checkoutHandlingControl.accessibilityIdentifier = "payment_control"
        apiKeyTextField.accessibilityIdentifier = "api_key_txt_field"
        apiKeyTextField.text = nil
        metadataTestCaseTextField.accessibilityIdentifier = "metadata_test_case_txt_field"
        metadataTestCaseTextField.text = nil
        customerIdTextField.accessibilityIdentifier = "customer_id_txt_field"
        customerIdTextField.text = "ios-customer-\(String.randomString(length: 8))"
        phoneNumberTextField.accessibilityIdentifier = "phone_number_txt_field"
        phoneNumberTextField.text = nil
        phoneNumberTextField.accessibilityIdentifier = "phone_number_txt_field"
        countryCodeTextField.text = CountryCode.de.rawValue
        countryCodeTextField.accessibilityIdentifier = "country_code_txt_field"
        currencyTextField.text = Currency.EUR.rawValue
        currencyTextField.accessibilityIdentifier = "currency_txt_field"
        amountTextField.placeholder = "In minor units (type 100 for 1.00)"
        amountTextField.text = "101"
        amountTextField.accessibilityIdentifier = "amount_txt_field"
        performPaymentSwitch.isOn = performPaymentAfterVaulting
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
    
    @IBAction func viewTapped(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func environmentValueChanged(_ sender: UISegmentedControl) {
        environment = Environment(intValue: sender.selectedSegmentIndex)
    }
    
    @IBAction func paymentHandlingValueChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            paymentHandling = .auto
        } else {
            paymentHandling = .manual
        }
    }
    
    @IBAction func preformPaymentValueChanged(_ sender: UISwitch) {
        performPaymentAfterVaulting = sender.isOn
    }
    
    @IBAction func primerSDKButtonTapped(_ sender: Any) {
        self.evaluateCustomDefinedApiKey()
        self.evaluateMetadataTestCase()
        
        clientSessionRequestBody = Networking.createClientSessionRequestBodyWithParameters(
            amount: amount,
            currency: Currency(rawValue: currencyTextField.text ?? ""),
            customerId: (customerIdTextField.text ?? "").isEmpty ? "ios_customer_id" : customerIdTextField.text!,
            phoneNumber: phoneNumberTextField.text,
            countryCode: CountryCode(rawValue: countryCodeTextField.text ?? ""))
        
        let vc = MerchantCheckoutViewController.instantiate()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func hucButtonTapped(_ sender: Any) {
        self.evaluateCustomDefinedApiKey()
        self.evaluateMetadataTestCase()
        
        clientSessionRequestBody = Networking.createClientSessionRequestBodyWithParameters(
            amount: amount,
            currency: Currency(rawValue: currencyTextField.text ?? ""),
            customerId: (customerIdTextField.text ?? "").isEmpty ? "ios_customer_id" : customerIdTextField.text!,
            phoneNumber: phoneNumberTextField.text,
            countryCode: CountryCode(rawValue: countryCodeTextField.text ?? ""))
        
        let vc = MerchantHUCPaymentMethodsViewController.instantiate()
        navigationController?.pushViewController(vc, animated: true)
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
            return CountryCode.allCases.sorted(by: { $0.rawValue < $1.rawValue })[row].rawValue
        } else {
            return Currency.allCases.sorted(by: { $0.rawValue < $1.rawValue })[row].rawValue
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            countryCodeTextField.text = CountryCode.allCases.sorted(by: { $0.rawValue < $1.rawValue })[row].rawValue
        } else {
            currencyTextField.text = Currency.allCases.sorted(by: { $0.rawValue < $1.rawValue })[row].rawValue
        }
    }
}

extension AppViewController {
    
    func evaluateCustomDefinedApiKey() {
        customDefinedApiKey = (apiKeyTextField.text ?? "").isEmpty ? nil : apiKeyTextField.text
    }
    
    func evaluateMetadataTestCase() {
        metadataTestCase = (metadataTestCaseTextField.text ?? "").isEmpty ? nil : metadataTestCaseTextField.text
    }
}

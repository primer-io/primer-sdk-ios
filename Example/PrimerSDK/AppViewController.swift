//
//  AppViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import PrimerSDK

class AppViewController: UIViewController, AppViewControllerDelegate {
    
    var customerId: String {
        customerIdTextField.text ?? ""
    }
    
    var environment: Environment = .Sandbox {
        didSet {
            environmentTextField.text = environment.rawValue
        }
    }
    
    var countryCode: CountryCode = CountryCode.de {
        didSet {
            countryTextField.text = countryCode.country
        }
    }
    
    let countryList = [
        CountryCode.de,
        CountryCode.se,
        CountryCode.tr,
        CountryCode.au,
        CountryCode.ge,
    ]
    
    var amount: Int = 50 {
        didSet {
            amountTextField.text = amount.asString
        }
    }
    
    let amountList = [
        50,
        100,
        200,
        1000,
        5000,
    ]
    
    var useKlarna: Bool {
        klarnaSwitch.isOn
    }
    
    var usePaypal: Bool {
        paypalSwitch.isOn
    }
    
    var useCard: Bool {
        cardSwitch.isOn
    }
    
    var useApplePay: Bool {
        applePaySwitch.isOn
    }
    
    //
    
    @IBOutlet var customerIdTextField: UITextField!
    @IBOutlet var environmentTextField: UITextField!
    @IBOutlet var countryTextField: UITextField!
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var klarnaSwitch: UISwitch!
    @IBOutlet var paypalSwitch: UISwitch!
    @IBOutlet var cardSwitch: UISwitch!
    @IBOutlet var applePaySwitch: UISwitch!
    @IBOutlet var nextButton: UIButton!
    
    var environmentPickerView = UIPickerView()
    var countryPickerView = UIPickerView()
    var amountPickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
    
        
        if traitCollection.userInterfaceStyle == .light {
            view.backgroundColor = .white
        } else {
            if #available(iOS 13.0, *) {
                view.backgroundColor = .systemGray6
            } else {
                view.backgroundColor = UIColor(displayP3Red: 26/255, green: 27/255, blue: 27/255, alpha: 1)
            }
        }
        
        environment = Environment.allCases[0]
        countryCode = countryList[0]
        amount = amountList[0]
        
        configureCustomerIdTextField()
        configurePickerAndAttachToolbar(to: environmentTextField, picker: environmentPickerView)
        configurePickerAndAttachToolbar(to: countryTextField, picker: countryPickerView)
        configurePickerAndAttachToolbar(to: amountTextField, picker: amountPickerView)
        
        klarnaSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        paypalSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        cardSwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        applePaySwitch.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        nextButton.backgroundColor = .black
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 8.0
        determineCanProgress()
    }
    
    private func determineCanProgress() {
//        let paymentMethodSelected = [klarnaSwitch.isOn, paypalSwitch.isOn, cardSwitch.isOn, applePaySwitch.isOn].contains(true)
        let canProgress = customerId.count > 0
        nextButton.isEnabled = canProgress
        nextButton.alpha = canProgress ? 1.0 : 0.6
    }
    
    @IBAction private func onCustomerIdTextFieldDidChange(_ sender: UITextField) {
        determineCanProgress()
    }
    
    @IBAction private func klarnaSwitchDidChange(_ sender: UISwitch) {
        determineCanProgress()
    }
    
    @IBAction private func paypalSwitchDidChange(_ sender: UISwitch) {
        determineCanProgress()
    }
    
    @IBAction private func cardSwitchDidChange(_ sender: UISwitch) {
        determineCanProgress()
    }
    
    @IBAction private func applePaySwitchDidChange(_ sender: UISwitch) {
        determineCanProgress()
    }
    
    private func configureCustomerIdTextField() {
        customerIdTextField.delegate = self
        customerIdTextField.becomeFirstResponder()
    }
    
    private func configurePickerAndAttachToolbar(to textField: UITextField, picker: UIPickerView) {
//        picker.backgroundColor = .white
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35))
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(donePicker))
        doneButton.tintColor = .systemBlue
        cancelButton.tintColor = .systemBlue
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        textField.inputView = picker
        textField.inputAccessoryView = toolBar
    }
    
    @objc func donePicker() {
        environmentTextField.resignFirstResponder()
        countryTextField.resignFirstResponder()
        amountTextField.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! MerchantCheckoutViewController
        destinationVC.delegate = self
    }
}

extension AppViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        customerIdTextField.resignFirstResponder()
        return true
    }
}

extension AppViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == countryPickerView) {
            return countryList.count
        } else if (pickerView == amountPickerView) {
            return amountList.count
        } else if (pickerView == environmentPickerView) {
            return Environment.allCases.count
        } else {
            return 0
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView == countryPickerView) {
            return (countryList[row].country + " - " + countryList[row].currency!.rawValue)
        } else if (pickerView == amountPickerView) {
            return amountList[row].asString
        } else if (pickerView == environmentPickerView) {
            return Environment.allCases[row].rawValue
        } else {
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView == countryPickerView) {
            countryCode = countryList[row]
        } else if (pickerView == environmentPickerView) {
            environment = Environment.allCases[row]
        } else if (pickerView == amountPickerView) {
            amount = amountList[row]
        }
    }
}

extension CountryCode {
    var currencySymbol: String {
        switch self {
        case .se, .dk, .no:
            return "kr"
        case .de, .fi, .es, .it:
            return "€"
        case .gb:
            return "£"
        case .tr:
            return "₺‎"
        case .ge:
            return "₾"
        case .au:
            return "A$"
        default:
            return ""
        }
    }
    
    var currency: Currency? {
        switch self {
        case .dk:
            return .DKK
        case .no:
            return .NOK
        case .se:
            return .SEK
        case .de, .fi, .es, .it:
            return .EUR
        case .tr:
            return .TRY
        case .ge:
            return .GEL
        case .gb:
            return .GBP
        case .au:
            return .AUD
        default:
            return nil
        }
    }
}

extension Int {
    var asString: String {
        return String(format: "%.2f", (Double(self) / 100))
    }
}

protocol AppViewControllerDelegate: class {
    
    var customerId: String { get }
    
    var environment: Environment { get }
    
    var countryCode: CountryCode { get }
    
    var amount: Int { get }
    
    var useKlarna: Bool { get }
    var usePaypal: Bool { get }
    var useCard: Bool { get }
    var useApplePay: Bool { get }
}

enum Environment: String, CaseIterable {
    case Sandbox, Production
}

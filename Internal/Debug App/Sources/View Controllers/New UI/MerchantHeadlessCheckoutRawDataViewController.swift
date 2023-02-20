//
//  MerchantHeadlessCheckoutRawDataViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 12/7/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHeadlessCheckoutRawDataViewController: UIViewController {
    
    static func instantiate(paymentMethodType: String, settings: PrimerSettings, clientToken: String) -> MerchantHeadlessCheckoutRawDataViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCRawDataViewController") as! MerchantHeadlessCheckoutRawDataViewController
        mpmvc.paymentMethodType = paymentMethodType
        mpmvc.settings = settings
        mpmvc.clientToken = clientToken
        return mpmvc
    }
    
    var settings: PrimerSettings!
    var clientToken: String!
    
    var stackView: UIStackView!
    var paymentMethodType: String!
    var paymentId: String?
    var activityIndicator: UIActivityIndicatorView?
    var rawCardData = PrimerCardData(cardNumber: "", expiryDate: "", cvv: "", cardholderName: "")
    
    var cardnumberTextField: UITextField!
    var expiryDateTextField: UITextField!
    var cvvTextField: UITextField!
    var cardholderNameTextField: UITextField!
    var payButton: UIButton!
    
    var logs: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.spacing = 6
        self.view.addSubview(self.stackView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true

        self.renderInputs()
    }
    
    var primerRawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    
    func renderInputs() {
        do {
            self.primerRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: self.paymentMethodType, delegate: self)
            let inputElementTypes = self.primerRawDataManager!.listRequiredInputElementTypes(for: self.paymentMethodType)
            
            for inputElementType in inputElementTypes {
                switch inputElementType {
                case .cardNumber:
                    self.cardnumberTextField = UITextField(frame: .zero)
                    self.cardnumberTextField.accessibilityIdentifier = "card_txt_fld"
                    self.cardnumberTextField.borderStyle = .line
                    self.cardnumberTextField.layer.borderColor = UIColor.black.cgColor
                    self.stackView.addArrangedSubview(self.cardnumberTextField)
                    self.cardnumberTextField.translatesAutoresizingMaskIntoConstraints = false
                    self.cardnumberTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    self.cardnumberTextField.delegate = self
                    self.cardnumberTextField.placeholder = "4242 4242 4242 4242"
                    
                case .expiryDate:
                    self.expiryDateTextField = UITextField(frame: .zero)
                    self.expiryDateTextField.accessibilityIdentifier = "expiry_txt_fld"
                    self.expiryDateTextField.borderStyle = .line
                    self.expiryDateTextField.layer.borderColor = UIColor.black.cgColor
                    self.stackView.addArrangedSubview(self.expiryDateTextField)
                    self.expiryDateTextField.translatesAutoresizingMaskIntoConstraints = false
                    self.expiryDateTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    self.expiryDateTextField.delegate = self
                    self.expiryDateTextField.placeholder = "03/30"
                    
                case .cvv:
                    self.cvvTextField = UITextField(frame: .zero)
                    self.cvvTextField.accessibilityIdentifier = "cvc_txt_fld"
                    self.cvvTextField.borderStyle = .line
                    self.cvvTextField.layer.borderColor = UIColor.black.cgColor
                    self.stackView.addArrangedSubview(self.cvvTextField)
                    self.cvvTextField.translatesAutoresizingMaskIntoConstraints = false
                    self.cvvTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    self.cvvTextField.delegate = self
                    self.cvvTextField.placeholder = "123"
                    
                case .cardholderName:
                    self.cardholderNameTextField = UITextField(frame: .zero)
                    self.cardholderNameTextField.accessibilityIdentifier = "card_holder_txt_fld"
                    self.cardholderNameTextField.borderStyle = .line
                    self.cardholderNameTextField.layer.borderColor = UIColor.black.cgColor
                    self.stackView.addArrangedSubview(self.cardholderNameTextField)
                    self.cardholderNameTextField.translatesAutoresizingMaskIntoConstraints = false
                    self.cardholderNameTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    self.cardholderNameTextField.delegate = self
                    self.cardholderNameTextField.placeholder = "John Smith"
                    
                case .otp:
                    break
                    
                case .postalCode:
                    break
                    
                case .phoneNumber:
                    break
                    
                case .retailer:
                    break
                    
                case .unknown:
                    break
                }
            }
            
            self.payButton = UIButton(frame: .zero)
            self.stackView.addArrangedSubview(self.payButton)
            self.payButton.accessibilityIdentifier = "submit_btn"
            self.payButton.translatesAutoresizingMaskIntoConstraints = false
            self.payButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
            self.payButton.setTitle("Pay", for: .normal)
            self.payButton.titleLabel?.adjustsFontSizeToFitWidth = true
            self.payButton.titleLabel?.minimumScaleFactor = 0.7
            self.payButton.backgroundColor = .lightGray
            self.payButton.setTitleColor(.white, for: .normal)
            self.payButton.isEnabled = false
            self.payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
            
        } catch {
            
        }
    }
    
    @IBAction func payButtonTapped(_ sender: UIButton) {
        guard expiryDateTextField.text?.count == 7,
              let expiryComponents = expiryDateTextField.text?.split(separator: "/") else {
            self.showErrorMessage("Please write expiry date in format MM/YY")
            return
        }
        
        if expiryComponents.count != 2 {
            self.showErrorMessage("Please write expiry date in format MM/YY")
            return
        }
        
        if paymentMethodType == "PAYMENT_CARD" {
            self.primerRawDataManager!.submit()
            self.showLoadingOverlay()
            
        }
    }
    
    // MARK: - HELPERS
    
    private func showLoadingOverlay() {
        DispatchQueue.main.async {
            self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
            self.view.addSubview(self.activityIndicator!)
            self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
            self.activityIndicator?.color = .black
            self.activityIndicator?.startAnimating()
        }
    }
    
    private func hideLoadingOverlay() {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.removeFromSuperview()
            self.activityIndicator = nil
        }
    }
}

extension MerchantHeadlessCheckoutRawDataViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var newText: String?
        
        if let text = textField.text,
           let textRange = Range(range, in: text) {
            newText = text.replacingCharacters(in: textRange, with: string)
            
            if newText!.count == 0 {
                newText = nil
            }
        }
        
        if textField == self.cardnumberTextField {
            self.rawCardData.cardNumber = (newText ?? "").replacingOccurrences(of: " ", with: "")
            
        } else if textField == self.expiryDateTextField,
                  newText?.count == 7
        {
            self.rawCardData.expiryDate = newText!

        } else if textField == self.cvvTextField {
            self.rawCardData.cvv = newText ?? ""
            
        } else if textField == self.cardholderNameTextField {
            self.rawCardData.cardholderName = newText
        }
        
        self.primerRawDataManager?.rawData = self.rawCardData
        
        return true
    }
}

extension MerchantHeadlessCheckoutRawDataViewController: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        print("\n\nMERCHANT APP\n\(#function)\ndataIsValid: \(isValid)")
        self.logs.append(#function)
        self.payButton.backgroundColor = isValid ? .black : .lightGray
        self.payButton.isEnabled = isValid
    }
    
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String : Any]?) {
        print("\n\nMERCHANT APP\n\(#function)\nmetadataDidChange: \(metadata)")
        self.logs.append(#function)
    }
}

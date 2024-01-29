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
    
    static func instantiate(paymentMethodType: String) -> MerchantHeadlessCheckoutRawDataViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCRawDataViewController") as! MerchantHeadlessCheckoutRawDataViewController
        mpmvc.paymentMethodType = paymentMethodType
        return mpmvc
    }
    
    var primerRawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager?
    
    var stackView: UIStackView!
    var paymentMethodType: String!
    var paymentId: String?
    var activityIndicator: UIActivityIndicatorView?
    var rawCardData = PrimerCardData(cardNumber: "", 
                                     expiryDate: "",
                                     cvv: "",
                                     cardholderName: "")
    
    var cardnumberTextField: UITextField?
    var expiryDateTextField: UITextField?
    var cvvTextField: UITextField?
    var cardholderNameTextField: UITextField?
    var payButton: UIButton!
    
    var cardsLabel: UILabel!
    
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
        
        self.cardnumberTextField?.becomeFirstResponder()
    }
    
    // 4111 1234 1234 1234
    // 5522 1234 1234 1234

    
    func renderAutoInputUI() {
        let stack = UIStackView()
        stack.axis = .horizontal
        
        let updateCardData = { [self] in
            rawCardData.cardNumber = cardnumberTextField!.text!.replacingOccurrences(of: " ", with: "")
            primerRawDataManager?.rawData = rawCardData
        }
        
        let visaButton = UIButton(primaryAction: UIAction(title: "VISA", handler: { _ in
            self.cardnumberTextField?.text = "4111 1234 1234 1234"
            updateCardData()
        }))
        let mcButton = UIButton(primaryAction: UIAction(title: "MasterCard", handler: { _ in
            self.cardnumberTextField?.text = "5522 1234 1234 1234"
            updateCardData()
        }))
        
        stack.addArrangedSubview(visaButton)
        stack.addArrangedSubview(mcButton)
        stack.distribution = .fillEqually
        
        self.stackView.addArrangedSubview(stack)
    }
    
    func renderInputs() {
        renderAutoInputUI()
        
        do {
            self.primerRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: self.paymentMethodType, delegate: self)
            let inputElementTypes = self.primerRawDataManager!.listRequiredInputElementTypes(for: self.paymentMethodType)
            
            for inputElementType in inputElementTypes {
                switch inputElementType {
                case .cardNumber:
                    self.cardnumberTextField = styledTextField(forAccessibilityId: "card_txt_fld",
                                                               withPlaceholderText: "4242 4242 4242 4242")
                case .expiryDate:
                    self.expiryDateTextField = styledTextField(forAccessibilityId: "expiry_txt_fld",
                                                               withPlaceholderText: "03/2030")
                case .cvv:
                    self.cvvTextField = styledTextField(forAccessibilityId: "cvc_txt_fld",
                                                        withPlaceholderText: "123")
                case .cardholderName:
                    self.cardholderNameTextField = styledTextField(forAccessibilityId: "card_holder_txt_fld",
                                                                   withPlaceholderText: "John Smith")
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
            
            self.cardsLabel = UILabel(frame: .zero)
            self.cardsLabel.font = .systemFont(ofSize: 24)
            self.cardsLabel.textAlignment = .center
            self.cardsLabel.numberOfLines = 0
            self.cardsLabel.lineBreakMode = .byWordWrapping
            self.stackView.addArrangedSubview(cardsLabel)
            self.cardsLabel.translatesAutoresizingMaskIntoConstraints = false
            self.cardsLabel.heightAnchor.constraint(equalToConstant: 120).isActive = true
            
        } catch {
            print("[MerchantHeadlessCheckoutRawDataViewController] ERROR: Failed to set up card entry fields")
        }
    }
    
    private func styledTextField(forAccessibilityId accessibilityId: String,
                                 withPlaceholderText placeholderText: String) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.accessibilityIdentifier = accessibilityId
        textField.borderStyle = .none
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        textField.delegate = self
        textField.placeholder = placeholderText
        
        self.stackView.addArrangedSubview(textField)
        
        return textField
    }
    
    @IBAction func payButtonTapped(_ sender: UIButton) {
        guard expiryDateTextField?.text?.count == 7,
              let expiryComponents = expiryDateTextField?.text?.split(separator: "/") else {
            self.showErrorMessage("Please write expiry date in format MM/YYYY")
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
        print("TextField called")
        let text = textField.text
        
        var newText: String = ""
        
        if text != nil,
           let textRange = Range(range, in: text!) {
            newText = text!.replacingCharacters(in: textRange, with: string)
        }
        
        if textField == self.cardnumberTextField {
            self.rawCardData = PrimerCardData(
                cardNumber: newText.replacingOccurrences(of: " ", with: ""),
                expiryDate: self.expiryDateTextField?.text ?? "",
                cvv: self.cvvTextField?.text ?? "",
                cardholderName: self.cardholderNameTextField?.text ?? "",
                cardNetwork: self.rawCardData.cardNetwork)
            
        } else if textField == self.expiryDateTextField {
            self.rawCardData = PrimerCardData(
                cardNumber: self.cardnumberTextField?.text ?? "",
                expiryDate: newText,
                cvv: self.cvvTextField?.text ?? "",
                cardholderName: self.cardholderNameTextField?.text ?? "",
                cardNetwork: self.rawCardData.cardNetwork)
            
        } else if textField == self.cvvTextField {
            self.rawCardData = PrimerCardData(
                cardNumber: self.cardnumberTextField?.text ?? "",
                expiryDate: self.expiryDateTextField?.text ?? "",
                cvv: newText,
                cardholderName: self.cardholderNameTextField?.text ?? "",
                cardNetwork: self.rawCardData.cardNetwork)
            
        } else if textField == self.cardholderNameTextField {
            self.rawCardData = PrimerCardData(
                cardNumber: self.cardnumberTextField?.text ?? "",
                expiryDate: self.expiryDateTextField?.text ?? "",
                cvv: self.cvvTextField?.text ?? "",
                cardholderName: newText.count == 0 ? nil : newText,
                cardNetwork: self.rawCardData.cardNetwork)
        }
        
        print("self.rawCardData\ncardNumber: \(self.rawCardData.cardNumber)\nexpiryDate: \(self.rawCardData.expiryDate)\ncvv: \(self.rawCardData.cvv)\ncardholderName: \(self.rawCardData.cardholderName ?? "nil")")
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
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?) {
        print("\n\nMERCHANT APP\n\(#function)\nmetadataDidChange: \(String(describing: metadata))")
        self.logs.append(#function)
    }
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, willFetchCardMetadataForState cardState: PrimerCardValidationState) {
        // TODO
        print("[MerchantHeadlessCheckoutRawDataViewController] willFetchCardMetadataForState")
        DispatchQueue.main.async {
            self.cardsLabel.text = "🌏"
        }
    }
    
    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, didReceiveCardMetadata metadata: PrimerCardMetadata, forCardValidationState cardState: PrimerCardValidationState) {
        let printableNetworks = metadata.availableCardNetworks.map { $0.networkIdentifier }.joined(separator: ", ")
        print("[MerchantHeadlessCheckoutRawDataViewController] didReceiveCardMetadata: \(printableNetworks) forCardValidationState: \(cardState.cardNumber)")
        DispatchQueue.main.async {
            self.cardsLabel.text = printableNetworks
            self.rawCardData.cardNetworkIdentifier = metadata.preferredCardNetwork?.networkIdentifier
        }
    }
}

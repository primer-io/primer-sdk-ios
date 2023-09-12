//
//  CustomPaymentMethodViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 28/1/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHeadlessCheckoutCardComponentsViewController: UIViewController {
    
    static func instantiate(paymentMethodType: String) -> MerchantHeadlessCheckoutCardComponentsViewController {
        let vc = MerchantHeadlessCheckoutCardComponentsViewController()
        vc.paymentMethodType = paymentMethodType
        return vc
    }
    
    var paymentMethodType: String!
    
    var stackView: UIStackView!
    var cardNumberTextField: PrimerInputTextField?
    var expiryTextField: PrimerInputTextField?
    var cvvTextField: PrimerInputTextField?
    var cardHolderNameTextField: PrimerInputTextField?
    var activityIndicator: UIActivityIndicatorView?
    var paymentButton: UIButton!
    
    var paymentId: String?
    var resumePaymentId: String?
    
    var threeDSAlert: UIAlertController?
    var logs: [String] = []
    
    var cardComponentsManager: PrimerHeadlessUniversalCheckout.CardComponentsManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        self.paymentButton = UIButton()
        self.paymentButton.accessibilityIdentifier = "submit_btn"
        self.paymentButton.backgroundColor = .black
        self.paymentButton.setTitle("Pay now", for: .normal)
        self.paymentButton.setTitleColor(.white, for: .normal)
        self.view.addSubview(self.paymentButton)
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.spacing = 6
        self.view.addSubview(self.stackView)
        
        self.paymentButton.translatesAutoresizingMaskIntoConstraints = false
        self.paymentButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.paymentButton.addTarget(self, action: #selector(paymentButtonTapped), for: .touchUpInside)
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
                
        self.cardComponentsManager = try! PrimerHeadlessUniversalCheckout.CardComponentsManager()
        self.cardComponentsManager!.delegate = self
        
        var tmpInputElements: [PrimerHeadlessUniversalCheckoutInputElement] = []
        for inputElementType in self.cardComponentsManager!.requiredInputElementTypes {
            let textField = PrimerInputTextField(type: inputElementType, frame: .zero)
            textField.borderStyle = .line
            textField.layer.borderColor = UIColor.black.cgColor
            textField.inputElementDelegate = self
            self.stackView.addArrangedSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            if inputElementType == .cardNumber {
                self.cardNumberTextField = textField
                self.cardNumberTextField?.accessibilityIdentifier = "card_txt_fld"
                self.cardNumberTextField?.placeholder = "Card number"
            } else if inputElementType == .expiryDate {
                self.expiryTextField = textField
                self.expiryTextField?.accessibilityIdentifier = "expiry_txt_fld"
                self.expiryTextField?.placeholder = "Expiry"
            } else if inputElementType == .cvv {
                self.cvvTextField = textField
                self.cvvTextField?.accessibilityIdentifier = "cvc_txt_fld"
                self.cvvTextField?.placeholder = "CVV"
            } else if inputElementType == .cardholderName {
                self.cardHolderNameTextField = textField
                self.cardHolderNameTextField?.accessibilityIdentifier = "card_holder_txt_fld"
                self.cardHolderNameTextField?.placeholder = "Cardholder"
            }
            
            tmpInputElements.append(textField)
        }
        
        self.cardComponentsManager?.inputElements = tmpInputElements
        self.stackView.addArrangedSubview(self.paymentButton)
    }
    
    @objc
    func paymentButtonTapped() {
        self.cardComponentsManager?.submit()
    }
    
    // MARK: - HELPERS
    
    private func showLoadingOverlay() {
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.view.addSubview(self.activityIndicator!)
        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
        self.activityIndicator?.color = .black
        self.activityIndicator?.startAnimating()
    }
    
    private func hideLoadingOverlay() {
        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        self.activityIndicator = nil
    }
}

extension MerchantHeadlessCheckoutCardComponentsViewController: PrimerInputElementDelegate {
    
    func inputElementDidFocus(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {
        
    }
    
    func inputElementDidBlur(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {
        
    }
    
    func inputElementValueDidChange(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {
        
    }
}

extension MerchantHeadlessCheckoutCardComponentsViewController: PrimerHeadlessUniversalCheckoutCardComponentsManagerDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: PrimerHeadlessUniversalCheckout.CardComponentsManager, isCardFormValid: Bool) {
        
    }
}

//
//  CustomPaymentMethodViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 28/1/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantCardFormViewController: UIViewController {
    
    var stackView: UIStackView!
    
    var cardNumberTextField: PrimerInputTextField?
    var expiryTextField: PrimerInputTextField?
    var cvvTextField: PrimerInputTextField?
    var cardHolderNameTextField: PrimerInputTextField?
    var environment: Environment = .staging
    var threeDSAlert: UIAlertController?
    var resumePaymentId: String?
    var paymentResponsesData: [Data] = []
    var activityIndicator: UIActivityIndicatorView?
    var paymentButton: UIButton!
    var paymentId: String?
    
    var cardComponentsManager: PrimerHeadlessUniversalCheckout.CardComponentsManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        self.paymentButton = UIButton()
        self.paymentButton.backgroundColor = .black
        self.paymentButton.setTitle("Pay now", for: .normal)
        self.paymentButton.setTitleColor(.white, for: .normal)
        self.view.addSubview(self.paymentButton)
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.spacing = 6
        self.view.addSubview(self.stackView)

        self.paymentButton.translatesAutoresizingMaskIntoConstraints = false
        self.paymentButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.paymentButton.topAnchor.constraint(greaterThanOrEqualTo: self.stackView.bottomAnchor, constant: 30).isActive = true
        self.paymentButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        self.paymentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        self.paymentButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.paymentButton.addTarget(self, action: #selector(paymentButtonTapped), for: .touchUpInside)

        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true

        PrimerHeadlessUniversalCheckout.current.delegate = self
        self.cardComponentsManager = PrimerHeadlessUniversalCheckout.CardComponentsManager()
        cardComponentsManager?.delegate = self

        var tmpInputElements: [PrimerInputTextField] = []
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
                self.cardNumberTextField?.placeholder = "Card number"
            } else if inputElementType == .expiryDate {
                self.expiryTextField = textField
                self.expiryTextField?.placeholder = "Expiry"
            } else if inputElementType == .cvv {
                self.cvvTextField = textField
                self.cvvTextField?.placeholder = "CVV"
            } else if inputElementType == .cardholderName {
                self.cardHolderNameTextField = textField
                self.cardHolderNameTextField?.placeholder = "Cardholder"
            }

            tmpInputElements.append(textField)
        }

        self.cardComponentsManager?.inputElements = tmpInputElements
    }

    @objc
    func paymentButtonTapped() {
        self.cardComponentsManager?.submit()
    }
}

extension MerchantCardFormViewController: PrimerHeadlessUniversalCheckoutDelegate {

    func primerHeadlessUniversalCheckoutPreparationDidStart(for paymentMethodType: String) {
        print("✅ \(#function)")
    }
    
    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethodTypes: [String]) {
        print("✅ \(#function)\npaymentMethodTypes: \(paymentMethodTypes)")
    }
    
    func primerHeadlessUniversalCheckoutTokenizationStarted(paymentMethodType: String) {
        print("ℹ️ \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
    
    func primerHeadlessUniversalCheckoutTokenizationDidStart(for paymentMethodType: String) {
        print("✅ \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
        
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("✅ \(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        
        Networking.createPayment(with: paymentMethodTokenData) { (res, err) in
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
            }

            if let err = err {
                // No need to handle anything
            } else if let res = res {
                self.paymentId = res.id
                
                if res.requiredAction?.clientToken != nil {
                    decisionHandler(.continueWithNewClientToken(res.requiredAction!.clientToken))
                } else {
                    if let data = try? JSONEncoder().encode(res) {
//                        DispatchQueue.main.async {
//                            let rvc = HUCResultViewController.instantiate(data: [data])
//                            self.navigationController?.pushViewController(rvc, animated: true)
//                        }
                    }
                }

            } else {
                assert(true)
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("ℹ️ \(#function)\nresumeToken: \(resumeToken)")
        
        Networking.resumePayment(self.paymentId!, withToken: resumeToken) { (res, err) in
            if let err = err {
                // ...
            } else {
                decisionHandler(.succeed())
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: Error) {
        print("🚨 \(#function)\nerror: \(err)")
    }
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("✅ \(#function)\ndata: \(data)")
        
        let message = """
PaymentId: \(data.payment?.id ?? "unknown")
OrderId: \(data.payment?.orderId ?? "unknown")
"""
        
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert);
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel) { _ in alert.dismiss(animated: true) })
        self.navigationController?.present(alert, animated: true)
    }
    
    func primerHeadlessUniversalCheckoutClientSessionWillUpdate() {
        print("ℹ️ \(#function)")
    }
    
    func primerHeadlessUniversalCheckoutClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        print("ℹ️ \(#function)\nclientSession: \(clientSession)")
    }
    
    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("ℹ️ \(#function)\ndata: \(data)")
        decisionHandler(.continuePaymentCreation())
    }

}

extension MerchantCardFormViewController: PrimerInputElementDelegate {
    
    func inputElementDidFocus(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {

    }

    func inputElementDidBlur(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {

    }

    func inputElementValueDidChange(_ sender: PrimerHeadlessUniversalCheckoutInputElement) {

    }
}

extension MerchantCardFormViewController: PrimerHeadlessUniversalCheckoutCardComponentsManagerDelegate {
    func cardComponentsManager(_ cardComponentsManager: PrimerSDK.PrimerHeadlessUniversalCheckout.CardComponentsManager, isCardFormValid: Bool) {

        print("ℹ️ \(#function)\nisCardFormValid: \(isCardFormValid)")
    }
    
    
}

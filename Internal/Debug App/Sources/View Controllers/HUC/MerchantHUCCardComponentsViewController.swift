//
//  CustomPaymentMethodViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 28/1/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHUCCardComponentsViewController: UIViewController, PrimerHeadlessUniversalCheckoutDelegate {
    
    static func instantiate(paymentMethodType: String) -> MerchantHUCCardComponentsViewController {
        let vc = MerchantHUCCardComponentsViewController()
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
    
    var checkoutData: [String] = []
    var primerError: Error?
    var logs: [String] = []
    
    var cardFormUIManager: PrimerHeadlessUniversalCheckout.CardFormUIManager?
    
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

        self.cardFormUIManager = try! PrimerHeadlessUniversalCheckout.CardFormUIManager(paymentMethodType: self.paymentMethodType)

        var tmpInputElements: [PrimerInputElement] = []
        for inputElementType in self.cardFormUIManager!.requiredInputElementTypes {
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

        self.cardFormUIManager?.inputElements = tmpInputElements
    }

    @objc
    func paymentButtonTapped() {
        self.cardFormUIManager?.tokenize()
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

// MARK: - PRIMER HEADLESS UNIVERSAL CHECKOUT DELEGATE

// MARK: Auto Payment Handling

extension MerchantHUCCardComponentsViewController {
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        self.logs.append(#function)
        
        if let checkoutDataDictionary = try? data.asDictionary(),
           let jsonData = try? JSONSerialization.data(withJSONObject: checkoutDataDictionary, options: .prettyPrinted),
           let jsonString = jsonData.prettyPrintedJSONString {
            self.checkoutData.append(jsonString as String)
        }
        
        self.hideLoadingOverlay()
        
        let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
        self.navigationController?.pushViewController(rvc, animated: true)
    }
}

// MARK: Manual Payment Handling

extension MerchantHUCCardComponentsViewController {
    
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        self.logs.append(#function)
        
        Networking.createPayment(with: paymentMethodTokenData) { (res, err) in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                self.hideLoadingOverlay()

            } else if let res = res {
                self.paymentId = res.id
                
                if res.requiredAction?.clientToken != nil {
                    decisionHandler(.continueWithNewClientToken(res.requiredAction!.clientToken))
                    
                } else {
                    self.hideLoadingOverlay()
                    let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
                    self.navigationController?.pushViewController(rvc, animated: true)
                }

            } else {
                assert(true)
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\nresumeToken: \(resumeToken)")
        self.logs.append(#function)
        
        Networking.resumePayment(self.paymentId!, withToken: resumeToken) { (res, err) in
            DispatchQueue.main.async {
                self.hideLoadingOverlay()
            }
            
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                decisionHandler(.fail(withErrorMessage: "Merchant App\nFailed to resume payment."))
            } else {
                decisionHandler(.succeed())
            }
            
            let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
    }
}

// MARK: Common

extension MerchantHUCCardComponentsViewController {

    func primerHeadlessUniversalCheckoutDidLoadAvailablePaymentMethods(_ paymentMethodTypes: [String]) {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutPreparationDidStart(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
        self.showLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutTokenizationDidStart(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutPaymentMethodDidShow(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(additionalInfo)")
        self.logs.append(#function)
        DispatchQueue.main.async {
            self.hideLoadingOverlay()
        }
    }
    
    func primerHeadlessUniversalCheckoutDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(additionalInfo)")
        self.logs.append(#function)
        self.hideLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: Error) {
        print("\n\nMERCHANT APP\n\(#function)\nerror: \(err)")
        self.logs.append(#function)
        
        self.primerError = err
        self.hideLoadingOverlay()
    }
    
    func primerHeadlessUniversalCheckoutClientSessionWillUpdate() {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        print("\n\nMERCHANT APP\n\(#function)\nclientSession: \(clientSession)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        self.logs.append(#function)
        decisionHandler(.continuePaymentCreation())
    }
}

extension MerchantHUCCardComponentsViewController: PrimerInputElementDelegate {
    
    func inputElementDidFocus(_ sender: PrimerInputElement) {

    }

    func inputElementDidBlur(_ sender: PrimerInputElement) {

    }

    func inputElementValueDidChange(_ sender: PrimerInputElement) {

    }
}

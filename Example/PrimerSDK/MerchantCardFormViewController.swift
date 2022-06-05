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

        self.cardFormUIManager = try! PrimerHeadlessUniversalCheckout.CardFormUIManager()

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
}

extension MerchantCardFormViewController: PrimerHeadlessUniversalCheckoutDelegate {
    
    func primerHeadlessUniversalCheckoutPreparationStarted() {
        print("🤯🤯🤯 \(#function)")
    }
    
    func primerHeadlessUniversalCheckoutClientSessionDidSetUpSuccessfully(paymentMethods: [String]) {
        print("🤯🤯🤯 \(#function)\npaymentMethods: \(paymentMethods)")
    }
    
    func primerHeadlessUniversalCheckoutTokenizationStarted(paymentMethodType: String) {
        print("🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
    
    func primerHeadlessUniversalCheckoutPaymentMethodPresented(paymentMethodType: String) {
        print("🤯🤯🤯 \(#function)\npaymentMethodType: \(paymentMethodType)")
    }
    
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("🤯🤯🤯 \(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        
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
    
    func primerHeadlessUniversalDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("🤯🤯🤯 \(#function)\nresumeToken: \(resumeToken)")
        
        Networking.resumePayment(self.paymentId!, withToken: resumeToken) { (res, err) in
            if let err = err {
                // ...
            } else {
                decisionHandler(.succeed())
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: Error) {
        print("🤯🤯🤯 \(#function)\nerror: \(err)")
    }
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("🤯🤯🤯 \(#function)\ndata: \(data)")
    }
    
    func primerClientSessionWillUpdate() {
        print("🤯🤯🤯 \(#function)")
    }
    
    func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        print("🤯🤯🤯 \(#function)\nclientSession: \(clientSession)")
    }
    
    func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("🤯🤯🤯 \(#function)\ndata: \(data)")
        decisionHandler(.continuePaymentCreation())
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    func primerHeadlessUniversalCheckoutResume(withResumeToken resumeToken: String, resumeHandler: ResumeHandlerProtocol?) {
//
//    }
//
//    func primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol?) {
//        if let threeDSecureAuthentication = paymentMethodToken.threeDSecureAuthentication,
//           (threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.notPerformed && threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.authSuccess) {
//            var message: String = ""
//
//            if let reasonCode = threeDSecureAuthentication.reasonCode {
//                message += "[\(reasonCode)] "
//            }
//
//            if let reasonText = threeDSecureAuthentication.reasonText {
//                message += reasonText
//            }
//
//            threeDSAlert = UIAlertController(title: "3DS Error", message: message, preferredStyle: .alert)
//            threeDSAlert?.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
//                self?.threeDSAlert = nil
//            }))
//        }
//
//        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
//        self.view.addSubview(self.activityIndicator!)
//        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
//        self.activityIndicator?.color = .black
//        self.activityIndicator?.startAnimating()
//
//        Networking.createPayment(with: paymentMethodToken) { (res, err) in
//            DispatchQueue.main.async {
//                self.activityIndicator?.stopAnimating()
//                self.activityIndicator?.removeFromSuperview()
//                self.activityIndicator = nil
//
//                if !self.paymentResponsesData.isEmpty {
//                    let rvc = HUCResultViewController.instantiate(data: self.paymentResponsesData)
//                    self.navigationController?.pushViewController(rvc, animated: true)
//                }
//            }
//
//            if let err = err {
//                resumeHandler?.handle(error: err)
//            } else if let res = res {
//                if let data = try? JSONEncoder().encode(res) {
//                    DispatchQueue.main.async {
//                        let rvc = HUCResultViewController.instantiate(data: [data])
//                        self.navigationController?.pushViewController(rvc, animated: true)
//                    }
//                }
//
//                guard let requiredAction = res.requiredAction else {
//                    resumeHandler?.handleSuccess()
//                    return
//                }
//
//                self.resumePaymentId = res.id
//
//                if requiredAction.name == .threeDSAuthentication, res.status == .pending {
//                    resumeHandler?.handle(newClientToken: requiredAction.clientToken)
//                } else {
//                    resumeHandler?.handleSuccess()
//                }
//
//            } else {
//                assert(true)
//            }
//        }
//    }
//
//    func primerHeadlessUniversalCheckoutPreparationStarted() {
//
//    }
//
//    func primerHeadlessUniversalCheckoutTokenizationStarted() {
//
//    }
//
//    func primerHeadlessUniversalCheckoutClientSessionDidSetUpSuccessfully() {
//
//    }
//
//    func primerHeadlessUniversalCheckoutPaymentMethodPresented() {
//
//    }
//
//    func primerHeadlessUniversalCheckoutTokenizationSucceededTokenizationSucceeded(paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol?) {
//
//    }
//
//    func primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError err: Error) {
//        DispatchQueue.main.async {
//            self.activityIndicator?.stopAnimating()
//            self.activityIndicator?.removeFromSuperview()
//            self.activityIndicator = nil
//
//            if !self.paymentResponsesData.isEmpty {
//                let rvc = HUCResultViewController.instantiate(data: self.paymentResponsesData)
//                self.navigationController?.pushViewController(rvc, animated: true)
//            }
//        }
//        print(err)
//    }
 
}

extension MerchantCardFormViewController: PrimerInputElementDelegate {
    func inputElementDidFocus(_ sender: PrimerInputElement) {

    }

    func inputElementDidBlur(_ sender: PrimerInputElement) {

    }

    func inputElementValueDidChange(_ sender: PrimerInputElement) {

    }
}

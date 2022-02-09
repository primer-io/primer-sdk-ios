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
    lazy var endpoint: String = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    
    var cardNumberTextField: PrimerCheckoutComponents.TextField?
    var expiryTextField: PrimerCheckoutComponents.TextField?
    var cvvTextField: PrimerCheckoutComponents.TextField?
    var cardHolderNameTextField: PrimerCheckoutComponents.TextField?
    var environment: Environment = .staging
    var threeDSAlert: UIAlertController?
    var transactionResponse: TransactionResponse?
    var paymentResponsesData: [Data] = []
    var activityIndicator: UIActivityIndicatorView?
    var paymentButton: UIButton!
    
    var checkoutComponentsUIManager: PrimerCheckoutComponents.CardFormUIManager?
    
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

        PrimerCheckoutComponents.delegate = self

        self.checkoutComponentsUIManager = try! PrimerCheckoutComponents.CardFormUIManager(paymentMethodType: .paymentCard)

        var tmpInputElements: [PrimerInputElement] = []
        for inputElementType in self.checkoutComponentsUIManager!.requiredInputElementTypes {
            let textField = PrimerCheckoutComponents.TextField(type: inputElementType, frame: .zero)
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

        self.checkoutComponentsUIManager?.inputElements = tmpInputElements
    }

    @objc
    func paymentButtonTapped() {
        self.checkoutComponentsUIManager?.startTokenization()
    }
}

extension MerchantCardFormViewController: PrimerCheckoutComponentsDelegate {
    func onEvent(_ event: PrimerCheckoutComponentsEvent) {
        print("🖖🖖🖖\nEvent: \(event)\n\n")
        switch event {
        case .tokenizationStarted:
            break
            
        case .tokenizationSucceeded(let paymentMethodToken, let resumeHandler):
            if let threeDSecureAuthentication = paymentMethodToken.threeDSecureAuthentication,
               (threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.notPerformed && threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.authSuccess) {
                var message: String = ""

                if let reasonCode = threeDSecureAuthentication.reasonCode {
                    message += "[\(reasonCode)] "
                }

                if let reasonText = threeDSecureAuthentication.reasonText {
                    message += reasonText
                }

                threeDSAlert = UIAlertController(title: "3DS Error", message: message, preferredStyle: .alert)
                threeDSAlert?.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                    self?.threeDSAlert = nil
                }))
            }

            self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
            self.view.addSubview(self.activityIndicator!)
            self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
            self.activityIndicator?.color = .black
            self.activityIndicator?.startAnimating()

            let networking = Networking()
            networking.createPayment(with: paymentMethodToken) { (res, err) in
                DispatchQueue.main.async {
                    self.activityIndicator?.stopAnimating()
                    self.activityIndicator?.removeFromSuperview()
                    self.activityIndicator = nil

                    if !self.paymentResponsesData.isEmpty {
                        let rvc = ResultViewController.instantiate(data: self.paymentResponsesData)
                        self.navigationController?.pushViewController(rvc, animated: true)
                    }
                }

                if let err = err {
                    resumeHandler?.handle(error: err)
                } else if let res = res {
                    guard let requiredAction = res.requiredAction else {
                        resumeHandler?.handleSuccess()
                        return
                    }
                    
                    guard let dateStr = res.dateStr else {
                        resumeHandler?.handleSuccess()
                        return
                    }
                    
                    self.transactionResponse = TransactionResponse(
                        id: res.id,
                        date: dateStr,
                        status: res.status.rawValue,
                        requiredAction: requiredAction)
                    
                    if requiredAction.name == "3DS_AUTHENTICATION", res.status == .pending {
                        resumeHandler?.handle(newClientToken: requiredAction.clientToken)
                    } else {
                        resumeHandler?.handleSuccess()
                    }

                } else {
                    assert(true)
                }
            }

        case .failure(let err):
            print(err)
        case .preparationStarted:
            break
        case .paymentMethodPresented:
            break
        case .clientSessionSetupSuccessfully:
            break
        }
    }
 
}

extension MerchantCardFormViewController: PrimerInputElementDelegate {
    func inputElementDidFocus(_ sender: PrimerInputElement) {

    }

    func inputElementDidBlur(_ sender: PrimerInputElement) {

    }

    func inputElementValueDidChange(_ sender: PrimerInputElement) {

    }
}

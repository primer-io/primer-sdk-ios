//
//  CustomPaymentMethodViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 28/1/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantCardFormViewController: PrimerCheckoutComponents.PaymentMethodViewController, UITextFieldDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.paymentMethodType = .paymentCard
        self.delegate = self
        
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
        
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        self.stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
        let requiredInputElementTypes = PrimerCheckoutComponents.listInputElementTypes(for: paymentMethodType)
        
        requiredInputElementTypes.forEach { inputElementType in
            let textField = PrimerCheckoutComponents.TextField(type: inputElementType, frame: .zero)
            textField.borderStyle = .line
            textField.layer.borderColor = UIColor.black.cgColor
            textField.inputElementDelegate = self
            self.stackView.addArrangedSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
            self.inputElements.append(textField)
            
            if inputElementType == .cardNumber {
                self.cardNumberTextField = textField
            } else if inputElementType == .expiryDate {
                self.expiryTextField = textField
            } else if inputElementType == .cvv {
                self.cvvTextField = textField
            } else if inputElementType == .cardholderName {
                self.cardHolderNameTextField = textField
            }
        }
        
        self.cardNumberTextField?.placeholder = "Card number"
        self.expiryTextField?.placeholder = "Expiry"
        self.cvvTextField?.placeholder = "CVV"
        self.cardHolderNameTextField?.placeholder = "Cardholder"
        
//        self.cardNumberTextField?.text = "4242 4242 4242 4242"
//        self.expiryTextField?.text = "02/23"
//        self.cvvTextField?.text = "123"
//        self.cardHolderNameTextField?.text = "John Smith"
        
        self.requestClientToken()
    }
    
    private func requestClientToken() {
        let clientSessionRequestBody = ClientSessionRequestBody(
            customerId: "customerId",
            orderId: "ios_order_id_\(String.randomString(length: 8))",
            currencyCode: .EUR,
            amount: nil,
            metadata: ["key": "val"],
            customer: ClientSessionRequestBody.Customer(
                firstName: "John",
                lastName: "Smith",
                emailAddress: "john@primer.io",
                mobileNumber: "+4478888888888",
                billingAddress: Address(
                    firstName: "John",
                    lastName: "Smith",
                    addressLine1: "65 York Road",
                    addressLine2: nil,
                    city: "London",
                    state: nil,
                    countryCode: "GB",
                    postalCode: "NW06 4OM"),
                shippingAddress: Address(
                    firstName: "John",
                    lastName: "Smith",
                    addressLine1: "9446 Richmond Road",
                    addressLine2: nil,
                    city: "London",
                    state: nil,
                    countryCode: "GB",
                    postalCode: "EC53 8BT")
            ),
            order: ClientSessionRequestBody.Order(
                countryCode: .fr,
                lineItems: [
                    ClientSessionRequestBody.Order.LineItem(
                        itemId: "_item_id_0",
                        description: "Item",
                        amount: 1000,
                        quantity: 1)
                ]),
            paymentMethod: ClientSessionRequestBody.PaymentMethod(
                vaultOnSuccess: true,
                options: [
                    "PAYMENT_CARD": [
                        "networks": [
                            "VISA": [
                                "surcharge": [
                                    "amount": 109
                                ]
                            ],
                            "MASTERCARD": [
                                "surcharge": [
                                    "amount": 129
                                ]
                            ]
                        ]
                    ]
                ]
            )
        )
        
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.view.addSubview(self.activityIndicator!)
        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
        self.activityIndicator?.color = .black
        self.activityIndicator?.startAnimating()
        requestClientSession(requestBody: clientSessionRequestBody, completion: { (token, err) in
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
            }
            
            if let token = token {
                self.clientToken = token
            }
        })
    }
    
    func requestClientSession(requestBody: ClientSessionRequestBody, completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/api/client-session") else {
            return completion(nil, NetworkError.missingParams)
        }
        
        let bodyData: Data!
        
        do {
            if let requestBodyJson = requestBody.dictionaryValue {
                bodyData = try JSONSerialization.data(withJSONObject: requestBodyJson, options: .fragmentsAllowed)
            } else {
                completion(nil, NetworkError.serializationError)
                return
            }
        } catch {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        let networking = Networking()
        networking.request(
            environment: environment,
            apiVersion: .v3,
            url: url,
            method: .post,
            headers: nil,
            queryParameters: nil,
            body: bodyData) { result in
                switch result {
                case .success(let data):
                    do {
                        if let token = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any])?["clientToken"] as? String {
                            self.clientToken = token
                            completion(token, nil)
                        } else {
                            let err = NSError(domain: "example", code: 10, userInfo: [NSLocalizedDescriptionKey: "Failed to find client token"])
                            completion(nil, err)
                        }
                        
                    } catch {
                        completion(nil, error)
                    }
                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
    
    func createPayment(with paymentMethod: PaymentMethodToken, _ completion: @escaping ([String: Any]?, Error?) -> Void) {
        guard let paymentMethodToken = paymentMethod.token else {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        guard let url = URL(string: "\(endpoint)/api/payments/") else {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        let body = Payment.Request(paymentMethodToken: paymentMethodToken)
        
        var bodyData: Data!
        
        do {
            bodyData = try JSONEncoder().encode(body)
        } catch {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        let networking = Networking()
        networking.request(
            environment: environment,
            apiVersion: .v2,
            url: url,
            method: .post,
            headers: nil,
            queryParameters: nil,
            body: bodyData) { result in
                switch result {
                case .success(let data):
                    let paymentResponse = try? JSONDecoder().decode(Payment.Response.self, from: data)
                    if paymentResponse != nil {
                        self.paymentResponsesData.append(data)
                    }
                    
                    if let dic = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] {
                        completion(dic, nil)
                    } else {
                        let err = NetworkError.invalidResponse
                        completion(nil, err)
                    }
                    
                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
}

extension MerchantCardFormViewController: PrimerCheckoutComponentsDelegate {
    func onEvent(_ event: PrimerCheckoutComponentsEvent) {
        switch event {
        case .tokenizationStarted:
            break
        case .tokenizationSuccess(let paymentMethodToken, let resumeHandler):
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
            
            createPayment(with: paymentMethodToken) { (res, err) in
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
                    guard let requiredActionDic = res["requiredAction"] as? [String: Any] else {
                        resumeHandler?.handleSuccess()
                        return
                    }
                    
                    guard let id = res["id"] as? String,
                          let date = res["date"] as? String,
                          let status = res["status"] as? String,
                          let requiredActionName = requiredActionDic["name"] as? String,
                          let clientToken = requiredActionDic["clientToken"] as? String else {
                              resumeHandler?.handleSuccess()
                              return
                          }
                    
                    self.transactionResponse = TransactionResponse(id: id, date: date, status: status, requiredAction: requiredActionDic)
                    
                    if requiredActionName == "3DS_AUTHENTICATION", status == "PENDING" {
                        resumeHandler?.handle(newClientToken: clientToken)
                    } else if requiredActionName == "USE_PRIMER_SDK", status == "PENDING" {
                        resumeHandler?.handle(newClientToken: clientToken)
                    } else {
                        resumeHandler?.handleSuccess()
                    }
                    
                } else {
                    assert(true)
                }
            }
            
        case .error(let err):
            print(err)
        }
    }
}

extension MerchantCardFormViewController: PrimerInputElementDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        fatalError()
    }
    
    func inputElementDidFocus(_ sender: PrimerInputElement) {
        
    }
    
    func inputElementDidBlur(_ sender: PrimerInputElement) {
        
    }
    
    func inputElementValueIsValid(_ sender: PrimerInputElement, isValid: Bool) {
        
    }
    
    func inputElementDidDetectType(_ sender: PrimerInputElement, type: Any?) {
        self.cvvTextField?.detectedValueType = type
    }
}

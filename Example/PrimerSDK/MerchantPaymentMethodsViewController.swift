//
//  MerchantPaymentMethodsViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 2/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantPaymentMethodsViewController: UIViewController {
    
    static func instantiate(amount: Int, currency: Currency, countryCode: CountryCode) -> MerchantPaymentMethodsViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantPaymentMethodsViewController") as! MerchantPaymentMethodsViewController
        mpmvc.amount = amount
        mpmvc.currency = currency
        mpmvc.countryCode = countryCode
        return mpmvc
    }

    lazy var endpoint: String = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    var environment: Environment!
    var amount: Int!
    var currency: Currency!
    var countryCode: CountryCode!
    var availablePaymentMethods: [PrimerPaymentMethodType] = []
    

    @IBOutlet weak var tableView: UITableView!
    var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PrimerHeadlessUniversalCheckout.current.delegate = self
        
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.view.addSubview(self.activityIndicator!)
        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
        self.activityIndicator?.color = .black
        self.activityIndicator?.startAnimating()
        self.requestClientToken { clientToken, err in
            if let err = err {
                DispatchQueue.main.async {
                    self.activityIndicator?.stopAnimating()
                    self.activityIndicator?.removeFromSuperview()
                    self.activityIndicator = nil
                }
            } else if let clientToken = clientToken {
                let settings = PrimerSettings(
                    merchantIdentifier: "merchant.checkout.team",
                    urlScheme: "merchant://",
                    businessDetails: BusinessDetails(name: "Business Name", address: nil))
                PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: settings, completion: { (pms, err) in
                    DispatchQueue.main.async {
                        self.activityIndicator?.stopAnimating()
                        self.activityIndicator?.removeFromSuperview()
                        self.activityIndicator = nil
                        
                        self.availablePaymentMethods = pms ?? []
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    private func requestClientToken(completion: @escaping (String?, Error?) -> Void) {
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
                        itemId: "shoes-72189",
                        description: "Fancy shoes",
                        amount: 1000,
                        quantity: 1)
                ]),
            paymentMethod: ClientSessionRequestBody.PaymentMethod(
                vaultOnSuccess: false,
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
        
        
        requestClientSession(requestBody: clientSessionRequestBody, completion: { (token, err) in
            completion(token, err)
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
    
}

extension MerchantPaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availablePaymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let paymentMethod = self.availablePaymentMethods[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MerchantPaymentMethodCell", for: indexPath) as! MerchantPaymentMethodCell
        cell.configure(paymentMethodType: paymentMethod)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let paymentMethodType = self.availablePaymentMethods[indexPath.row]
        if paymentMethodType == PaymentMethodConfigType.paymentCard {
            let mcfvc = MerchantCardFormViewController()
            self.navigationController?.pushViewController(mcfvc, animated: true)
        } else {
            PrimerHeadlessUniversalCheckout.current.showPaymentMethod(paymentMethodType)
        }
    }
}

extension MerchantPaymentMethodsViewController: PrimerHeadlessUniversalCheckoutDelegate {
    func primerHeadlessUniversalCheckoutResume(withResumeToken resumeToken: String, resumeHandler: ResumeHandlerProtocol?) {
        
    }

    func primerHeadlessUniversalCheckoutPreparationStarted() {
        
    }
    
    func primerHeadlessUniversalCheckoutTokenizationStarted() {
        
    }
    
    func primerHeadlessUniversalCheckoutClientSessionDidSetUpSuccessfully() {

    }
    
    func tokenizationPreparationStarted() {
        self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
        self.view.addSubview(self.activityIndicator!)
        self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
        self.activityIndicator?.color = .black
        self.activityIndicator?.startAnimating()
    }
    
    func primerHeadlessUniversalCheckoutPaymentMethodPresented() {
        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        self.activityIndicator = nil
    }
    
    func primerHeadlessUniversalCheckoutTokenizationSucceeded(paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol?) {
        Networking.createPayment(with: paymentMethodToken) { (res, err) in
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
            }

            if let err = err {
                
            } else if let res = res {
                if let data = try? JSONEncoder().encode(res) {
                    DispatchQueue.main.async {
                        let rvc = ResultViewController.instantiate(data: [data])
                        self.navigationController?.pushViewController(rvc, animated: true)
                    }
                }

            } else {
                assert(true)
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError err: Error) {
        self.activityIndicator?.stopAnimating()
        self.activityIndicator?.removeFromSuperview()
        self.activityIndicator = nil
    }
}

class MerchantPaymentMethodCell: UITableViewCell {
    
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    
    func configure(paymentMethodType: PrimerPaymentMethodType) {
        paymentMethodLabel.text = paymentMethodType.rawValue
        
        if let button = PrimerHeadlessUniversalCheckout.makeButton(for: paymentMethodType) {
            buttonContainerView.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            button.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            button.topAnchor.constraint(equalTo: topAnchor).isActive = true
            button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            button.isUserInteractionEnabled = false
        }
    }
    
}

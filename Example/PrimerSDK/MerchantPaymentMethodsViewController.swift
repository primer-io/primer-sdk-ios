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
    
    static func instantiate(environment: Environment, amount: Int, currency: Currency, countryCode: CountryCode) -> MerchantPaymentMethodsViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantPaymentMethodsViewController") as! MerchantPaymentMethodsViewController
        mpmvc.environment = environment
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
    var availablePaymentMethods: [PaymentMethodConfigType] = []
    

    @IBOutlet weak var tableView: UITableView!
    var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = PrimerSettings(
            merchantIdentifier: "merchant.dx.team",
            urlScheme: "")
        Primer.shared.configure(settings: settings, theme: nil)
        PrimerCheckoutComponents.delegate = self
        
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
                PrimerCheckoutComponents.listAvailablePaymentMethods(forSession: clientToken) { pms, err in
                    DispatchQueue.main.async {
                        self.activityIndicator?.stopAnimating()
                        self.activityIndicator?.removeFromSuperview()
                        self.activityIndicator = nil
                    }
                    
                    if let err = err {
                        
                    } else if let pms = pms {
                        self.availablePaymentMethods = pms
                        self.tableView.reloadData()
                    }
                }
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
        cell.configure(paymentMethodConfigType: paymentMethod)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let paymentMethod = self.availablePaymentMethods[indexPath.row]
        if paymentMethod == .paymentCard {
            let mcfvc = MerchantCardFormViewController()
            self.navigationController?.pushViewController(mcfvc, animated: true)
        } else {
            PrimerCheckoutComponents.showCheckout(for: paymentMethod)
        }
    }
}

extension MerchantPaymentMethodsViewController: PrimerCheckoutComponentsDelegate {
    func onEvent(_ event: PrimerCheckoutComponentsEvent) {
        DispatchQueue.main.async {
            switch event {
            case .configurationStarted:
                self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
                self.view.addSubview(self.activityIndicator!)
                self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
                self.activityIndicator?.color = .black
                self.activityIndicator?.startAnimating()
                
            case .paymentMethodPresented:
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
                
            case .tokenizationStarted:
                break
            case .tokenizationSuccess(let paymentMethodToken, let resumeHandler):
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
                
            case .error(let err):
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
            }
        }
        print("MerchantPaymentMethodsViewController.onEvent: \(event)")
    }
}

class MerchantPaymentMethodCell: UITableViewCell {
    
    @IBOutlet weak var paymentMethodLabel: UILabel!
    @IBOutlet weak var buttonContainerView: UIView!
    
    func configure(paymentMethodConfigType: PaymentMethodConfigType) {
        paymentMethodLabel.text = paymentMethodConfigType.rawValue
        
        if let button = PrimerCheckoutComponents.getButton(for: paymentMethodConfigType) {
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

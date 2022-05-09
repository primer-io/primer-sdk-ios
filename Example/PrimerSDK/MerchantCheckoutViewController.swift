//
//  MerchantCheckoutViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantCheckoutViewController: UIViewController {
    
    class func instantiate(customerId: String, phoneNumber: String?, countryCode: CountryCode?, currency: Currency?, amount: Int?, performPayment: Bool) -> MerchantCheckoutViewController {
        let mcvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantCheckoutViewController") as! MerchantCheckoutViewController
        mcvc.customerId = customerId
        mcvc.phoneNumber = phoneNumber
        mcvc.performPayment = performPayment
        
        if let countryCode = countryCode {
            mcvc.countryCode = countryCode
        }
        if let currency = currency {
            mcvc.currency = currency
        }
        if let amount = amount {
            mcvc.amount = amount
        }
        
        return mcvc
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postalCodeLabel: UILabel!
    
    var paymentMethodsDataSource: [PaymentMethodToken] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    lazy var endpoint: String = {
        if environment == .local {
            return "https://primer-mock-back-end.herokuapp.com"
        } else {
            return "https://us-central1-primerdemo-8741b.cloudfunctions.net"
        }
    }()
    
    var clientToken: String?
    
    var vaultApayaSettings: PrimerSettings!
    var vaultPayPalSettings: PrimerSettings!
    var vaultKlarnaSettings: PrimerSettings!
    var applePaySettings: PrimerSettings!
    var generalSettings: PrimerSettings!
    var amount = 200
    var currency: Currency = .EUR
    var customerId: String!
    var phoneNumber: String?
    var countryCode: CountryCode = .gb
    var threeDSAlert: UIAlertController?
    var performPayment: Bool = false
    
    var customer: PrimerSDK.Customer?
    var address: PrimerSDK.Address?
    var checkoutData: CheckoutData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        generalSettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: nil,
            urlScheme: "merchant://",
            urlSchemeIdentifier: "merchant",
            isFullScreenOnly: false,
            hasDisabledSuccessScreen: false,
            businessDetails: BusinessDetails(name: "Business Name", address: nil),
            directDebitHasNoAmount: false,
            isInitialLoadingHidden: false,
            is3DSOnVaultingEnabled: true,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )
        
        let configuration = PrimerConfiguration(settings: generalSettings)
        Primer.shared.configure(configuration: configuration, delegate: self)
    }
    
    // MARK: - ACTIONS
    
    @IBAction func addApayaButtonTapped(_ sender: Any) {
        vaultApayaSettings = PrimerSettings(
            isFullScreenOnly: true,
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        let configuration = PrimerConfiguration(settings: vaultApayaSettings)
        Primer.shared.configure(configuration: configuration, delegate: self)
    }
    
    @IBAction func addCardButtonTapped(_ sender: Any) {
        let cardSettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: nil,
            urlScheme: "merchant://",
            urlSchemeIdentifier: "merchant",
            isFullScreenOnly: false,
            hasDisabledSuccessScreen: false,
            businessDetails: nil,
            directDebitHasNoAmount: false,
            isInitialLoadingHidden: true,
            is3DSOnVaultingEnabled: true,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )
        
        let configuration = PrimerConfiguration(settings: cardSettings)
        Primer.shared.configure(configuration: configuration, delegate: self)
        Primer.shared.showPaymentMethod(.paymentCard, withIntent: .checkout, on: self)
    }
    
    @IBAction func addPayPalButtonTapped(_ sender: Any) {
        vaultPayPalSettings = PrimerSettings(
            urlScheme: "merchant://",
            urlSchemeIdentifier: "merchant",
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        let configuration = PrimerConfiguration(settings: vaultPayPalSettings)
        Primer.shared.configure(configuration: configuration, delegate: self)
        Primer.shared.showPaymentMethod(.payPal, withIntent: .checkout, on: self)
    }
    
    @IBAction func addKlarnaButtonTapped(_ sender: Any) {
        vaultKlarnaSettings = PrimerSettings(
            klarnaSessionType: .recurringPayment,
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        let configuration = PrimerConfiguration(settings: vaultKlarnaSettings)
        Primer.shared.configure(configuration: configuration, delegate: self)
        Primer.shared.showPaymentMethod(.klarna, withIntent: .vault, on: self)
    }
    
    @IBAction func addApplePayButtonTapped(_ sender: Any) {
        applePaySettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        let configuration = PrimerConfiguration(settings: applePaySettings)
        Primer.shared.configure(configuration: configuration, delegate: self)
        Primer.shared.showPaymentMethod(.applePay, withIntent: .checkout, on: self)
    }
    
    @IBAction func openVaultButtonTapped(_ sender: Any) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\n")
        
        let clientSessionRequestBody = ClientSessionRequestBody(
            customerId: customerId,
            orderId: "ios_order_id_\(String.randomString(length: 8))",
            currencyCode: currency,
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
                countryCode: countryCode,
                lineItems: [
                    ClientSessionRequestBody.Order.LineItem(
                        itemId: "shoes-28190",
                        description: "Fancy shoes",
                        amount: amount,
                        quantity: 2)
                ]),
            paymentMethod: ClientSessionRequestBody.PaymentMethod(
                vaultOnSuccess: true,
                options:
                [
                    "APPLE_PAY": [
                        "surcharge": [
                            "amount": 19
                        ]
                    ],
                    "PAY_NL_IDEAL": [
                        "surcharge": [
                            "amount": 39
                        ]
                    ],
                    "PAYPAL": [
                        "surcharge": [
                            "amount": 49
                        ]
                    ],
                    "ADYEN_TWINT": [
                        "surcharge": [
                            "amount": 59
                        ]
                    ],
                    "ADYEN_IDEAL": [
                        "surcharge": [
                            "amount": 69
                        ]
                    ],
                    "ADYEN_GIROPAY": [
                        "surcharge": [
                            "amount": 79
                        ]
                    ],
                    "BUCKAROO_BANCONTACT": [
                        "surcharge": [
                            "amount": 89
                        ]
                    ],
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
        
        let networking = Networking()
        networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                
            } else if let clientToken = clientToken {
                self.clientToken = clientToken
                self.generalSettings = PrimerSettings(
                    merchantIdentifier: "merchant.checkout.team",
                    klarnaSessionType: .recurringPayment,
                    klarnaPaymentDescription: nil,
                    urlScheme: "merchant://",
                    urlSchemeIdentifier: "merchant",
                    isFullScreenOnly: false,
                    hasDisabledSuccessScreen: false,
                    directDebitHasNoAmount: false,
                    isInitialLoadingHidden: false,
                    is3DSOnVaultingEnabled: true,
                    debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
                )
                
                let configuration = PrimerConfiguration(settings: self.generalSettings)
                Primer.shared.configure(configuration: configuration, delegate: self)
                Primer.shared.showVaultManager(on: self, clientToken: clientToken, completion: nil)
            }
        }
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\n")
        
        let clientSessionRequestBody = ClientSessionRequestBody(
            customerId: customerId,
            orderId: "ios_order_id_\(String.randomString(length: 8))",
            currencyCode: currency,
            amount: nil,
            metadata: nil, //["key": "val"],
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
                countryCode: countryCode,
                lineItems: [
                    ClientSessionRequestBody.Order.LineItem(
                        itemId: "_item_id_0",
                        description: "Item",
                        amount: amount,
                        quantity: 1)
                ]),
            paymentMethod: ClientSessionRequestBody.PaymentMethod(
                vaultOnSuccess: false,
                options:
                [
                    "APPLE_PAY": [
                        "surcharge": [
                            "amount": 19
                        ]
                    ],
                    "PAY_NL_IDEAL": [
                        "surcharge": [
                            "amount": 39
                        ]
                    ],
                    "PAYPAL": [
                        "surcharge": [
                            "amount": 49
                        ]
                    ],
                    "ADYEN_TWINT": [
                        "surcharge": [
                            "amount": 59
                        ]
                    ],
                    "ADYEN_IDEAL": [
                        "surcharge": [
                            "amount": 69
                        ]
                    ],
                    "ADYEN_GIROPAY": [
                        "surcharge": [
                            "amount": 79
                        ]
                    ],
                    "BUCKAROO_BANCONTACT": [
                        "surcharge": [
                            "amount": 89
                        ]
                    ],
                    "PAYMENT_CARD": [
                        "networks": [
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
        
        let networking = Networking()
        networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                
            } else if let clientToken = clientToken {
                self.clientToken = clientToken
                self.generalSettings = PrimerSettings(
                    merchantIdentifier: "merchant.checkout.team",
                    klarnaSessionType: .recurringPayment,
                    klarnaPaymentDescription: nil,
                    urlScheme: "merchant://",
                    urlSchemeIdentifier: "merchant",
                    isFullScreenOnly: false,
                    hasDisabledSuccessScreen: false,
                    directDebitHasNoAmount: false,
                    isInitialLoadingHidden: false,
                    is3DSOnVaultingEnabled: true,
                    debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
                )
                
                let configuration = PrimerConfiguration(settings: self.generalSettings)
                Primer.shared.configure(configuration: configuration, delegate: self)
                Primer.shared.showUniversalCheckout(on: self, clientToken: clientToken, completion: nil)
            }
        }
    }
}

// MARK: - PRIMER DELEGATE

extension MerchantCheckoutViewController: PrimerDelegate {
    
    func primerWillCreatePaymentWithData(_ data: CheckoutPaymentMethodData, decisionHandler: @escaping (PaymentCreationDecision?) -> Void) {
        decisionHandler(.continuePaymentCreation())
    }
    
    func primerDidFailWithError(_ error: Error, data: CheckoutData?, decisionHandler: @escaping ((ErrorDecision) -> Void)) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nPayment Failed\n")
        let message = "Merchant App | ERROR"
        decisionHandler(.showErrorMessage(message))
    }
        
    func primerDidCompleteCheckoutWithData(_ data: CheckoutData, decisionHandler: @escaping ((SuccessDecision) -> Void)) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nPayment Success: \(data)\n")
        self.checkoutData = data
        
        let message = "Merchant App | SUCCESS"
        decisionHandler(.showSuccessMessage(message))
    }
    
    func primerDidDismiss() {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\nPrimer view dismissed\n")
        
        DispatchQueue.main.async { [weak self] in
            self?.fetchPaymentMethods()
            
            if let threeDSAlert = self?.threeDSAlert {
                self?.present(threeDSAlert, animated: true, completion: nil)
            }
            
            if let checkoutData = self?.checkoutData {
                let rvc = ResultViewController.instantiate(data: checkoutData)
                self?.navigationController?.pushViewController(rvc, animated: true)
                self?.checkoutData = nil
            }
        }
    }
}

// MARK: - TABLE VIEW DATA SOURCE & DELEGATE

extension MerchantCheckoutViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentMethodsDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let paymentMethod = paymentMethodsDataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentMethodCell", for: indexPath) as! PaymentMethodCell
        
        switch paymentMethod.paymentInstrumentType {
        case .paymentCard:
            let title = "•••• •••• •••• \(paymentMethod.paymentInstrumentData?.last4Digits ?? "••••")"
            cell.configure(title: title, image: paymentMethod.icon.image!)
        case .payPalBillingAgreement:
            let title = paymentMethod.paymentInstrumentData?.externalPayerInfo?.email ?? "PayPal"
            cell.configure(title: title, image: paymentMethod.icon.image!)
        case .goCardlessMandate:
            let title = "Direct Debit"
            cell.configure(title: title, image: paymentMethod.icon.image!)
        case .klarnaCustomerToken:
            let title = paymentMethod.paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna Customer Token"
            cell.configure(title: title, image: paymentMethod.icon.image!)
        case .apayaToken:
            if let apayaViewModel = ApayaViewModel(paymentMethod: paymentMethod) {
                cell.configure(title: "[\(apayaViewModel.carrier.name)] \(apayaViewModel.hashedIdentifier ?? "")", image: UIImage(named: "mobile"))
            }
        default:
            cell.configure(title: "", image: nil)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentPrimerOptions(indexPath.row)
    }
    
}

internal extension String {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

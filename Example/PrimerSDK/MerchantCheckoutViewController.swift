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
    
    class func instantiate(environment: Environment, customerId: String, phoneNumber: String?, countryCode: CountryCode?, currency: Currency?, amount: Int?, performPayment: Bool) -> MerchantCheckoutViewController {
        let mcvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantCheckoutViewController") as! MerchantCheckoutViewController
        mcvc.environment = environment
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
    var environment = Environment.staging
    var customerId: String!
    var phoneNumber: String?
    var countryCode: CountryCode = .gb
    var threeDSAlert: UIAlertController?
    var transactionResponse: TransactionResponse?
    var performPayment: Bool = false
    
    var customer: PrimerSDK.Customer?
    var address: PrimerSDK.Address?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        generalSettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: nil,
            urlScheme: "primer",
            urlSchemeIdentifier: "primer",
            isFullScreenOnly: false,
            hasDisabledSuccessScreen: false,
            directDebitHasNoAmount: false,
            isInitialLoadingHidden: false,
            is3DSOnVaultingEnabled: true,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )

        Primer.shared.delegate = self
        self.configurePrimer()
        self.fetchPaymentMethods()
    }
    
    func configurePrimer() {
        Primer.shared.configure(settings: generalSettings)
        Primer.shared.configure(theme: CheckoutTheme.primer)
    }
    
    // MARK: - ACTIONS
    
    @IBAction func addApayaButtonTapped(_ sender: Any) {
        vaultApayaSettings = PrimerSettings(
            isFullScreenOnly: true,
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        Primer.shared.configure(settings: vaultApayaSettings)
        Primer.shared.showPaymentMethod(.apaya, withIntent: .vault, on: self)
    }
    
    @IBAction func addCardButtonTapped(_ sender: Any) {
        let cardSettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: nil,
            urlScheme: "primer",
            urlSchemeIdentifier: "primer",
            isFullScreenOnly: false,
            hasDisabledSuccessScreen: false,
            businessDetails: nil,
            directDebitHasNoAmount: false,
            isInitialLoadingHidden: true,
            is3DSOnVaultingEnabled: true,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )
        
        Primer.shared.configure(settings: cardSettings)
        Primer.shared.showPaymentMethod(.paymentCard, withIntent: .checkout, on: self)
    }
    
    @IBAction func addPayPalButtonTapped(_ sender: Any) {
        vaultPayPalSettings = PrimerSettings(
            urlScheme: "primer",
            urlSchemeIdentifier: "primer",
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        Primer.shared.configure(settings: vaultPayPalSettings)
        Primer.shared.showPaymentMethod(.payPal, withIntent: .vault, on: self)
    }
    
    @IBAction func addKlarnaButtonTapped(_ sender: Any) {
        vaultKlarnaSettings = PrimerSettings(
            klarnaSessionType: .recurringPayment,
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        Primer.shared.configure(settings: vaultKlarnaSettings)
        Primer.shared.showPaymentMethod(.klarna, withIntent: .vault, on: self)
    }
    
    @IBAction func addApplePayButtonTapped(_ sender: Any) {
        applePaySettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        Primer.shared.configure(settings: applePaySettings)
        Primer.shared.showPaymentMethod(.applePay, withIntent: .checkout, on: self)
    }
    
    @IBAction func openVaultButtonTapped(_ sender: Any) {
        Primer.shared.configure(settings: generalSettings)
        Primer.shared.showVaultManager(on: self)
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        Primer.shared.configure(settings: generalSettings)
        Primer.shared.showUniversalCheckout(on: self)
    }
    
    func requestClientSession(requestBody: ClientSessionRequestBody, completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/clientSession") else {
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
    
    func requestClientSessionWithActions(_ actions: [PrimerSDK.ClientSession.Action], completion: @escaping (String?, Error?) -> Void) {
        guard let clientToken = clientToken else {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        guard let url = URL(string: "\(endpoint)/actions") else {
            return completion(nil, NetworkError.missingParams)
        }
        
        var merchantActions: [ClientSession.Action] = []
        for action in actions {
            if action.type == "SET_SURCHARGE_FEE" {
                let newAction = ClientSession.Action(
                    type: "SET_SURCHARGE_FEE",
                    params: [
                        "amount": 456
                    ])
                merchantActions.append(newAction)
            } else {
                merchantActions.append(action)
            }
        }
                
        var bodyData: Data!
        
        do {
            let bodyJson = ClientSessionActionsRequest(clientToken: clientToken, actions: merchantActions)
            bodyData = try JSONEncoder().encode(bodyJson)
        } catch {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        let networking = Networking()
        networking.request(
            environment: environment,
            apiVersion: nil,
            url: url,
            method: .post,
            headers: nil,
            queryParameters: nil,
            body: bodyData) { result in
                switch result {
                case .success(let data):
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                            completion(nil, NetworkError.missingParams)
                            return
                        }
                        
                        print("Client Token Response:\n\(json)")
                        
                        guard let clientToken = json["clientToken"] as? String else {
                            completion(nil, NetworkError.missingParams)
                            return
                        }

                        print("Client Token:\n\(clientToken)")
                        completion(clientToken, nil)

                    } catch {
                        completion(nil, error)
                    }
                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
    
    func createPayment(with paymentMethod: PaymentMethodToken, _ completion: @escaping ([String: Any]?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/createPayment") else {
            return completion(nil, NetworkError.missingParams)
        }
                
        let body = PaymentRequest(
            paymentMethodToken: paymentMethod.token,
            amount: nil,
            type: nil,
            currencyCode: nil,
            countryCode: nil)
        
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

// MARK: - PRIMER DELEGATE

extension MerchantCheckoutViewController: PrimerDelegate {
    
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\n")
        
        let clientSessionRequestBody = ClientSessionRequestBody(
            customerId: customerId,
            orderId: "orderId",
            currencyCode: currency,
            amount: nil,
            metadata: nil,
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
                        itemId: "itemId0",
                        description: "I'm an item",
                        amount: amount,
                        quantity: 1)
                ]),
            paymentMethod: ClientSessionRequestBody.PaymentMethod(
                vaultOnSuccess: true,
                options: [
                    "APPLE_PAY": [
                        "surcharge": [
                            "amount": 119
                        ]
                    ],
                    "PAY_NL_BANCONTACT": [
                        "surcharge": [
                            "amount": 49
                        ]
                    ],
                    "PAY_NL_IDEAL": [
                        "surcharge": [
                            "amount": 99
                        ]
                    ],
                    "PAYPAL": [
                        "surcharge": [
                            "amount": 179
                        ]
                    ],
                    "ADYEN_TWINT": [
                        "surcharge": [
                            "amount": 49
                        ]
                    ],
                    "ADYEN_GIROPAY": [
                        "surcharge": [
                            "amount": 29
                        ]
                    ],
                    "BUCKAROO_BANCONTACT": [
                        "surcharge": [
                            "amount": 19
                        ]
                    ],
                    "PAYMENT_CARD": [
                        "networks": [
                            "VISA": [
                                "surcharge": [
                                    "amount": 288
                                ]
                            ],
                            "MASTERCARD": [
                                "surcharge": [
                                    "amount": 388
                                ]
                            ]
                        ]
                    ]
                ]
            )
        )
        
        requestClientSession(requestBody: clientSessionRequestBody, completion: completion)
    }
    
    func onClientSessionActions(_ actions: [ClientSession.Action], resumeHandler: ResumeHandlerProtocol?) {
        requestClientSessionWithActions(actions) { (clientToken, err) in
            if let err = err {
                resumeHandler?.handle(error: err)
            } else if let clientToken = clientToken {
                resumeHandler?.handle(newClientToken: clientToken)
            }
        }
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nPayment Method: \(paymentMethodToken)\n")

        if paymentMethodToken.paymentInstrumentType == .paymentCard,
           let threeDSecureAuthentication = paymentMethodToken.threeDSecureAuthentication,
           threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.authSuccess {
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

        if !performPayment {
            resumeHandler.handleSuccess()
            return
        }
        
        createPayment(with: paymentMethodToken) { (res, err) in
//            resumeHandler.handle(error: NetworkError.missingParams)
//            return
            if let err = err {
                resumeHandler.handle(error: err)
            } else if let res = res {
                guard let requiredActionDic = res["requiredAction"] as? [String: Any] else {
                    resumeHandler.handleSuccess()
                    return
                }
                
                guard let id = res["id"] as? String,
                      let date = res["date"] as? String,
                      let status = res["status"] as? String,
                      let requiredActionName = requiredActionDic["name"] as? String,
                      let clientToken = requiredActionDic["clientToken"] as? String else {
                          resumeHandler.handleSuccess()
                          return
                      }
                
                self.transactionResponse = TransactionResponse(id: id, date: date, status: status, requiredAction: requiredActionDic)
                
                if requiredActionName == "3DS_AUTHENTICATION", status == "PENDING" {
                    resumeHandler.handle(newClientToken: clientToken)
                } else if requiredActionName == "USE_PRIMER_SDK", status == "PENDING" {
                    resumeHandler.handle(newClientToken: clientToken)
                } else {
                    resumeHandler.handleSuccess()
                }
                
            } else {
                assert(true)
            }
        }
    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\nToken added to vault\nToken: \(token)\n")
    }
    
    func onCheckoutDismissed() {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\nPrimer view dismissed\n")
        
        fetchPaymentMethods()
        
        if let threeDSAlert = threeDSAlert {
            present(threeDSAlert, animated: true, completion: nil)
        }
    }
    
    func checkoutFailed(with error: Error) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nError domain: \((error as NSError).domain)\nError code: \((error as NSError).code)\n\((error as NSError).localizedDescription)")
    }
    
    func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nResume payment for clientToken:\n\(clientToken)")
        
        guard let url = URL(string: "\(endpoint)/resumePayment"),
              let transactionResponse = transactionResponse else {
                  resumeHandler.handle(error: NetworkError.missingParams)
                  return
              }
        
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let bodyDic: [String: Any] = [
            "id": transactionResponse.id,
            "resumeToken": clientToken
        ]
        
        var bodyData: Data!
        
        do {
            bodyData = try JSONSerialization.data(withJSONObject: bodyDic, options: .fragmentsAllowed)
        } catch {
            resumeHandler.handle(error: NetworkError.missingParams)
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
                case .success:
                    resumeHandler.handleSuccess()

                case .failure(let err):
                    resumeHandler.handle(error: err)
                }
            }
    }
    
    func onResumeError(_ error: Error) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nError domain: \((error as NSError).domain)\nError code: \((error as NSError).code)\n\((error as NSError).localizedDescription)")
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

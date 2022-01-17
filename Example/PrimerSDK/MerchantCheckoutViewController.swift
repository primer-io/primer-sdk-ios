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
            merchantIdentifier: "merchant.dx.team",
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

        
        Primer.shared.configure(settings: generalSettings)
        Primer.shared.configure(theme: CheckoutTheme.primer)
        Primer.shared.delegate = self
        
        self.fetchPaymentMethods()
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
        Primer.shared.showPaymentMethod(.payPal, withIntent: .checkout, on: self)
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
    
    func requestClientSessionWithActions(_ actions: [PrimerSDK.ClientSession.Action], completion: @escaping (String?, Error?) -> Void) {
        guard let clientToken = clientToken else {
            completion(nil, NetworkError.missingParams)
            return
        }
        
        guard let url = URL(string: "\(endpoint)/api/client-session/actions") else {
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
            } else if action.type == "SET_BILLING_ADDRESS" {
                if let postalCode = (action.params?["postalCode"] as? String) {
                    postalCodeLabel.text = "Postal code: \(postalCode)"
                    
                    var billingAddress: [String: String] = [:]
                    
                    action.params?.forEach { entry in
                        if let value = entry.value as? String {
                            billingAddress[entry.key] = value
                        }
                    }
                    
                    let newAction = ClientSession.Action(
                        type: action.type,
                        params: [ "billingAddress": billingAddress ]
                    )
                    
                    merchantActions.append(newAction)
                }
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
    
    var paymentResponsesData: [Data] = []
    
    func createPayment(with paymentMethod: PaymentMethodToken, _ completion: @escaping ([String: Any]?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/api/payments/") else {
            return completion(nil, NetworkError.missingParams)
        }
                
        let body = Payment.Request(paymentMethodToken: paymentMethod.token)
        
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
                    
                    let paymentResponse = try? JSONDecoder().decode(Payment.Response.self, from: data)
                    if paymentResponse != nil {
                        self.paymentResponsesData.append(data)
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
            orderId: "ios_order_id",
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
                        itemId: "_item_id_0",
                        description: "Item",
                        amount: amount,
                        quantity: 1)
                ]),
            paymentMethod: ClientSessionRequestBody.PaymentMethod(
                vaultOnSuccess: true,
                options: [
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
        
        if paymentMethodToken.paymentInstrumentType == .unknown {
            // Mock QR code merchant res
            
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                let newClientToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2OTIwMjY4MzksImFjY2Vzc1Rva2VuIjoiZTkwZWRkYmQtOGYwMy00NjlmLWI3ODEtYzViOWJiOWE1OTEwIiwiYW5hbHl0aWNzVXJsIjpudWxsLCJpbnRlbnQiOiJYRkVSU19QQVlOT1dfUkVESVJFQ1RJT04iLCJzdGF0dXNVcmwiOiJodHRwOi8vbG9jYWxob3N0OjgwODUvcmVzdW1lLXRva2Vucy83ZmNjNWJlYi1kNmEzLTQyZmEtOWY1Yy02NDNlZjdkOGZiMzUiLCJxckNvZGUiOiJpVkJPUncwS0dnb0FBQUFOU1VoRVVnQUFBWVlBQUFHR0NBWUFBQUIvZ0NibEFBQUFCR2RCVFVFQUFMR1BDL3hoQlFBQUFDQmpTRkpOQUFCNkpnQUFnSVFBQVBvQUFBQ0E2QUFBZFRBQUFPcGdBQUE2bUFBQUYzQ2N1bEU4QUFBQUJtSkxSMFFBL3dEL0FQK2d2YWVUQUFBY09rbEVRVlI0MnUzZGVaUmRWWlhIOGQrcldhaUVKSVJBaG9MWURJRUlqU2kyMEV3eWlDaUNpMEZCbHdFVUdRVVJtV1ZRUkZCYWJORkdJUWl0Q1NCcE1VN2RMaGNLTFFFWkVvYUFnSVNZUUNEZ2dFQkNwa3FsVW5uOVJ6Q3dYMGpmbkp6aDNsUDEvZnlYcXZmdVBmZldxK3c2WjkremQ2MWVyOWNGQU1Ecm1zb2VBQUNnV2dnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ0R3QUFBTUFnTUFBQ2pwZXdCckk4cmF4Y2tQZDk1OWE5VjZ2b2F4OVA0K3FMdnV4NHZ0dERYVTNUOFJrWG5LK0w3ZmwrK1B5L2Y2MDE5Zk5mUGk2dXlQLzlWeEl3QkFHQVFHQUFBQm9FQkFHQmtrV05vRkhxTnpuV04wWFdOTS9TYWFOSDdZNi9SKzNLOUg3NDVpZGhyM3I3dkQ1MHppUDE1QzUwVENuMCszL3RSOXY4dlZjQ01BUUJnRUJnQUFBYUJBUUJnWkpsamFKUjZEVDMydmdIZk5kTFFhN0t4NzArUnNuTWtzYS9IOStkVE5CN2ZuRW5vMS91TzEzYzhycW8ybmhTWU1RQUFEQUlEQU1BZ01BQUFqSDZSWTBqTmQ4MDJkRzJYMFBzb1FqOFg3N3RHSHJ1V1VlZzFiOS94VnkzbkUvcno0L3I2L3JCbW54dG1EQUFBZzhBQUFEQUlEQUFBZ3h6RGVraTlqNkNSN3hwOTBmaUt6dWY2L2lLaGN3YWg3M2ZzV2tleGErZkV6bEg0WGsvcTJsWnd4NHdCQUdBUUdBQUFCb0VCQUdEMGl4eEQ3T2VjWTlmZUNmMysyTFdKZk5lQVl6OFg3enJlMkxXalV2ZVBDRjFycVZIajhVTG5iSHhWL1hnNVlNWUFBREFJREFBQWc4QUFBREN5ekRHa2ZtNDU5blAwdVgzZjlmNDBxdnI0ZktYT1ViaWV2MnIzTjNVT0puYU9yajlneGdBQU1BZ01BQUNEd0FBQU1HcjFlcjFlOWlDcUx2VWFwKy94VXAvUDlmMk5VdGZPcWRwejk2blg2SXV1Si9YMXg3NGV1R1BHQUFBd0NBd0FBSVBBQUFBd3N0ekgwQ2gxZjRHcVBlY2N1MmR4Nk9QbHRvOGd0TmcvcjlBNXB0QTl4WXRlbnpwblZuUzlBN0VITlRNR0FJQkJZQUFBR0FRR0FJQ1JSWTdCZDAzUzlYaEZyeStTZXQ5QTZ0bzR2dGRmZG44RDE4K1Q2L2w5bGQwL0l2YjFwODVaK1BhbktIdmZVaG1ZTVFBQURBSURBTUFnTUFBQWpDeHJKWVZlUXcyOXB1azYzckxyejd1cSt2aUt6dGNvZGkyZTJEa0JWN0UvRDZISGx6b25XSFlPcHdxWU1RQUFEQUlEQU1BZ01BQUFqQ3oyTVJSeFhYT3NlZy9ncXZVbjhMMmUwTmZuZWoyaG40UDNQWC9WY2hpaDl5V0VYcU9QbmNQemxVUE93QlV6QmdDQVFXQUFBQmdFQmdDQWtjVStodGhyN0kycXZtWVkrN251b3ZzUmUwMjNhdnRNVW91OUw2VHNmU1JsZjE1RDUwU3FkcjlEWU1ZQUFEQUlEQUFBZzhBQUFEQ3kyTWVRZWsyeTZQaXgxeUJkaGU3ZkVIcDh2c3J1VDFBMG5xbzlSeCs3eDNmVlB2K3U5eWYwKzBQdlM2a0NaZ3dBQUlQQUFBQXdDQXdBQUNPTEhFT1IyRDFlYzY4RkU3cjJrcS9VL1J2S1BsL3FIdGUrWXZkTUQvMzdsYnFmUXRYM2pZVEFqQUVBWUJBWUFBQUdnUUVBWUdTUll3aGRhOGYxOWI3MTlYM0ZydWZmS0hXOWV0ZnpsVjNyeC9YNmlsN3Ztdk5LM2M4ajlyNFgzMzA0b1k4ZisvK0xIREJqQUFBWUJBWUFnRUZnQUFBWVdlUVlHb1YramozMnZvVFV6MlhudHFicHUrWmJkZzlmM3pYMW92T256am1rUG4vVmhjNTU1SUFaQXdEQUlEQUFBQXdDQXdEQXlLTG5jNlBZenlXN25pOTFqaUMzSHM1RngvTlY5WHIrb2NlZit2N2xscU1MZmIvbytRd0FHUEFJREFBQWc4QUFBREN5ekRFMGlsMS9QWFp0RmRmemhiNytzdnRCdUVxOXBwdTYvbjdvOXpjcWU1OU02djRTUlZMbkJNa3hBQUN5UTJBQUFCZ0VCZ0NBa1dXT29XcTFnNnFXWS9BVmVoOUYxWElRdm1Mdkl5azdoK0lyZFU3RTlmeXhlN0tYL2Y5UkNNd1lBQUFHZ1FFQVlCQVlBQUJHRnYwWVF2ZUVMVHNuRUx1SGJ1dzF6TlQzdDJ4bDE3cHkvWHlrWG1OM0ZUcW5rcnAyV09qcnF5Sm1EQUFBZzhBQUFEQUlEQUFBSTh0OURLNWlQeWVlZTMrSUlxbmZYN1ZhUGJGeklySDdZMVM5ZGxiUjhjdnVQeEY3MzA0Vk1XTUFBQmdFQmdDQVFXQUFBQmhaN0dOb0ZIb051T3puMEdPL1B2V2FlT2g5SGFHL24zcU4xL2Q4VlZ1ekxocVA3K2V4NmozQmZUL2ZPV0RHQUFBd0NBd0FBSVBBQUFBd3NzZ3h4SzRWRS9xNVpkZlh4KzRSN1B2Y2R1d2V4S0h2VDluN05vcXVQM1RPSWZYN2ZjOFhlczAvOWI0TTMvSGxrSE5neGdBQU1BZ01BQUNEd0FBQU1MS29sWlJiYlp2UTQ0dGQ2NmJzL2dpcGUxekh2djlsS3p0SFZYUjgzL0c2aXYzenlpRm40SW9aQXdEQUlEQUFBQXdDQXdEQXlHSWZnNnZRYTVxeDE3U3IxbFBYOVhwU2p5ZjBjK1ZGeDY5Ni93SFhXa1crVXVjZ1lvKy9TT2llM3psZ3hnQUFNQWdNQUFDRHdBQUFNTExJTWFSK3pqbDA3U1BYMTZkK2J0NTNEVGgyTGFEVWE5Q2hQdzlGeHk5N1BMN2pLenFmYTMrTTFMWFBVcDh2aHh3RU13WUFnRUZnQUFBWUJBWUFnSkZGanNHM2gyL3NmUTJ1L1FGOHorLzYvdGc1ak5ocnBxR3ZMM1l0cTZMeGhiNStWNkUvdjc3WFcvYjlpWjJ6eVNHbjBJZ1pBd0RBSURBQUFBd0NBd0RBeUtJZlE2T3FQL2RmTkY3ZjQ3bXFlcitCc21zditZNXZvUGNMNlcvamkzMDlPV0RHQUFBd0NBd0FBSVBBQUFBd3N0akgwTWoxdWV2WXRZdEMxMWFxV2orQTBQZWpxSCtBNzNQMXNkZWNZL2V2aUwzR252dStEdC96VlMxSFVVWE1HQUFBQm9FQkFHQVFHQUFBUmhiN0dNcXVseDc3ZUw2dkwzcS9xN0t2SjNYT3gvVitsUDM1Y3hYNzgrQTYvdHgvSDNMY2wrQ0tHUU1Bd0NBd0FBQU1BZ01Bd01oeUg0UHZjOVNwMTF4ZHo1OTZEVHAyeitiUTErOTdQMUxYMDAvZFE5bjEvR1gzWTNDOVh0LzNsNTF6eVFFekJnQ0FRV0FBQUJnRUJnQ0FrV1dPSWZZYWUranh1Szd4cHE2VlZIYlBhZGZqcDc2KzBQZWppTy85aWwzTHFML3ZDM0x0S1Y4a3gzMFF6QmdBQUVhV013YmtiK0hTNWV2ODNrbEx2dlQvdnRiMysxWDM1dkZQN0x5MDdPRmdBR0xHQUFBd3NwZ3hoSzQvNzNyODJHdm9ydGZ2SzdkNis3Qmk5MnRJM1VNNzl1ZlI5ZnkrY3N3cE5HTEdBQUF3Q0F3QUFJUEFBQUF3c3VqSDRLcHEvUmhjaisvN2V0L3pwNmlOMC9qa0VON2FrSTA3MXZwYTdKN0pzV3NMcGU2dmtIcy9pREpra1h3RzF1WFZCUXZWdmJ4N25kOGZOblNJMmxyYjlOZVhYbHJuYXpiZmJETzF0S3orVmVqcDZkRkxMNytpSlV1VzZXMXZhOWZnUVlNMGJPZ1FTZExpSlV1MWFQR2lkUjVuVU9jZ0RSN1VXZll0QWJ3UkdKQzFiMTV6dmFiZE4zMmQzNy80N0RPMHkwN2pkZFNuVDF2bmEyNjUvdHZhcW11TVZxNWNxZU5PUFZ2ei8veG5yVnpacDZhbUpqVzN0bWkvUFhiWGVaOC9TYmYrNUJlYS9GOVQxM21jWTQ4K1VpY2MrL0d5YnduZ2pjQ0FyRTM0Mk9FNmFMKzlKVW4zUGZTb2Z2cmZ2OVlaSngrdnJwRWpKRW5qdHR0RzlYcGR2YjBydGM4ZTc5VWhCKzYzMWpHMkdENWNmWDE5T3Via0wraVo1NTdYV2FlZnFQSGJicU9GcjcybU82YmRxeWYrK0xScXRab08zSDl2N2JEdFAwbVNaczE5VmpkTW5xTFBISE8wdHQvNjdaS2tMYmZxS3Z0MkFFRU1pTUNRMno0RDEvSEgzcWRSTkI3WCt4RnlqWHo3Y2R0byszSGJTSkplWGJoNm1lYzl1K3lrYlYvL3oxcVMvdmJTM3lWSlk3dkdhSzg5ZG52TDQvejk1VmMwZDk1ek92U0Q3OWZIUG5Md21xL3Z1ZnUvcUY2dnExYXJhV3pYR0kzdEdpTkphbTFya3lUdHRNTTQ3ZmFlZHdXN25oRDNLM2JQN05pMXFsdy8zN0Y3Y29mK3ZPZVFjK0NwSkVCU3JWYVRKTTJiUDE4OVBUMXYrVDFnb0JnUU13WkFraDU4NURGZDgvMUo1bXNUampwY213d2VwR0ZEaCtxQWZmYlFIZFB1MVJISG5hS3RSby9TcnJ2c3JMMTIyMVhidkduMkFRd0VCQVlNR0hPZWZVNS8vcHQ5T3Vtd2d6K2dUUVlQVWxOVFRWKzk2Qnh0djkyMnVuL0d3M3A2empONjZOSEhkZjJrVzdUN3J1L1dKZWVkb1NHYkRDNzdFb0Frc2d3TXFkZTRZOWV2RDkxdm9HaU5OSFVQMzZyVVR2cjRFWWZxMU04Y3M4N3YxMm8xVFRqcU1FMDQ2akJKMHJ6bjUrcy9KazdTNzZjL3FEdnZ2bGRISFBMQjVHTytzblpCOHA5WDBmRmk5NkQyL2I0djN4eEgwZkZ5UUk0QldJZXhXM2Jwck5OT2tDUTk4K3o4c29jREpFTmdBQ1F0ZkcyUnpybmtDajMrNUN6ejlkblB6Sk1rYmRrMXF1d2hBc2xrdVpRRWJJZzdwOTJuWjE5NFlhMnZuM3ZhU1pyNzNQTjY0SkZIZGZkOTA3WGorSEY2eC9iajlQTExyK2pPdSsvVjRFR2QybXUzWGNzZVBwQk1Gb0VoZG0yWXNzY1RPZ2NRK2pudTJMVjBRbW52YU5mZ1FaMXFhV2syWDI5dWJ0YmdRWjFhdEdTeEhuM3N5YlhlMTd1aVY3dTlleGZkK1pPYmRNWFYzOU05OXora1orZk5WNjNXcEFQMzNWdGZQdi96YW02MngyeHRiZFhnUVoxcWIyK0xlazNuMWI5VytqNEUxL2VIN3ZGZGRQN1UxNWQ2UEdYSUlqQUE2K09nL2ZmUlFmdnZzOWJYaDI4NlRMLzkyUzJGNzIvcmFOZVh6ejlUdmIwcjFidXlWMjJ0cld0cUtEVjY5enQzV3E5akFqa2lNQUFOV2x0YjFOcktyd1lHTHBMUEFBQWp5eitMWXVjSXl1NDVHN3ZldTI5dG14RDNaK0hTNVU1anhodGlyMW5IemhHRUhrL29uRURvKzFPVmZUd3VtREVBQUF3Q0F3REFJREFBQUl3c2V6NlgzVU0yOUhpcTFvTTJSYzlmY2d6clo4akdIYVgzR0U1ZEN5aDJmNUhRdjYvOUVUTUdBSUJCWUFBQUdBUUdaR2RaZDdlNnU3czMrUDBybHZkbzhkS2xHL1RlUll1WHFMZDM1VnBmNyt2cjA0cmxQUnR3UktCNnNzd3h1UEo5anJqc1drRlY2K2xjZFA3MXNhNGN3NS9tUEtzSnA1eXBMVGJmVEwwcmVyVlYxMmlkZHNLeEdyLzlkbHF5ZEtrdSt1bzNOWHZ1WE5WcVRkcGh1MjMwcGZQTzBLRE96alh2ZitEQmgvV0ZpeTdYMUVuWGFlUVdJN1NzdTFzZlBlNVUzZmJENzZxNXFWbGZ2L282VFg5NHBqbzYyalY4NkJCZGR1SFpldXlKV1pyNGc1dTFlT2xTTGU5Wm9jMkdEZFh3VFlkcDR0VnZYTmZ6TDd5b2l5Ni9Tc3VYOTJqWjh1WGFZZHkyK3VvWHoxSjdXNXR1dlBuSG12U2oyelJpK0tZYXVjVUlmZU1yWDFSSFI0Y2thZnBETTNYMnhaZnI1N2Zjb0UySERaRWtYZkRscjZ1cHVWbGZ1ZkFzTlRjMTZjNjc3OVBNUjUvUTJaODdjYTM3TWJIelV1ZDdtM3FmajYvWU9iVWlzV3NwNVlnWkF5cWxycnBhV3BwMXkvWGYxaTkrZEtPMkhETmFWM3pyZTZyWDYvcmRQZmRyOXR5NSt0bk4zOWVVRzYvUkg1LytrNmJkTTkyK3Y3NzZyL2RiZnZ4enZmRTNUMTMxdWpSN3pqeE51L2NCVGI3MjN6WGx4bXUwYVBGUy9lTFh2OVdCKysybHFUZE4xRm1ubjZSMzdyaURwdDQwMFFRRlNmclZiMzZucHFZbTNYcmpOWm82NlRydHYrZS9xcldsVmZPZW42K2JwdnhVdjV6eW4vcko1T3MwWnRSSVRaN3kwOWZIVXRmM2I1cWlWZlc2Zm4vL2pEY09WcFB1ZnVCQnZmRGlYOTQwN243Lzl4a3lRbUJBWmJXME5PdVU0eWZvcjMvN3V4WXZXYXE3N25sQTU1eDJzdHJiMmpTb2MyTWQvdUdETkd2TzNMWGUxelZxcE82WWRvLys4T1JUNXVzelpqNm1Jdy85a0ladk9reHRyYTA2ODlSUDY4bW5acS9YV0xxWDkyanp6WWFydWFsSjdXMXRPdWlBZmRUVVZOUGpUejZ0N2JZZXEwMEdyWjYxbkgzNmlUcittS01sU1MvKzVhK2FNL2M1SFhYWWgvWEFRelBOOGQ2NzZ5NDY3ZHhMMU5mWFYvWnRCdFpDWUVDbHRiUTBxNjJ0UlQzTGU3Unc4U0p0Tm56WW11LzlZNm1vVVd0N200Nzh5TUdhT09sVzgvVkZpeFpyeElqaGEvNjl4ZVlqdEd6WnN2VWF4NEh2MjFPUFB6bExKNTF4dmk2OTh0dWFOWHVPSkdscGQ3ZmEyOXRWcTlVa3JTN3gzZHkwK3RmcTRabVBhL1RvTFhUTTBVZHE1dU5QYWtWdjc1cmpIWExBdmxyVjE2ZmI3NWhXOWkwRzFwSkZyU1RmTlcvZmZnTkZ4L2NkZjlYcTY3dU9ML2FhYTcwdTFacHFxalhWdEtxK2FzM1hWL1d0a2w3L0Qvbk5tbFRUY1o4NFV0TStPMTEzM1gzL0cxOXZxbW5WcWpmK1F1L3I2MU5UYmYzK050cHgvRGpkTnVsYXpYamtEM3J3NGNkMHlsa1hhK3JrYTFWcnFxbGVyNnRlcjY4SkR2OXcxNzBQYU44OWR0T3JDMTdWcUpHYjYvWTdwdW1RRHg0Z1NlcnMzRWhYWEhLdXZuYjF0ZnJFNFlkNjNaL1UvVGVLVkswbmMrejcweDh4WTBDbExWbThUTjNkUGVyY2VHTjFqUnFwcDJhdlhqcXExK3Q2WXRac2JUcDB5RnUrcjZXbFJhZWZlS3d1dStvN2VtM1JZa25TcUpHYjY2blpjOWVzNS85eDFod05YY2Y3RzYzbzdWVkhSNGYyM1hNM25mTzVFN1hkMW1QMTFKL21hUGl3WVZxOGRJbFd2WDdNQlF0ZjA0cmxQWHAxd1VKTmYvaFIzVHIxbHpyaGpBdjB6TFB6TlhuS1ZQV3RlaU93N2J6amVHMHpka3RkOTRPYnk3N05nSkhGakFFRHk2cStWYnBoOGhRdGZHMlJaanp5bUQ1N3dqSHE2R2pYY1ovNHFFNDY0M3pOZS80RnJWeTVVci82emYvcVJ6ZDhaNTNIMlhXWGY5WUg5dDlIdjc3akxrblMvbnZ2b1JzblQ5R2xWMTZ0SVpzTTF0UmYzYTZyTDd0b3ZjWjB3V1hmMElKWFh0WGVlKzZ1cDU2ZXJibnpudFA0Y2R0cG80NTIzZmF6LzlFNUYxK3V0NC90MHUxMzNxM0xMemxYRHo3MHFONjN4M3YxcGZQUGxDUzkvTW9ybW5EeVdWcXc0RFZ6M05OUC9KU09QUGJrc204NVlCQVlVQ21iRGh1cVQzM3lZNUtrb1VPRzZPQUQ5OVhPTzc1RGtyVGw2Rkg2dDBzdjBJeVpqNnRXcSttSDM3MUtZN3ZHbVBkM2pSbWxJejd5SVVsU1UxT1R6am45UkczVk5VWnRyVzNhZUtPTjlOMnJMdE45TTJacVdYZTN2blhaaFhyWE8zZGE4OTV0Mzc2bFB2VCsvZDV5WEJkOTRiTzY1NzRaZXVhNTU3WDEySzEwL0NlUDB0Qk5Ca3VTTHIvNFhQMzJybnYweXFzTGRQSFpwMnZuOGR2cnhSZitvdDNmOHk2MXQ2MXUvVGw2NUVpZGV2d0UxV3JTL3UvYlM2TkhqWlFrYlQ1aXVLNjY3RUt0ZXROTUFpaGJsdnNZcXBZRGNIMTk2dHBPb2ZkeCtMcXlkb0ZPV3ZLbG9NZnNyeVoyWGxyNXowdlphL0t4UDkrcDl4RlZBVGtHQUlCQllBQUFHQVFHQUlDUlpZNmhVZXpua0VPdnVSYTlQdlQ5aUcxRDdqZjlHTmJQa0kwN0NsOFRlMTlPN0g0anFmZnBoSDUvZjhncE5HTEdBQUF3Q0F3QUFJUEFBQUF3c3RqZzVsdXJKWFE5ZDljMXhOajE4VU9mUC9VYU1OYnRyWDcyUmJYQWl2Zyt0Kzk2Zk44MSt0RDdPRncvcjdGN3dsZFJGb0VCL2MrYms2cXhmM0ZTYjJBRWNzZFNFZ0RBSURBQUFJd3NsNUppMTBKeWZYL3FmUXFwZS9yR2ZuM1IrSHhmSDNwTlBmVDRmSE5pb1Q5L1ZkOVg0RHQrWHdOaDZaQVpBd0RBSURBQUFBd0NBd0RBR0pDMWtrS0xYUzgvZGorSHNtc3J1VjV2MGV2NysvaDh4KytxN0g0RVZWdlR6MkVmZ2k5bURBQUFnOEFBQURBSURBQUFJNHNjUStvMTVLTHp4MzV1UDdUUXo4Mm4za2ZpZWp6ZjYvY2RmOVZyVzdsZVgranhGUjB2OXU5VDJmdWdjc2hSTUdNQUFCZ0VCZ0NBUVdBQUFCaFoxa3BxRkxyV1VlcCtDNkd2Si9UNVE5Ky8wUFg2WGUrUDc4ODM5ajZWb3UvSDdnOFF1N1pUMWZwSHhNN1I1SkJUYU1TTUFRQmdFQmdBQUFhQkFRQmdaSmxqS0x0K2UreDlGYUY3MG9aZXczYzlmOUY0Zkk4ZnV5ZTRiNC9sMk5mdmUzeFh2amtrVjdGcmdhWHUzNUJEem9FWkF3REFJREFBQUF3Q0F3REF5S0pXVXFQVXRXdUtqaDk2L0s3bmo5MkR0K3grQXJIN0grVFdUOE5WNnZzWit2eXV5djY4Rm8ySEhBTUFJRHNFQmdDQVFXQUFBQmhaN0dPSXZVWlg5ZG9vc1o4YkQxMDdxT3ByeXFIM2hmaCtIcXJXSDZUbzlhR3YxemZuVWJUUEpIWE9xV285cWpjRU13WUFnRUZnQUFBWUJBWUFnSkZGamlGMi9mM1EvUVJjcnlkMUQrTFV6MUhIWGpPT3ZTWWMrdk1RT2tkUWRzN0I5ZnA4VmEyMldObS9YekV3WXdBQUdBUUdBSUJCWUFBQUdGbmtHR0xYQXZKZGt3MjlwaHQ2emJUbytLN1hGL3Q2Zk1VZVQrb2NUdGs5eFdQWEJrdmR3enYyejc4LzVCeVlNUUFBREFJREFNQWdNQUFBakg3Ump5SDBHbWpzZXYrdTV3OWREOS8xZW1MWFJpcTdCN1R2OFdPUHgxZnFIc2krbjQreXg1ZjY5VlhFakFFQVlCQVlBQUFHZ1FFQVlHU3hqNkZSNkRYNzFHdkVxZXZEdXg0LzlQRmM5NUc0Q3QwRHZPeDlGNkhYdEdQbk9FTHZ1L0hkSitCN3ZXWG5RS3FBR1FNQXdDQXdBQUFNQWdNQXdNZ3l4MUFrZE8yZzBPZHo1YnZtSExzbmN1Z2NRdFgyTmJoSzNRTzY2bXZncWZ0QmhCNWY3SDRwVmNTTUFRQmdFQmdBQUFhQkFRQmc5SXNjUSt5ZXZhR2ZnNjk2YlpheTYrZkg3dkZjSkhaUDc5QzFoSHo3Z3pTS25aTkpuVk9JL2Z0UWRMNnlhMlZ0Q0dZTUFBQ0R3QUFBTUFnTUFBQWp5MzRNamFxMkJsMzFISUtycXZVM0NEM2UxRDJjUTQvZlZleGFZNkUvTDZsN3FJZnVUNUlqWmd3QUFJUEFBQUF3Q0F3QUFDUExISVB2bWw3cWV1dGwxLzZKM1kraXYrVmNRbjgreXE2MUU3by9pYXVxN1ROeFBmNUF4SXdCQUdBUUdBQUFCb0VCQUdCa1VTc3BkWS9YUnFsekNyNXJ2cUhyL1ljK2Z0azVDTjlhVnFuN0pialc1Z290ZHUycklxRS8vN0Y3d3ZlSEhBVXpCZ0NBUVdBQUFCZ0VCZ0NBa2NVK2h0ajEwS3YrSEg3VjFqQkRQNWZmcUdyUDZhZmVCMUQyOWZpT3QxSHFmU2ErNHkwYWYrcDlVR1ZneGdBQU1BZ01BQUNEd0FBQU1MTFl4OUFvOUhQNG9aOERUOTJUTjNYdG03TFhWRjJ2TC9ZYXRPLzRmSzhuOUQ2ZjFMOFB2cTkzZlgvcy96L28rUXdBNkhjSURBQUFnOEFBQURDeTNNZFFkditFMkQxdWZlK1A2L0ZEWDIvczE3c3F1eCtGNi9oOHhlNlJuTHBmUk9qcjk3MGZSZTluSHdNQW9OOGhNQUFBREFJREFNRElZaDlEMVo3YkRyMkc2N3NtR251Tk5IWU9wZXlleUw3ajhiMGZzWitEcjNydHNDS3Bjd1psWDI4Vk1HTUFBQmdFQmdDQVFXQUFBQmhaN0dObzVGc3JLTGY2K2JIdlYranJheFQ2T2YrcTFkNEpmVDVmVmV2WFVIVDhJcWwvdnI3ajZRK1lNUUFBREFJREFNQWdNQUFBakN6Mk1iaHlYZE11dTRkeDZCeEY2SnhBMVhJS1JVTDN0d2o5L3RpMWQ2cFd1OG4xZktIMzBUVEtyUWQ0R1pneEFBQU1BZ01Bd0NBd0FBQ01MUGN4dUNwN0RkaFY2UHJ1cWZzbnhONVhVbmEvaHR5dU4zYnRxYkwzSmFUdVA1RmJEbWRETUdNQUFCZ0VCZ0NBUVdBQUFCaFo1aGhpMTZjdnV4Nis2L0dLN2svWmE5eXg3NGZyL1NtNnZ0aHI2cUd2MS9mNlhhK3Y3T2YyWTkrL0l1UVlBQUFERG9FQkFHQVFHQUFBUnBZNWh0U3F0c2FldXI1KzJlOHZPbDZSMFBYNXExWmJwK3cxL3R4cWFlWCsrVStCR1FNQXdDQXdBQUFNQWdNQXdNaWlIMFBxNTVhTDFnQlQ5NGoyUFY3VjNoOTd6VFgwUHBYVXRYMUMzNit5OTYyNEhyL3EvUmw4KzJQa2dCa0RBTUFnTUFBQURBSURBTURJSXNmUUtQU2FYZXpuMW4yUFYvWnozNjdIOXgxUDdCeE82UHNUKytjWit2TVh1MWFYNy9WV3JUOUU3UGRYRVRNR0FJQkJZQUFBR0FRR0FJQ1JSYTJrMkQxWFl6K0hIN3Zuc3EvWS9TaUtwRDVmYW1YdkcvQWRuK3Q0WS85K2xkMlRQZlQxVmhFekJnQ0FRV0FBQUJnRUJnQ0FrZVUraHRSODF3eGRhNytFcmhVVCtqbHlYNzc3Q3FwZS85OTEvS2xyUzVXOWo2SHE0eW1TT2dkWUJtWU1BQUNEd0FBQU1BZ01BQUNESE1NR0tMdit2dThhWit3MWM5Y2NSdWljZzYvWS9URkM5MWVJUFg1WG9YTXNybUxmLzdMUGx3SXpCZ0NBUVdBQUFCZ0VCZ0NBMFM5eURMSFg3R0xYUWdwOS9OQjgxMUJqNzV1SVhldXA3UDRKVmJ1ZTBEOVAzNXlUNi9GRHY5NzNlcXFJR1FNQXdDQXdBQUFNQWdNQXdNZ3l4MUIyL2ZwR3ZyV1FpcTR2OXZHTHJzZjErbjJQbHpybmtIb2ZTdEg5S2Z2ekhYdGZTT3J4eDk0WFZQYlBLd1ptREFBQWc4QUFBREFJREFBQUk0dWV6d0NBZEpneEFBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd0NBd0FBQU1BZ01Bd1BnL05TaUZJK0cyQ3k4QUFBQUFTVVZPUks1Q1lJST0ifQ.8pUMHXcnoSC8XdtWVMEsXdtqpn6LaCZTUrfz9WmZ24A"
                
                resumeHandler.handle(newClientToken: newClientToken)
            }
        } else {
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
        
        DispatchQueue.main.async {
            if !self.paymentResponsesData.isEmpty {
                let rvc = ResultViewController.instantiate(data: self.paymentResponsesData)
                self.navigationController?.pushViewController(rvc, animated: true)
            }
        }
    }
    
    func checkoutFailed(with error: Error) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nError domain: \((error as NSError).domain)\nError code: \((error as NSError).code)\n\((error as NSError).localizedDescription)")
    }
    
    func onResumeSuccess(_ clientToken: String, resumeHandler: ResumeHandlerProtocol) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nResume payment for clientToken:\n\(clientToken)")
        
        if clientToken == "qr_code_resume_token" {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                resumeHandler.handleSuccess()
            }
            return
        }
        
        guard let transactionResponse = transactionResponse,
              let url = URL(string: "\(endpoint)/api/payments/\(transactionResponse.id)/resume")
        else {
            resumeHandler.handle(error: NetworkError.missingParams)
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyDic: [String: Any] = [
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
                case .success(let data):
                    let paymentResponse = try? JSONDecoder().decode(Payment.Response.self, from: data)
                    if paymentResponse != nil {
                        self.paymentResponsesData.append(data)
                    }
                    
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

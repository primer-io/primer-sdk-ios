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
    
    class func instantiate(environment: Environment, customerId: String?, amount: Int?, performPayment: Bool) -> MerchantCheckoutViewController {
        let mvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantCheckoutViewController") as! MerchantCheckoutViewController
        mvc.environment = environment
        mvc.customerId = customerId
        mvc.amount = amount ?? 4
        mvc.performPayment = performPayment
        return mvc
    }
    
    @IBOutlet weak var tableView: UITableView!
    var environment: Environment = .sandbox
    fileprivate var customerId: String?
    var currency: Currency = .EUR
    fileprivate var performPayment: Bool = false
    
    var paymentMethodsDataSource: [PaymentMethodToken] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    var amount = 4
    
    let vaultApayaSettings = PrimerSettings(
        currency: .GBP,
        hasDisabledSuccessScreen: true,
        isInitialLoadingHidden: true
    )
    
    var vaultPayPalSettings: PrimerSettings!
    var vaultKlarnaSettings: PrimerSettings!
    var applePaySettings: PrimerSettings!
    var generalSettings: PrimerSettings! {
        didSet {
            
        }
    }
    var threeDSAlert: UIAlertController?
    
    var transactionResponse: TransactionResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        generalSettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            customerId: customerId,
            amount: amount,        // Please don't change on develop (used for UI testing)
            currency: currency,     // Please don't change on develop (used for UI testing)
            countryCode: .se,
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: nil,
            urlScheme: "primer",
            urlSchemeIdentifier: "primer",
            isFullScreenOnly: false,
            hasDisabledSuccessScreen: false,
            businessDetails: nil,
            directDebitHasNoAmount: false,
            orderItems: [
                try! OrderItem(name: "Shoes", unitAmount: 1, quantity: 2, isPending: false),
                try! OrderItem(name: "Shoes", unitAmount: 2, quantity: 1, isPending: false),
                try! OrderItem(name: "Shoes", unitAmount: nil, quantity: 3, isPending: true)
            ],
            isInitialLoadingHidden: false,
            is3DSOnVaultingEnabled: true,
            billingAddress: Address(addressLine1: "Line 1", addressLine2: "Line 2", city: "City", state: "State", countryCode: "SE", postalCode: "15236"),
            orderId: "order id",
            userDetails: UserDetails(
                firstName: "Evans",
                lastName: "Pie",
                email: "evans@primer.io",
                addressLine1: "Line 1",
                addressLine2: "Line 2",
                city: "City",
                postalCode: "15236",
                countryCode: "SE",
                homePhone: nil,
                mobilePhone: nil,
                workPhone: nil),
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )
        
        vaultPayPalSettings = PrimerSettings(
            customerId: customerId,
            currency: currency,
            countryCode: .se,
            urlScheme: "primer",
            urlSchemeIdentifier: "primer",
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: false
        )
        
        vaultKlarnaSettings = PrimerSettings(
            customerId: customerId,
            klarnaSessionType: .recurringPayment,
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        applePaySettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            customerId: customerId,
            currency: currency,
            countryCode: .se,
            hasDisabledSuccessScreen: true,
            businessDetails: BusinessDetails(
                name: "My Business",
                address: Address(
                    addressLine1: "107 Rue",
                    addressLine2: nil,
                    city: "Paris",
                    state: nil,
                    countryCode: "FR",
                    postalCode: "75001"
                )
            ),
            orderItems: [
                try! OrderItem(name: "Shoes", unitAmount: 1, quantity: 2, isPending: false),
                try! OrderItem(name: "Shoes", unitAmount: 2, quantity: 1, isPending: false),
                try! OrderItem(name: "Shoes", unitAmount: nil, quantity: 3, isPending: true)
            ],
            isInitialLoadingHidden: true
        )
        
        Primer.shared.delegate = self
        self.configurePrimer()
        self.fetchPaymentMethods()
    }
    
    func configurePrimer() {
        Primer.shared.configure(settings: generalSettings)
        
        let theme = generatePrimerTheme()
        Primer.shared.configure(theme: theme)
        
        Primer.shared.setDirectDebitDetails(
            firstName: "John",
            lastName: "Doe",
            email: "test@mail.com",
            iban: "FR1420041010050500013M02606",
            address: Address(
                addressLine1: "1 Rue",
                addressLine2: "",
                city: "Paris",
                state: "",
                countryCode: "FR",
                postalCode: "75001"
            )
        )
    }
    
    // MARK: - ACTIONS
    
    @IBAction func addApayaButtonTapped(_ sender: Any) {
        Primer.shared.configure(settings: vaultApayaSettings)
        Primer.shared.showCheckout(self, flow: .addApayaToVault)
    }
    
    @IBAction func addCardButtonTapped(_ sender: Any) {
        Primer.shared.showCheckout(self, flow: .addCardToVault)
    }
    
    @IBAction func addPayPalButtonTapped(_ sender: Any) {
        Primer.shared.configure(settings: vaultPayPalSettings)
        Primer.shared.showCheckout(self, flow: .addPayPalToVault)
    }
    
    @IBAction func addKlarnaButtonTapped(_ sender: Any) {
        Primer.shared.configure(settings: vaultKlarnaSettings)
        Primer.shared.showCheckout(self, flow: .addKlarnaToVault)
    }
    
    @IBAction func addDirectDebitButtonTapped(_ sender: Any) {
        Primer.shared.showCheckout(self, flow: .addDirectDebitToVault)
    }
    
    @IBAction func addApplePayButtonTapped(_ sender: Any) {
        Primer.shared.configure(settings: applePaySettings)
        Primer.shared.showCheckout(self, flow: .checkoutWithApplePay)
    }
    
    @IBAction func openVaultButtonTapped(_ sender: Any) {
        Primer.shared.configure(settings: generalSettings)
        Primer.shared.showCheckout(self, flow: .defaultWithVault)
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        Primer.shared.configure(settings: generalSettings)
        Primer.shared.showCheckout(self, flow: .default)
    }
    
}

// MARK: - PRIMER DELEGATE

extension MerchantCheckoutViewController: PrimerDelegate {
    
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/clientToken") else {
            return completion(nil, NetworkError.missingParams)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateClientTokenRequest(customerId: customerId, customerCountryCode: "SE", environment: environment)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(nil, NetworkError.missingParams)
        }
        
        callApi(request, completion: { result in
            switch result {
            case .success(let data):
                do {
                    let token = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: String])["clientToken"]!
                    print("Primer token:\n\(token)")
                    completion(token, nil)
                    
                } catch {
                    completion(nil, error)
                }
            case .failure(let err):
                completion(nil, err)
            }
        })
    }
    
//    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
//        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nPayment Method: \(paymentMethodToken)\n")
//
//        guard let token = paymentMethodToken.token else {
//            completion(NetworkError.missingParams)
//            return
//        }
//
//        if let threeDSecureAuthentication = paymentMethodToken.threeDSecureAuthentication,
//           threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.authSuccess {
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
//        if !performPayment {
//            completion(nil)
//            return
//        }
//
//        guard let url = URL(string: "\(endpoint)/payments") else {
//            completion(NetworkError.missingParams)
//            return
//        }
//
//        let type = paymentMethodToken.paymentInstrumentType
//
//        var request = URLRequest(url: url)
//
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body = PaymentRequest(environment: environment, paymentMethod: token, amount: amount, type: type.rawValue, currencyCode: currency.rawValue)
//
//        do {
//            request.httpBody = try JSONEncoder().encode(body)
//        } catch {
//            completion(NetworkError.missingParams)
//            return
//        }
//
//        callApi(request) { (result) in
//            switch result {
//            case .success(let data):
//                completion(nil)
//
//            case .failure(let err):
//                completion(err)
//            }
//        }
//    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, resumeHandler: ResumeHandlerProtocol?) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nPayment Method: \(paymentMethodToken)\n")
        
        guard let token = paymentMethodToken.token else {
            resumeHandler?.handle(error: NetworkError.missingParams)
            return
        }

        if let threeDSecureAuthentication = paymentMethodToken.threeDSecureAuthentication,
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
            resumeHandler?.handleSuccess()
            return
        }

        guard let url = URL(string: "\(endpoint)/payments") else {
            resumeHandler?.handle(error: NetworkError.missingParams)
            return
        }

        let type = paymentMethodToken.paymentInstrumentType

        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PaymentRequest(environment: environment, paymentMethod: token, amount: amount, type: type.rawValue, currencyCode: currency.rawValue)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            resumeHandler?.handle(error: NetworkError.missingParams)
            return
        }

        callApi(request) { (result) in
            switch result {
            case .success(let data):
//                var paymentResponse: PaymentResponse?

                if let dic = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    if let amount = dic?["amount"] as? Int,
                       let id = dic?["id"] as? String,
                       let date = dic?["date"] as? String,
                       let status = dic?["status"] as? String {

                        if let requiredActionDic = dic?["requiredAction"] as? [String: Any] {
                            self.transactionResponse = TransactionResponse(id: id, date: date, status: status, requiredAction: requiredActionDic)
                            
                            if let requiredActionName = requiredActionDic["name"] as? String,
                               let clientToken = requiredActionDic["clientToken"] as? String {

                                if requiredActionName == "3DS_AUTHENTICATION", status == "PENDING" {
                                    resumeHandler?.handle(newClientToken: clientToken)
                                    return
                                }
                            }
                        }
                    }
                }

                resumeHandler?.handleSuccess()

            case .failure(let err):
                resumeHandler?.handle(error: err)
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
        guard let url = URL(string: "\(endpoint)/resume"),
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

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyDic, options: .fragmentsAllowed)
        } catch {
            resumeHandler.handle(error: NetworkError.missingParams)
            return
        }

        callApi(request) { (result) in
            switch result {
            case .success(let data):
                resumeHandler.handleSuccess()

            case .failure(let err):
                resumeHandler.handle(error: err)
            }
        }
    }
    
    func onResumeError(_ error: Error, resumeHandler: ResumeHandlerProtocol) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nError domain: \((error as NSError).domain)\nError code: \((error as NSError).code)\n\((error as NSError).localizedDescription)")
        resumeHandler.handle(error: NSError(domain: "merchant", code: 100, userInfo: [NSLocalizedDescriptionKey: "Bla bla bla"]))
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
        default:
            cell.configure(title: "", image: nil)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentPrimerOptions(indexPath.row)
    }
    
}

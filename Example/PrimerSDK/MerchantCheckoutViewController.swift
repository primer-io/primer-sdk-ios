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
        mvc.amount = amount ?? 1
        mvc.performPayment = performPayment
        return mvc
    }

    @IBOutlet weak var tableView: UITableView!
    fileprivate var environment: Environment = .sandbox
    fileprivate var customerId: String?
    var amount: Int = 1
    fileprivate var performPayment: Bool = false
    
    var paymentMethodsDataSource: [PaymentMethodToken] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
//    let endpoint = "http://localhost:8020"

    
    
    var vaultPayPalSettings: PrimerSettings!
    var vaultKlarnaSettings: PrimerSettings!
    var applePaySettings: PrimerSettings!
    var generalSettings: PrimerSettings!
    var threeDSAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        generalSettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            customerId: customerId,
            amount: amount,        // Please don't change on develop (used for UI testing)
            currency: .EUR,     // Please don't change on develop (used for UI testing)
            countryCode: .fr,
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: nil,
            urlScheme: "primer",
            urlSchemeIdentifier: "primer",
            isFullScreenOnly: false,
            hasDisabledSuccessScreen: false,
            businessDetails: nil,
            directDebitHasNoAmount: false,
            orderItems: [],
            isInitialLoadingHidden: false,
            is3DSEnabled: true,
            billingAddress: Address(addressLine1: "Line 1", addressLine2: "Line 2", city: "City", state: "State", countryCode: "GR", postalCode: "15236"),
            orderId: "order id",
            userDetails: UserDetails(
                firstName: "Evans",
                lastName: "Pie",
                email: "evans@primer.io",
                addressLine1: "Line 1",
                addressLine2: "Line 2",
                city: "City",
                postalCode: "15236",
                countryCode: "GR",
                homePhone: nil,
                mobilePhone: nil,
                workPhone: nil),
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )
        
        vaultPayPalSettings = PrimerSettings(
            customerId: customerId,
            currency: .GBP,
            countryCode: .gb,
            urlScheme: "primer",
            urlSchemeIdentifier: "primer"
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
            currency: .EUR,
            countryCode: .fr,
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
            ]
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
        Primer.shared.showCheckout(self, flow: .defaultWithVault)
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
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
        
        let body = CreateClientTokenRequest(customerId: customerId, customerCountryCode: nil, environment: environment)
        
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
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\nToken added to vault\nToken: \(token)\n")
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        guard let token = paymentMethodToken.token else { return completion(NetworkError.missingParams) }
        
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
            completion(nil)
            return
        }

        guard let url = URL(string: "\(endpoint)/transaction") else {
            return completion(NetworkError.missingParams)
        }

        let type = paymentMethodToken.paymentInstrumentType

        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthorizationRequest(paymentMethod: token, amount: amount, type: type.rawValue, capture: true, currencyCode: "GBP")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(NetworkError.missingParams)
        }
        
        callApi(request) { (result) in
            switch result {
            case .success:
                completion(nil)
            case .failure(let err):
                completion(err)
            }
        }
    }
    
    func onCheckoutDismissed() {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\nPrimer view dismissed\n")
        fetchPaymentMethods()
        
        if let threeDSAlert = threeDSAlert {
            present(threeDSAlert, animated: true, completion: nil)
        }
    }
    
    func checkoutFailed(with error: Error) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\nError domain: \((error as NSError).domain)\nError code: \((error as NSError).code)")
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

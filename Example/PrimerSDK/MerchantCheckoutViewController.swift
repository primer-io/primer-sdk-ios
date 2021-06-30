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

    @IBOutlet weak var tableView: UITableView!
    var paymentMethodsDataSource: [PaymentMethodToken] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
//    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    let endpoint = "http://localhost:8020"

    let amount = 200
    
    let vaultPayPalSettings = PrimerSettings(
        currency: .GBP,
        countryCode: .gb,
        urlScheme: "primer://",
        urlSchemeIdentifier: "primer"
    )
    
    let vaultKlarnaSettings = PrimerSettings(
        klarnaSessionType: .recurringPayment,
        hasDisabledSuccessScreen: true,
        isInitialLoadingHidden: true
    )
    
    let applePaySettings = PrimerSettings(
        merchantIdentifier: "merchant.primer.dev.evangelos",
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
            try! OrderItem(name: "Shoes", unitAmount: 1, quantity: 3, isPending: false),
            try! OrderItem(name: "Shoes", unitAmount: 2, quantity: 1, isPending: false),
            try! OrderItem(name: "Shoes", unitAmount: nil, quantity: 10, isPending: true)
        ]
    )

    let generalSettings = PrimerSettings(
        merchantIdentifier: "merchant.checkout.team",
        customerId: "my-customer",
        amount: 100,
        currency: .EUR,
        countryCode: .fr,
        klarnaSessionType: .recurringPayment,
        klarnaPaymentDescription: nil,
        urlScheme: "primer.io://",
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
            workPhone: nil)
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer"
        
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
    
    func clientTokenCallback(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(endpoint)/clientToken") else {
            return completion(.failure(NetworkError.missingParams))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateClientTokenRequest(customerId: "customer123", customerCountryCode: nil)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(.failure(NetworkError.missingParams))
        }
        
        callApi(request, completion: { result in
            switch result {
            case .success(let data):
                do {
                    let token = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: String])["clientToken"]!
                    print("🚀🚀🚀 token:", token)
                    completion(.success(token))

                } catch {
                    completion(.failure(NetworkError.serializationError))
                    
                }
            case .failure(let err): completion(.failure(err))
            }
        })
    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        print("Token added: \(token)")
    }
    
    func authorizePayment(_ result: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
//        guard let token = result.token else { return completion(NetworkError.missingParams) }
//
//        guard let url = URL(string: "\(endpoint)/transaction") else {
//            return completion(NetworkError.missingParams)
//        }
//
//        let type = result.paymentInstrumentType
//
//        var request = URLRequest(url: url)
//
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body = AuthorizationRequest(paymentMethod: token, amount: amount, type: type.rawValue, capture: true, currencyCode: "GBP")
//        
//        do {
//            request.httpBody = try JSONEncoder().encode(body)
//        } catch {
//            return completion(NetworkError.missingParams)
//        }
//        
//        callApi(request) { (result) in
//            switch result {
//            case .success:
//                completion(nil)
//            case .failure(let err):
//                completion(err)
//            }
//        }
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        guard let token = paymentMethodToken.token else { return completion(NetworkError.missingParams) }

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
        fetchPaymentMethods()
    }
    
    func checkoutFailed(with error: Error) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\nError: \(error as NSError)")
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

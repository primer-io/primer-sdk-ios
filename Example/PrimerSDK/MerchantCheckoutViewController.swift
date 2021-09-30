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
    let endpoint = "http://localhost:8080"
    
    var vaultApayaSettings: PrimerSettings!
    var vaultPayPalSettings: PrimerSettings!
    var vaultKlarnaSettings: PrimerSettings!
    var applePaySettings: PrimerSettings!
    var generalSettings: PrimerSettings!
    
    var amount = 200
    var currency: Currency = .EUR
    var environment = Environment.staging
    var customerId: String?
    var phoneNumber: String?
    var countryCode: CountryCode = .gb
    
    class func instantiate(environment: Environment, customerId: String?, phoneNumber: String?, countryCode: CountryCode?, currency: Currency?, amount: Int?) -> MerchantCheckoutViewController {
        let mcvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantCheckoutViewController") as! MerchantCheckoutViewController
        mcvc.environment = environment
        mcvc.customerId = customerId
        mcvc.phoneNumber = phoneNumber
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer"
        
        generalSettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            customerId: customerId,
            amount: amount,        // Please don't change on develop (used for UI testing)
            currency: currency,     // Please don't change on develop (used for UI testing)
            countryCode: countryCode,
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
            customer: PrimerSDK.Customer(mobileNumber: phoneNumber)
        )
        
        vaultApayaSettings = PrimerSettings(
            currency: currency,
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true,
            customer: PrimerSDK.Customer(mobileNumber: self.phoneNumber)
        )
        
        vaultPayPalSettings = PrimerSettings(
            currency: currency,
            countryCode: countryCode,
            urlScheme: "primer",
            urlSchemeIdentifier: "primer"
        )
        
        vaultKlarnaSettings = PrimerSettings(
            klarnaSessionType: .recurringPayment,
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        
        applePaySettings = PrimerSettings(
            merchantIdentifier: "merchant.checkout.team",
            currency: currency,
            countryCode: countryCode,
            businessDetails: BusinessDetails(
                name: "My Business",
                address: PrimerSDK.Address(
                    addressLine1: "107 Rue",
                    addressLine2: nil,
                    city: "Paris",
                    postalCode: "75001",
                    state: nil,
                    countryCode: .fr
                )
            ),
            orderItems: [
                try! OrderItem(name: "Shoes", unitAmount: 1, quantity: 3, isPending: false),
                try! OrderItem(name: "Shoes", unitAmount: 2, quantity: 1, isPending: false),
                try! OrderItem(name: "Shoes", unitAmount: nil, quantity: 10, isPending: true)
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
            address: PrimerSDK.Address(
                addressLine1: "1 Rue",
                addressLine2: "",
                city: "Paris",
                postalCode: "75001",
                state: "",
                countryCode: .fr
            )
        )
    }

    // MARK: - ACTIONS
    
    @IBAction func addApayaButtonTapped(_ sender: Any) {
        Primer.shared.configure(settings: vaultApayaSettings)
        Primer.shared.showPaymentMethod(.apaya, withIntent: .vault, on: self)
    }
    
    @IBAction func addCardButtonTapped(_ sender: Any) {
//        Primer.shared.showCheckout(self, flow: .addCardToVault)
        Primer.shared.configure(settings: generalSettings)
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
//        Primer.shared.showCheckout(self, flow: .defaultWithVault)
        Primer.shared.showVaultManager(on: self)
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        Primer.shared.configure(settings: generalSettings)
//        Primer.shared.showCheckout(self, flow: .default)
        Primer.shared.showUniversalCheckout(on: self)
    }
    
}

// MARK: - PRIMER DELEGATE

extension MerchantCheckoutViewController: PrimerDelegate {
    
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/client-session") else {
            return completion(nil, NetworkError.missingParams)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateClientTokenRequest(
            orderId: "order_id",
            amount: 123,
            currencyCode: "EUR",
            customerId: "customer_id",
            metadata: [
                "test": "test"
            ],
            customer: Customer(
                emailAddress: "email@primer.io",
                billingAddress: Address(
                    addressLine1: "Lemesou 10",
                    addressLine2: nil,
                    city: "Athens",
                    countryCode: "GR",
                    postalCode: "15236",
                    firstName: "Evangelos",
                    lastName: "Pittas",
                    state: nil),
                shippingAddress: Address(
                    addressLine1: "Lemesou 10",
                    addressLine2: nil,
                    city: "Athens",
                    countryCode: "GR",
                    postalCode: "15236",
                    firstName: "Evangelos",
                    lastName: "Pittas",
                    state: nil),
                mobileNumber: "+447888888888"),
            order: Order(
                countryCode: "FR",
                fees: Fees(
                    amount: 11,
                    description: "Extra fees"),
                lineItems: [
                    LineItem(
                        itemId: "item_id_1",
                        description: "item description",
                        amount: 10,
                        discountAmount: 0,
                        quantity: 1,
                        taxAmount: 0,
                        taxCode: nil)
                ],
                shipping: Shipping(amount: 5)),
            paymentMethod: PaymentMethod(vaultOnSuccess: true))
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(nil, NetworkError.missingParams)
        }
        
        callApi(request, completion: { result in
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
        })
    }
    
    func tokenAddedToVault(_ token: PaymentMethodToken) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nToken: \(token)\n")
        print("")
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken, _ completion: @escaping (Error?) -> Void) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nToken: \(paymentMethodToken)\n")
        let token = paymentMethodToken.token

        guard let url = URL(string: "\(endpoint)/transaction") else {
            return completion(NetworkError.missingParams)
        }

        let type = paymentMethodToken.paymentInstrumentType

        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthorizationRequest(paymentMethod: token, amount: amount, type: type.rawValue, currencyCode: "GBP")
        
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
    }
    
    func checkoutFailed(with error: Error) {
        print("MERCHANT CHECKOUT VIEW CONTROLLER\nError domain: \((error as NSError).domain)\nError code: \((error as NSError).code)\n\(error.localizedDescription)")
        print("")
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

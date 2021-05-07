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
    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    let amount = 200
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer"
        
        Primer.shared.delegate = self
        configurePrimer()
//        fetchPaymentMethods()
    }
    
    func configurePrimer() {
        let settings = PrimerSettings(
            currency: .SEK,
            countryCode: .se,
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: "Scooter Rental",
            hasDisabledSuccessScreen: true,
            isInitialLoadingHidden: true
        )
        Primer.shared.configure(settings: settings)
        
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
    
    @IBAction func addKlarnaButtonTapped(_ sender: Any) {
        Primer.shared.showCheckout(self, flow: .addKlarnaToVault)
    }
    
    @IBAction func addDirectDebitButtonTapped(_ sender: Any) {
        Primer.shared.showCheckout(self, flow: .addDirectDebitToVault)
    }
    
    @IBAction func openWalletButtonTapped(_ sender: Any) {
        Primer.shared.showCheckout(self, flow: .defaultWithVault)
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
        
        let body = CreateClientTokenRequest(customerId: "customer123")
        
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
        guard let token = result.token else { return completion(NetworkError.missingParams) }

        guard let url = URL(string: "\(endpoint)/transaction") else {
            return completion(NetworkError.missingParams)
        }

        let type = result.paymentInstrumentType

        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthorizationRequest(paymentMethod: token, amount: amount, type: type.rawValue, capture: true, currencyCode: "GBP")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return completion(NetworkError.missingParams)
        }

        completion(nil)
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

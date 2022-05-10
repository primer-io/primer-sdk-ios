//
//  MerchantCheckoutViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class ManualPaymentMerchantCheckoutViewController: UIViewController {
    
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
    override var endpoint: String {
        get {
            if environment == .local {
                return "https://primer-mock-back-end.herokuapp.com"
            } else {
                return "https://us-central1-primerdemo-8741b.cloudfunctions.net"
            }
        }
    }
    
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
    var checkoutData: PrimerCheckoutData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        generalSettings = PrimerSettings(
            merchantIdentifier: "merchant.dx.team",
            klarnaSessionType: .recurringPayment,
            klarnaPaymentDescription: nil,
            urlScheme: "merchant://",
            urlSchemeIdentifier: "merchant",
            isFullScreenOnly: false,
            hasDisabledSuccessScreen: false,
            paymentHandling: .manual,
            directDebitHasNoAmount: false,
            isInitialLoadingHidden: false,
            is3DSOnVaultingEnabled: true,
            debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
        )
        
        let configuration = PrimerConfiguration(settings: generalSettings)
        Primer.shared.configure(configuration: configuration, delegate: self)
    }
    
    // MARK: - ACTIONS
    
    @IBAction func openVaultButtonTapped(_ sender: Any) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\n")
                
        let networking = Networking()
        let clientSessionRequestBody = networking.clientSessionRequestBodyWithCurrency(customerId, phoneNumber: phoneNumber, countryCode: countryCode, currency: currency, amount: amount)
        networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
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
                Primer.shared.showVaultManager(clientToken: clientToken, completion: nil)
            }
        }
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\n")
        
        let networking = Networking()
        let clientSessionRequestBody = networking.clientSessionRequestBodyWithCurrency(customerId, phoneNumber: phoneNumber, countryCode: countryCode, currency: currency, amount: amount)
        networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
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
                Primer.shared.showUniversalCheckout(clientToken: clientToken)
            }
        }
    }
}

// MARK: - PRIMER DELEGATE

extension ManualPaymentMerchantCheckoutViewController: PrimerDelegate {
    
    // Required
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nPayment Success: \(data)\n")
        self.checkoutData = data
    }
    
    // Optional
    
    func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nData: \(data)")
        decisionHandler(.continuePaymentCreation())
    }
    
    func primerDidDismiss() {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\nPrimer view dismissed\n")
        
        DispatchQueue.main.async { [weak self] in
            self?.fetchPaymentMethodsForCustomerId(self?.customerId)
            
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
    
    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\nError: \(error)")
        let message = "Merchant App | ERROR"
        decisionHandler(.fail(withErrorMessage: message))
    }
}

// MARK: - TABLE VIEW DATA SOURCE & DELEGATE

extension ManualPaymentMerchantCheckoutViewController: UITableViewDataSource, UITableViewDelegate {
    
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

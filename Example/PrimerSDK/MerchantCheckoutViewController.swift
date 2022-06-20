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
    
    @IBOutlet weak var postalCodeLabel: UILabel!
    
    var clientToken: String?
    var amount = 200
    var currency: Currency = .EUR
    var customerId: String!
    var phoneNumber: String?
    var countryCode: CountryCode = .gb
    var threeDSAlert: UIAlertController?
    var performPayment: Bool = false
    
    var checkoutData: PrimerCheckoutData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        let settings = PrimerSettings(
            paymentHandling: paymentHandling == .auto ? .auto : .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(merchantIdentifier: "merchant.dx.team", merchantName: "Primer Merchant")
            )
        )
        Primer.shared.configure(settings: settings, delegate: self)
    }
    
    // MARK: - ACTIONS
    
    @IBAction func openVaultButtonTapped(_ sender: Any) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\n")
                
        let clientSessionRequestBody = Networking().clientSessionRequestBodyWithCurrency(customerId, phoneNumber: phoneNumber, countryCode: countryCode, currency: currency, amount: amount)

        Networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
            } else if let clientToken = clientToken {
                self.clientToken = clientToken
                Primer.shared.showVaultManager(clientToken: clientToken)
            }
        }
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        print("\nMERCHANT CHECKOUT VIEW CONTROLLER\n\(#function)\n")
        
        let clientSessionRequestBody = Networking().clientSessionRequestBodyWithCurrency(customerId, phoneNumber: phoneNumber, countryCode: countryCode, currency: currency, amount: amount)

        Networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
            } else if let clientToken = clientToken {
                self.clientToken = clientToken
                Primer.shared.showUniversalCheckout(clientToken: clientToken)
            }
        }
    }
}

// MARK: - PRIMER DELEGATE

extension MerchantCheckoutViewController: PrimerDelegate {
    
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

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
    
    class func instantiate(customerId: String, phoneNumber: String?, countryCode: CountryCode?, currency: Currency?, amount: Int?, performPayment: Bool) -> ManualPaymentMerchantCheckoutViewController {
        let mcvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ManualPaymentMerchantCheckoutViewController") as! ManualPaymentMerchantCheckoutViewController
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

    var transactionResponse: TransactionResponse?
    var performPayment: Bool = false
    var paymentResponsesData: [Data] = []
    
    var clientToken: String?
    var amount = 200
    var currency: Currency = .EUR
    var customerId: String!
    var phoneNumber: String?
    var countryCode: CountryCode = .gb
    var threeDSAlert: UIAlertController?
    
    var checkoutData: PrimerCheckoutData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        let settings = PrimerSettings(
            paymentHandling: paymentHandling,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io",
                applePayOptions: PrimerApplePayOptions(merchantIdentifier: "merchant.checkout.team", merchantName: "Primer Merchant")
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
                Primer.shared.showVaultManager(clientToken: clientToken, completion: nil)
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

extension ManualPaymentMerchantCheckoutViewController: PrimerDelegate {
    
    // Required
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\n🤯🤯🤯 \(#function)\ndata: \(data)")
        self.checkoutData = data
    }
    
    // Optional
    
    func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\n🤯🤯🤯 \(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")

        if paymentMethodTokenData.paymentInstrumentType == .paymentCard,
           let threeDSecureAuthentication = paymentMethodTokenData.threeDSecureAuthentication,
           (threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.notPerformed && threeDSecureAuthentication.responseCode != ThreeDS.ResponseCode.authSuccess) {
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
            decisionHandler(.succeed())
            return
        }
        
        Networking.createPayment(with: paymentMethodTokenData) { res, err in
            if let err = err {
                print(err)
                decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong creating the payment..."))
            } else if let res = res {
                if let data = try? JSONEncoder().encode(res) {
                    self.paymentResponsesData.append(data)
                }
                
                if res.status == .declined {
                    decisionHandler(.fail(withErrorMessage: "Oh no, payment was declined :("))
                    return
                }
                
                guard let requiredAction = res.requiredAction else {
                    decisionHandler(.succeed())
                    return
                }
                
                guard let dateStr = res.dateStr else {
                    decisionHandler(.succeed())
                    return
                }
                
                self.transactionResponse = TransactionResponse(id: res.id!, date: dateStr, status: res.status.rawValue, requiredAction: requiredAction)
                
                if res.status == .pending {
                    decisionHandler(.continueWithNewClientToken(requiredAction.clientToken))
                } else {
                    decisionHandler(.succeed())
                }
                
            } else {
                assert(true)
            }
        }
    }

    func primerDidResumeWith(_ resumeToken: String, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\n🤯🤯🤯 \(#function)\nresumeToken: \(resumeToken)")
        
        guard let transactionResponse = transactionResponse,
              let url = URL(string: "\(endpoint)/api/payments/\(transactionResponse.id)/resume")
        else {
            decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong parsing the response..."))
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyDic: [String: Any] = [
            "resumeToken": resumeToken
        ]
        
        var bodyData: Data!
        
        do {
            bodyData = try JSONSerialization.data(withJSONObject: bodyDic, options: .fragmentsAllowed)
        } catch {
            decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong creating the request..."))
            return
        }
        
        let networking = Networking()
        networking.request(
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
                    
                    decisionHandler(.succeed())

                case .failure(let err):
                    print(err)
                    decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong resuming the payment..."))
                }
            }
    }
    
    func primerDidDismiss() {
        print("\n\n🤯🤯🤯 \(#function)")
        
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
        print("\n\n🤯🤯🤯 \(#function)\nerror: \(error)\ndata: \(data)")
        let message = "Merchant App | ERROR"
        decisionHandler(.fail(withErrorMessage: message))
    }
}

struct TransactionResponse {
    var id: String
    var date: String
    var status: String
    var requiredAction: Payment.Response.RequiredAction?
}

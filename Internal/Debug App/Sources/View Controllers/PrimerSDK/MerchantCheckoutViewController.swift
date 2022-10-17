//
//  MerchantCheckoutViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantCheckoutViewController: UIViewController, PrimerDelegate {
    
    class func instantiate() -> MerchantCheckoutViewController {
        let mcvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantCheckoutViewController") as! MerchantCheckoutViewController
        return mcvc
    }
        
    var threeDSAlert: UIAlertController?
    
    var checkoutData: [String] = []
    var primerError: Error?
    var logs: [String] = []
    var transactionResponse: TransactionResponse?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Primer [\(environment.rawValue)]"
        
        let settings = PrimerSettings(
            paymentHandling: paymentHandling == .auto ? .auto : .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: "merchant://primer.io",
                applePayOptions: PrimerApplePayOptions(merchantIdentifier: "merchant.dx.team", merchantName: "Primer Merchant", isCaptureBillingAddressEnabled: true)
            )
        )
        
        Primer.shared.configure(settings: settings, delegate: self)
    }
    
    // MARK: - ACTIONS
    
    @IBAction func openVaultButtonTapped(_ sender: Any) {
        print("\n\nMERCHANT APP\n\(#function)\n")
        self.logs.append(#function)
        
        Networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
            } else if let clientToken = clientToken {
                Primer.shared.showVaultManager(clientToken: clientToken)
            }
        }
    }
    
    @IBAction func openUniversalCheckoutTapped(_ sender: Any) {
        print("\n\nMERCHANT APP\n\(#function)\n")
        self.logs.append(#function)
        
        Networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
            } else if let clientToken = clientToken {
                Primer.shared.showUniversalCheckout(clientToken: clientToken)
            }
        }
    }
}

// MARK: - PRIMER DELEGATE

// MARK: Auto Payment Handling

extension MerchantCheckoutViewController {
    
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\nPayment Success: \(data)\n")
        self.logs.append(#function)
        
        if let checkoutDataDictionary = try? data.asDictionary(),
           let jsonData = try? JSONSerialization.data(withJSONObject: checkoutDataDictionary, options: .prettyPrinted),
           let jsonString = jsonData.prettyPrintedJSONString {
            self.checkoutData.append(jsonString as String)
        }
    }
}

// MARK: Manual Payment Handling

extension MerchantCheckoutViewController {
    
    func primerDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")
        self.logs.append(#function)

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

        if !performPaymentAfterVaulting {
            decisionHandler(.succeed())
            return
        }
        
        Networking.createPayment(with: paymentMethodTokenData) { res, err in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong creating the payment..."))
                
            } else if let res = res {
                if let data = try? JSONEncoder().encode(res),
                   let jsonString = data.prettyPrintedJSONString
                {
                    self.checkoutData.append(jsonString as String)
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
        print("\n\nMERCHANT APP\n\(#function)\nresumeToken: \(resumeToken)")
        self.logs.append(#function)
        
        guard let transactionResponse = transactionResponse else {
            decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong parsing the response..."))
            return
        }
        
        Networking.resumePayment(transactionResponse.id, withToken: resumeToken) { res, err in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                decisionHandler(.fail(withErrorMessage: "Oh no, something went wrong creating the payment..."))
                
            } else if let res = res {
                if let data = try? JSONEncoder().encode(res),
                   let jsonString = data.prettyPrintedJSONString
                {
                    self.checkoutData.append(jsonString as String)
                }
                
                if res.status == .declined {
                    decisionHandler(.fail(withErrorMessage: "Oh no, payment was declined :("))
                } else {
                    decisionHandler(.succeed())
                }
            }
        }
    }
}

// MARK: Common

extension MerchantCheckoutViewController {
    
    func primerClientSessionWillUpdate() {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }
    
    func primerClientSessionDidUpdate(_ clientSession: PrimerClientSession) {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
    }
    
    func primerWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\nData: \(data)")
        self.logs.append(#function)
        decisionHandler(.continuePaymentCreation())
    }
    
    func primerDidEnterResumePendingWithPaymentAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(String(describing: additionalInfo))")
        self.logs.append(#function)
    }

    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping ((PrimerErrorDecision) -> Void)) {
        print("\n\nMERCHANT APP\n\(#function)\nError: \(error)")
        self.logs.append(#function)
        
        let message = "Merchant App | ERROR"
        decisionHandler(.fail(withErrorMessage: message))
    }
    
    func primerDidDismiss() {
        print("\n\nMERCHANT APP\n\(#function)")
        self.logs.append(#function)
        
        if let threeDSAlert = self.threeDSAlert {
            self.present(threeDSAlert, animated: true, completion: nil)
        }
        
        if !self.checkoutData.isEmpty {
            let rvc = MerchantResultViewController.instantiate(checkoutData: self.checkoutData, error: self.primerError, logs: self.logs)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
    }
}

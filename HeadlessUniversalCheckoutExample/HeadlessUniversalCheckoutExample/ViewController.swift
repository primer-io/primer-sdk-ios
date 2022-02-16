//
//  ViewController.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 16/2/22.
//

import PrimerSDK
import PromiseKit
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func payWithCardButtonTapped(_ sender: Any) {
        self.fetchClientToken { (clientToken, err) in
            if let err = err {
                
            } else if let clientToken = clientToken {
                // 👇 Settings are optional, but they are needed for Apple Pay and PayPal
                let settings = PrimerSettings(
                    merchantIdentifier: "merchant.dx.team",  // 👈 Entitlement added in Xcode's settings, required for Apple Pay
                    urlScheme: "merchant://")                // 👈 URL Scheme added in Xcode's settings, required for PayPal
                
                PrimerHeadlessUniversalCheckout.configure(withClientToken: clientToken, andSetings: settings) { paymentMethodTypes, err in
                    if paymentMethodTypes?.contains(.paymentCard) == true {
                        let cfvc = CardFormViewController.instantiate()
                        self.navigationController?.pushViewController(cfvc, animated: true)
                    } else {
                        self.showError(withMessage: "Card payments are not available")
                    }
                }
            }
        }
    }
    
    func fetchClientToken(completion: @escaping (String?, Error?) -> Void) {
        let clientSessionRequestBody = ClientSessionRequestBody(
            customerId: "customer_id",
            orderId: "order_id",
            currencyCode: .EUR,
            amount: 1000,
            metadata: nil,
            customer: nil,
            order: nil,
            paymentMethod: nil)
        
        let networking = Networking()
        networking.requestClientSession(requestBody: clientSessionRequestBody, completion: completion)
    }
    
}

extension UIViewController {
    
    func showError(withMessage message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
}


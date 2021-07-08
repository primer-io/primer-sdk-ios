//
//  AppViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class AppViewController: UIViewController, PrimerTextFieldViewDelegate, CardComponentsManagerDelegate {

    @IBOutlet weak var primerTextField: PrimerCardNumberFieldView!
    @IBOutlet weak var expiryDateFieldView: PrimerExpiryDateFieldView!
    @IBOutlet weak var cvvFieldView: PrimerCVVFieldView!
    @IBOutlet weak var cardholderFieldView: PrimerCardholderFieldView!
    
//    var cardComponentsManager: CardComponentsManager!
    let endpoint = "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        primerTextField.backgroundColor = .lightGray
        primerTextField.placeholder = "Card number"
        primerTextField.delegate = self
        expiryDateFieldView.backgroundColor = .lightGray
        expiryDateFieldView.placeholder = "Expiry date"
        expiryDateFieldView.delegate = self
        cvvFieldView.backgroundColor = .lightGray
        cvvFieldView.placeholder = "CVV"
        cvvFieldView.delegate = self
        cardholderFieldView.backgroundColor = .lightGray
        cardholderFieldView.placeholder = "Cardholder"
        cardholderFieldView.delegate = self
    }
    
    @IBAction func tokenize(_ sender: Any) {
//        clientTokenCallback { result in
//            switch result {
//            case .success(let token):
        let cardComponentsManager = CardComponentsManager(accessToken: "token", flow: .vault, cardnumberField: self.primerTextField, expiryDateField: self.expiryDateFieldView, cvvField: self.cvvFieldView, cardholderField: self.cardholderFieldView)
                cardComponentsManager.delegate = self
                cardComponentsManager.tokenize()
                
//            case .failure(let err):
//                break
//            }
//        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, didDetectCardNetwork cardNetwork: CardNetwork) {
        print(cardNetwork)
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        print("isTextValid: \(isValid)")
    }
    
    func clientTokenCallback(_ completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(endpoint)/clientToken") else {
            return completion(nil, NetworkError.missingParams)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = CreateClientTokenRequest(customerId: "customer123", customerCountryCode: nil)
        
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
                    print("🚀🚀🚀 token:", token)
                    completion(token, nil)

                } catch {
                    completion(nil, NetworkError.serializationError)
                    
                }
            case .failure(let err):
                completion(nil, err)
            }
        })
    }
    
    func onTokenizeSuccess(_ paymentMethodToken: PaymentMethodToken) {
        print("*** onTokenizeSuccess: \(paymentMethodToken)")
    }
    
    func tokenizationFailed(with errors: [Error]) {
        print("*** tokenizationFailed: \(errors)")
    }
    
    func isLoading(_ isLoading: Bool) {
        print("*** isLoading: \(isLoading)")
    }
}

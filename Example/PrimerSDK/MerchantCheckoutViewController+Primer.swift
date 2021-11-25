//
//  MerchantCheckoutViewController+Primer.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

extension MerchantCheckoutViewController {
    
    // MARK: - PRIMER HELPERS
    
    internal func fetchPaymentMethods() {

    }
    
    internal func presentPrimerOptions(_ index: Int) {
        let result = paymentMethodsDataSource[index]
        let alert = UIAlertController(title: "Pay", message: "Capture the payment, or authorize to capture later.", preferredStyle: .alert)
        let child = SpinnerViewController()
        
        alert.addAction(UIAlertAction(title: "Capture", style: .default, handler: { [weak self] _ in
            self?.addSpinner(child)
            guard let request = self?.generateRequest(result, capture: true) else { return }
            self?.callApi(request, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.removeSpinner(child)
                        self?.showResult(error: false)
                    case .failure:
                        self?.removeSpinner(child)
                        self?.showResult(error: true)
                    }
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Authorize", style: .default, handler: { [weak self] _ in
            self?.addSpinner(child)
            guard let request = self?.generateRequest(result, capture: false) else { return }
            self?.callApi(request, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.removeSpinner(child)
                        self?.showResult(error: false)
                    case .failure:
                        self?.removeSpinner(child)
                        self?.showResult(error: true)
                    }
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        present(alert, animated: true)
    }
    
    internal func generateRequest(_ token: PaymentMethodToken, capture: Bool) -> URLRequest? {
        guard let url = URL(string: "\(endpoint)/transaction") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = PaymentRequest(
            environment: environment,
            paymentMethod: token.token,
            amount: amount,
            type: token.paymentInstrumentType.rawValue,
            currencyCode: currency,
            countryCode: countryCode)
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return nil
        }
        
        return request
    }
    
    internal func generatePrimerTheme() -> PrimerTheme {
        return PrimerTheme()
    }
    
}

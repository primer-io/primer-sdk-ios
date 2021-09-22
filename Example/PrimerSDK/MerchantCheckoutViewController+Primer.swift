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
        Primer.shared.fetchVaultedPaymentMethods { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let err):
                    print("Error: \(err)")
                case .success(let tokens):
                    self?.paymentMethodsDataSource = tokens
                }
            }
        }
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
        
        let body = AuthorizationRequest(
            paymentMethod: token.token!,
            amount: amount,
            type: token.paymentInstrumentType.rawValue,
            currencyCode: "GBP"
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return nil
        }
        
        return request
    }
    
    internal func generatePrimerTheme() -> PrimerTheme {
        
        if #available(iOS 13.0, *) {
            return PrimerTheme(
                cornerRadiusTheme: CornerRadiusTheme(textFields: 8),
                colorTheme: PrimerDefaultTheme(),
                darkTheme: PrimerDarkTheme(),
                layout: PrimerLayout(showTopTitle: true, textFieldHeight: 40))
        } else {
            return PrimerTheme(
                cornerRadiusTheme: CornerRadiusTheme(textFields: 8),
                colorTheme: PrimerDefaultTheme(),
                layout: PrimerLayout(showTopTitle: false, textFieldHeight: 44),
                textFieldTheme: .outlined)
        }
    }
    
    internal func generateAmountAndOrderItems() -> (Int, [OrderItem]) {
        let items = [try! OrderItem(name: "Rent scooter", unitAmount: amount, quantity: 1)]
        var newAmount = 0
        items.forEach { newAmount += (($0.unitAmount ?? 0) * $0.quantity)  }
        
        return (
            amount,
            [try! OrderItem(name: "Rent scooter", unitAmount: newAmount, quantity: 1)]
        )
    }
    
    internal func generateBusinessDetails() -> BusinessDetails {
        return BusinessDetails(
            name: "My Business",
            address: Address(
                addressLine1: "107 Rue",
                addressLine2: nil,
                city: "Paris",
                state: nil,
                countryCode: "FR",
                postalCode: "75001"
            )
        )
    }
    
}

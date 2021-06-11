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
        
        alert.addAction(UIAlertAction(title: "Perform 3DS", style: .default, handler: { [weak self] _ in
            Primer.shared.performThreeDS(paymentMethod: result) { (err) in
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
                    if let nsErr = err as NSError? {
                        let threeDSResultAlert = UIAlertController(title: "Error", message: "\(nsErr.domain):\(nsErr.code) | \(nsErr.localizedDescription)", preferredStyle: .alert)
                        threeDSResultAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self?.present(threeDSResultAlert, animated: true, completion: nil)
                    } else {
                        let threeDSResultAlert = UIAlertController(title: "Success!", message: "(meaning that we got response)", preferredStyle: .alert)
                        threeDSResultAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self?.present(threeDSResultAlert, animated: true, completion: nil)
                    }
                }
            }
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
            capture: capture,
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
        let themeColor = UIColor(red: 240/255, green: 97/255, blue: 91/255, alpha: 1)
        
        if #available(iOS 13.0, *) {
            return PrimerTheme(
                cornerRadiusTheme: CornerRadiusTheme(textFields: 8),
                colorTheme: PrimerDefaultTheme(tint1: themeColor),
                darkTheme: PrimerDarkTheme(tint1: themeColor),
                layout: PrimerLayout(showTopTitle: true, textFieldHeight: 40)
//                fontTheme: PrimerFontTheme(
//                    mainTitleFont: .boldSystemFont(ofSize: 24),
//                    successMessageFont: UIFont(name: "ChocolateBarDemo", size: 20.0)!
//                )
            )
        } else {
            return PrimerTheme(
                cornerRadiusTheme: CornerRadiusTheme(textFields: 8),
                colorTheme: PrimerDefaultTheme(tint1: themeColor),
                layout: PrimerLayout(showTopTitle: false, textFieldHeight: 44),
                textFieldTheme: .outlined
//                fontTheme: PrimerFontTheme(
//                    mainTitleFont: .boldSystemFont(ofSize: 24),
//                    successMessageFont: UIFont(name: "ChocolateBarDemo", size: 20.0)!
//                )
            )
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

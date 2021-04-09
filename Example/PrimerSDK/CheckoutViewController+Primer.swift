//
//  CheckoutViewController+PrimerDelegatae.swift
//  PrimerSDK_Example
//
//  Created by Carl Eriksson on 08/04/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import PrimerSDK

// Initialise Primer

extension CheckoutViewController {
    func initPrimer() {

        let (finalAmount, items) = generateAmountAndOrderItems()
        let theme = generatePrimerTheme()
        let businessDetails = generateBusinessDetails()
        let isFullScreenOnly = false

        let settings = PrimerSettings(
            delegate: self,
            amount: finalAmount,
            currency: .SEK,
            countryCode: .se,
            urlScheme: "https://primer.io/success",
            urlSchemeIdentifier: "primer",
            isFullScreenOnly: isFullScreenOnly,
            businessDetails: businessDetails,
            orderItems: items
        )

        primer = Primer(with: settings)
        
        setDirectDebit()

        primer?.setTheme(theme: theme)
    }
    
    private func generatePrimerTheme() -> PrimerTheme {
        
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
    
    private func generateAmountAndOrderItems() -> (Int, [OrderItem]) {
        let items = [OrderItem(name: "Rent scooter", unitAmount: amount, quantity: 1)]
        var newAmount = 0
        items.forEach { newAmount += ($0.unitAmount * $0.quantity)  }
        
        return (
            amount,
            [OrderItem(name: "Rent scooter", unitAmount: newAmount, quantity: 1)]
        )
    }
    
    private func generateBusinessDetails() -> BusinessDetails {
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
    
    private func setDirectDebit() {
        primer?.setDirectDebitDetails(
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
}

// MARK: Implement PrimerDelegate protocol

extension CheckoutViewController: PrimerDelegate {
    
    func onCheckoutDismissed() {
        fetchPaymentMethods()
    }

    func clientTokenCallback(_ completion: @escaping (Result<CreateClientTokenResponse, Error>) -> Void) {
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
                    let token = try JSONDecoder().decode(CreateClientTokenResponse.self, from: data)
                    print("🚀🚀🚀 token:", token)
                    completion(.success(token))
                } catch {
                    completion(.failure(NetworkError.serializationError))
                }
            case .failure(let err): completion(.failure(err))
            }
        })
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

        print("🐳", result)

        completion(nil)
        
        //        callApi(request, completion: { result in
        //            switch result {
        //            case .success: completion(nil)
        //            case .failure(let err): completion(err)
        //            }
        //        })
    }
}

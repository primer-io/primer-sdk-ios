//
//  ViewController+Primer.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import UIKit

extension UIViewController {

    @objc var endpoint: String {
        "https://us-central1-primerdemo-8741b.cloudfunctions.net"
    }
}

extension UIViewController {

    // MARK: - PRIMER HELPERS

    internal func fetchPaymentMethodsForCustomerId(_ customerId: String?) {

        guard let url = URL(string: "\(endpoint)/api/payment-instruments"),
              let customerId = customerId else {
            return
        }

        let networking = Networking()
        networking.request(
            apiVersion: .v2,
            url: url,
            method: .get,
            headers: nil,
            queryParameters: ["customer_id": customerId],
            body: nil) { result in
            switch result {
            case .success(let data):
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print(json as Any)

            case .failure(let err):
                print(err)
            }
        }
    }

    internal func presentPrimerOptions(_ index: Int) {

    }

    internal func generatePrimerTheme() -> PrimerTheme {
        return PrimerTheme()
    }

}

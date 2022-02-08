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
        guard let url = URL(string: "\(endpoint)/api/payment-instruments") else {
            return
        }
        
        let networking = Networking()
        networking.request(
            environment: environment,
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

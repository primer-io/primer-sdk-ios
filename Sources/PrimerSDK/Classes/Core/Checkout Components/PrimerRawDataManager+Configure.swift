//
//  PrimerRawDataManager+Configure.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 15/10/22.
//

import Foundation

extension PrimerHeadlessUniversalCheckout.RawDataManager {
    
    public func configure(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {

        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
                
        switch paymentMethodType {
        case .xenditRetailOutlets:
            fetchRetailOutlets { data, error in completion(data, error) }
        default:
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType.rawValue, userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
        }
    }
}

extension PrimerHeadlessUniversalCheckout.RawDataManager {
    
    // Fetching Xendit Retail Outlets
    func fetchRetailOutlets(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {
        
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        apiClient.listRetailOutlets(clientToken: decodedJWTToken, paymentMethodId: paymentMethodId) { result in
            switch result {
            case .failure(let err):
                completion(nil, err)
            case .success(let res):
                let retailOutletsList = RetailOutletsList(result: res)
                completion(retailOutletsList, nil)
            }
        }
    }
}

//
//  PrimerRawDataManager+Configure.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 15/10/22.
//

#if canImport(UIKit)

import Foundation

extension PrimerHeadlessUniversalCheckout.RawDataManager {
    
    /// The provided function provides additional data after initializing a Raw Data Manager.
    ///
    /// Some payment methods needs additional data to perform a correct flow.
    /// The function needs to be called after `public init(paymentMethodType: String) throws` if additonal data is needed.
    ///
    /// - Parameters:
    ///     - completion: the completion block returning either `PrimerInitializationData` or `Error`

    public func configure(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {

        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
                
        switch paymentMethodType {
        case .xenditRetailOutlets:
            fetchRetailOutlets { data, error in completion(data, error) }
        default:
            completion(nil, nil)
        }
    }
}

extension PrimerHeadlessUniversalCheckout.RawDataManager {
    
    // Fetching Xendit Retail Outlets
    private func fetchRetailOutlets(completion: @escaping (PrimerInitializationData?, Error?) -> Void) {
        
        guard let paymentMethod = PrimerPaymentMethod.getPaymentMethod(withType: paymentMethodType), let paymentMethodId = paymentMethod.id else {
            let err = PrimerError.unsupportedPaymentMethod(paymentMethodType: paymentMethodType, userInfo: nil, diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                self.initializationData = res
                completion(self.initializationData, nil)
            }
        }
    }
}

#endif

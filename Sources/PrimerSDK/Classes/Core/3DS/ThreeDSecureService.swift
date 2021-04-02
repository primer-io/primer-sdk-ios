//
//  ThreeDService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 1/4/21.
//

#if canImport(UIKit)

import Foundation

protocol ThreeDSecureServiceProtocol {
    func threeDSecureBeginAuthentication(paymentMethodToken: PaymentMethodToken,
                                         threeDSecureBeginAuthRequest: ThreeDSecureBeginAuthRequest,
                                         completion: @escaping (ThreeDSecureBeginAuthResponse?, Error?) -> Void)
}

class ThreeDSecureService: ThreeDSecureServiceProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var api: PrimerAPIClientProtocol
    
    func threeDSecureBeginAuthentication(paymentMethodToken: PaymentMethodToken,
                                         threeDSecureBeginAuthRequest: ThreeDSecureBeginAuthRequest,
                                         completion: @escaping (ThreeDSecureBeginAuthResponse?, Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(nil, PrimerError.vaultFetchFailed)
        }
        
        api.threeDSecureBeginAuthentication(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
            switch result {
            case .failure:
                completion(nil, PrimerError.threeDSFailed)
            case .success(let res):
                completion(res, nil)
            }
        })
        
        //        api.vaultFetchPaymentMethods(clientToken: clientToken) { [weak self] (result) in
        //            switch result {
        //            case .failure:
        //                completion(PrimerError.vaultFetchFailed)
        //            case .success(let paymentMethods):
        //                self?.state.paymentMethods = paymentMethods.data
        //
        //                guard let paymentMethods = self?.state.paymentMethods else { return }
        //
        //                if self?.state.selectedPaymentMethod.isEmpty == true && paymentMethods.isEmpty == false {
        //                    guard let id = paymentMethods[0].token else { return }
        //                    self?.state.selectedPaymentMethod = id
        //                }
        //
        //                completion(nil)
        //            }
        //        }
    }
}

#endif


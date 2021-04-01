//
//  ThreeDService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 1/4/21.
//

#if canImport(UIKit)

import Foundation

protocol ThreeDSecureServiceProtocol {
    func threeDSecureBeginAuthentication(paymentMethodToken: PaymentMethodToken, completion: @escaping (Error?) -> Void)
}

class ThreeDSecureService: ThreeDSecureServiceProtocol {

    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var api: PrimerAPIClientProtocol

    func threeDSecureBeginAuthentication(paymentMethodToken: PaymentMethodToken, completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.vaultFetchFailed)
        }
        
        let threeDSecureBeginAuthRequest = ThreeDSecureBeginAuthRequest(testScenario: .threeDS_V2_FRICTIONLESS_PASS,
                                                                        amount: 100,
                                                                        currencyCode: .EUR,
                                                                        orderId: "test_id",
                                                                        customer: ThreeDSecureCustomer(name: "Evangelos",
                                                                                                       email: "evangelos@primer.io",
                                                                                                       homePhone: nil,
                                                                                                       mobilePhone: nil,
                                                                                                       workPhone: nil),
                                                                        device: ThreeDSecureDevice(sdkTransactionId: ""),
                                                                        billingAddress: ThreeDSecureAddress(title: nil,
                                                                                                            firstName: nil,
                                                                                                            lastName: nil,
                                                                                                            email: nil,
                                                                                                            phoneNumber: nil,
                                                                                                            addressLine1: "my address line 1",
                                                                                                            addressLine2: nil,
                                                                                                            addressLine3: nil,
                                                                                                            city: "Athens",
                                                                                                            state: nil,
                                                                                                            countryCode: .gr,
                                                                                                            postalCode: "11472"),
                                                                        shippingAddress: nil,
                                                                        customerAccount: nil)
        
        api.threeDSecureBeginAuthentication(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
            switch result {
            case .failure:
                completion(PrimerError.threeDSFailed)
            case .success(let res):
                completion(nil)
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




#if canImport(UIKit)

import Foundation
import ThreeDS_SDK

protocol VaultServiceProtocol {
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void)
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void)
}

class VaultService: VaultServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    // swiftlint:disable cyclomatic_complexity
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.vaultFetchFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.vaultFetchPaymentMethods(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure:
                completion(PrimerError.vaultFetchFailed)
            case .success(let paymentMethods):
                state.paymentMethods = paymentMethods.data

                let paymentMethods = state.paymentMethods
                
                if !paymentMethods.isEmpty {
                    print(paymentMethods)
                    if let paymentMethod = paymentMethods.first {
                        print(paymentMethod)
                        
                        let service = ThreeDSecureService()
                        service.initializeSDK { (initResult) in
                            switch initResult {
                            case .success:
                                service.verifyWarnings { (verifyResult) in
                                    print(verifyResult)
                                    switch verifyResult {
                                    case .success:
                                        service.netceteraAuth(paymentMethod: paymentMethod) { (authResult) in
                                            switch authResult {
                                            case .success(let sdkTransactionId):
                                                print("3DS SDK transaction ID: \(sdkTransactionId)")
                                                
                                                let threeDSecureDevice = ThreeDSecureDevice(sdkTransactionId: sdkTransactionId)
                                                var req = ThreeDSecureBeginAuthRequest.demoAuthRequest
//                                                req.testScenario = ThreeDSecureTestScenario.threeDS2FrictionlessPass
                                                req.device = threeDSecureDevice
//                                                req.deviceChannel = "02"
                                                req.amount = 20000
                                                
                                                service.threeDSecureBeginAuthentication(paymentMethodToken: paymentMethod,
                                                                                               threeDSecureBeginAuthRequest: req) { (res, err) in
                                                    if let err = err {
                                                        print(err)
                                                    } else if let val = res?.authentication as? ThreeDSSkippedAPIResponse {
                                                        print(val)
                                                    } else if let val = res?.authentication as? ThreeDSMethodAPIResponse {
                                                        print(val)
                                                    } else if let val = res?.authentication as? ThreeDSBrowserV2ChallengeAPIResponse {
                                                        print(val)
                                                    } else if let val = res?.authentication as? ThreeDSAppV2ChallengeAPIResponse {
                                                        print(val)
                                                    } else if let val = res?.authentication as? ThreeDSBrowserV1ChallengeAPIResponse {
                                                        print(val)
                                                    } else if let val = res?.authentication as? ThreeDSDeclinedAPIResponse {
                                                        print(val)
                                                    } else if let val = res?.authentication as? ThreeDSSuccessAPIResponse {
                                                        print(val)
                                                    }
                                                }
                                            case .failure(let err):
                                                break
                                            }
                                        }
                                    case .failure(let err):
                                        break
                                    }
                                }
                            case .failure(let err):
                                break
                            }
                        }
                    }

                }

                if state.selectedPaymentMethod.isEmpty == true && paymentMethods.isEmpty == false {
                    guard let id = paymentMethods[0].token else { return }
                    state.selectedPaymentMethod = id
                }

                completion(nil)
            }
        }
    }

    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.vaultDeleteFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.vaultDeletePaymentMethod(clientToken: clientToken, id: id) { (result) in
            switch result {
            case .failure:
                completion(PrimerError.vaultDeleteFailed)
            case .success:
                completion(nil)
            }
        }
    }
}

#endif

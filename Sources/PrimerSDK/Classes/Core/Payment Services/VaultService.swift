

#if canImport(UIKit)

import Foundation
import ThreeDS_SDK

protocol VaultServiceProtocol {
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void)
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void)
}

class VaultService: VaultServiceProtocol {

    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var api: PrimerAPIClientProtocol

    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.vaultFetchFailed)
        }

        api.vaultFetchPaymentMethods(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure:
                completion(PrimerError.vaultFetchFailed)
            case .success(let paymentMethods):
                self?.state.paymentMethods = paymentMethods.data

                guard let paymentMethods = self?.state.paymentMethods else { return }
                
                if !paymentMethods.isEmpty {
                    print(paymentMethods)
                    if let paymentMethod = paymentMethods.first {
                        let threeDS2Service: ThreeDS_SDK.ThreeDS2Service = ThreeDS2ServiceSDK()
                        
                        
                        do {
                            let configParameters = ConfigParameters()
                            try configParameters.addParam(group:nil, paramName:"license-key", paramValue: Primer.netceteraLicenseKey)
                            try threeDS2Service.initialize(configParameters, locale: nil, uiCustomization: nil)
                            let warnings = try threeDS2Service.getWarnings()
                            for w in warnings {
                                print("Warning \(w.getID()) [\(w.getSeverity().rawValue)]: \(w.getMessage())")
                            }
                        } catch {
                            print(error)
                        }
                        
                        
                        
                        var req = ThreeDSecureBeginAuthRequest.demoAuthRequest
                        req.testScenario = ThreeDSecureTestScenario.threeDS_V2_AUTO_CHALLENGE_FAIL
                        
                        let threeDSService = ThreeDSecureService()
                        threeDSService.threeDSecureBeginAuthentication(paymentMethodToken: paymentMethod,
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
                    }

                }

                if self?.state.selectedPaymentMethod.isEmpty == true && paymentMethods.isEmpty == false {
                    guard let id = paymentMethods[0].token else { return }
                    self?.state.selectedPaymentMethod = id
                }

                completion(nil)
            }
        }
    }

    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.vaultDeleteFailed)
        }

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

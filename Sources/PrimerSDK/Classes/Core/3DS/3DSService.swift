//
//  ThreeDSService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 17/6/21.
//

import Foundation
import ThreeDS_SDK

protocol ThreeDSServiceProtocol {
    func perform3DS(
        _ sdk: ThreeDSSDKProtocol,
        cardNetwork: CardNetwork,
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        presentOn viewController: UIViewController,
        completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void
    )
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void)
    func sdkAuth(sdk: ThreeDSSDKProtocol,
                 cardNetwork: CardNetwork,
                 protocolVersion: ThreeDS.ProtocolVersion,
                 completion: @escaping (Result<Transaction, Error>) -> Void)
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func performChallenge(with sdk: ThreeDSSDKProtocol,
                          on transaction: Transaction,
                          with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol,
                          presentOn viewController: UIViewController,
                          completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void)
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void)
}

class ThreeDSService: ThreeDSServiceProtocol {
    
    deinit {
        print("ThreeDSecureServiceProtocol deinit")
    }
    
    static func validate3DSParameters() throws {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !Primer.shared.flow.internalSessionFlow.vaulted && settings.amount == nil {
            throw PrimerError.amountMissing
        }
        
        guard let currency = settings.currency else {
            throw PrimerError.currencyMissing
        }
        
        guard let orderId = settings.orderId else {
            throw PrimerError.orderIdMissing
        }
        
        guard let billingAddress = settings.billingAddress else {
            throw PrimerError.billingAddressMissing
        }
        
        guard let city = billingAddress.city, !city.isEmpty else {
            throw PrimerError.billingAddressCityMissing
        }
        
        guard let countryCodeStr = settings.billingAddress?.countryCode, let countryCode = CountryCode(rawValue: countryCodeStr) else {
            throw PrimerError.billingAddressCountryCodeMissing
        }
        
        guard let postalCode = settings.billingAddress?.postalCode, !postalCode.isEmpty else {
            throw PrimerError.billingAddressPostalCodeMissing
        }
    }
    
    func perform3DS(
        _ sdk: ThreeDSSDKProtocol,
        cardNetwork: CardNetwork,
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        presentOn viewController: UIViewController,
        completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void
    ) {
        var transaction: Transaction!
        
        firstly {
            initializeSDK(sdk)
        }
        .then { () -> Promise<Transaction> in
            return self.sdkAuth(sdk: sdk, cardNetwork: cardNetwork, protocolVersion: protocolVersion)
        }
        .then { trx -> Promise<ThreeDS.BeginAuthResponse> in
            transaction = trx
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if !Primer.shared.flow.internalSessionFlow.vaulted && settings.amount == nil {
                throw PrimerError.amountMissing
            }
            
            guard let currency = settings.currency else {
                throw PrimerError.currencyMissing
            }
            
            guard let orderId = settings.orderId else {
                throw PrimerError.orderIdMissing
            }
            
            guard let billingAddress = settings.billingAddress else {
                throw PrimerError.billingAddressMissing
            }
            
            guard let addressLine1 = billingAddress.addressLine1, !addressLine1.isEmpty else {
                throw PrimerError.billingAddressCityMissing
            }
            
            guard let city = billingAddress.city, !city.isEmpty else {
                throw PrimerError.billingAddressCityMissing
            }
            
            guard let countryCodeStr = settings.billingAddress?.countryCode, let countryCode = CountryCode(rawValue: countryCodeStr) else {
                throw PrimerError.billingAddressCountryCodeMissing
            }
            
            guard let postalCode = settings.billingAddress?.postalCode, !postalCode.isEmpty else {
                throw PrimerError.billingAddressPostalCodeMissing
            }
            
            guard let userDetails = settings.userDetails,
                  !userDetails.firstName.isEmpty,
                  !userDetails.lastName.isEmpty,
                  !userDetails.email.isEmpty
            else {
                throw PrimerError.userDetailsMissing
            }
            
            let customer = ThreeDS.Customer(name: "\(userDetails.firstName) \(userDetails.lastName)",
                                            email: userDetails.email,
                                            homePhone: userDetails.homePhone,
                                            mobilePhone: userDetails.mobilePhone,
                                            workPhone: userDetails.workPhone)
            
            let threeDSAddress = ThreeDS.Address(title: nil,
                                                 firstName: userDetails.firstName,
                                                 lastName: userDetails.lastName,
                                                 email: userDetails.email,
                                                 phoneNumber: userDetails.mobilePhone ?? userDetails.homePhone ?? userDetails.workPhone,
                                                 addressLine1: addressLine1,
                                                 addressLine2: billingAddress.addressLine2,
                                                 addressLine3: nil,
                                                 city: city,
                                                 state: billingAddress.state,
                                                 countryCode: countryCode,
                                                 postalCode: postalCode)
            
            do {
                let threeDSecureAuthData = try transaction.buildThreeDSecureAuthData()
                let threeDSecureBeginAuthRequest = ThreeDS.BeginAuthRequest(testScenario: nil,
                                                                            amount: settings.amount ?? 0,
                                                                            currencyCode: currency,
                                                                            orderId: "test_id",
                                                                            customer: customer,
                                                                            device: threeDSecureAuthData as! ThreeDS.SDKAuthData,
                                                                            billingAddress: threeDSAddress,
                                                                            shippingAddress: nil,
                                                                            customerAccount: nil)
                
                return self.beginRemoteAuth(paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
            } catch {
                throw error
            }
        }
        .done { beginAuthResponse in
            guard let rvc = (UIApplication.shared.delegate as? UIApplicationDelegate)?.window??.rootViewController else {
                throw NSError(domain: "primer", code: 100, userInfo: nil)
            }
            
            let prvc = Primer.shared.root
            let presentingViewController = prvc?.presentingViewController
            
            prvc?.dismiss(animated: true) {
                firstly {
                    self.performChallenge(with: sdk, on: transaction, with: beginAuthResponse.authentication, presentOn: presentingViewController!)
                }
                .then { sdkAuth -> Promise<ThreeDS.PostAuthResponse> in
                    return self.continueRemoteAuth(threeDSTokenId: paymentMethodToken.token!)
                }
                .done { postAuthResponse in
                    completion(.success(postAuthResponse.token))
                }
                .catch { err in
                    completion(.failure(err))
                }
            }
        }
        .catch { err in
            completion(.failure(err))
        }
    }
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.initializeSDK(completion: completion)
    }
    
    func sdkAuth(sdk: ThreeDSSDKProtocol,
                 cardNetwork: CardNetwork,
                 protocolVersion: ThreeDS.ProtocolVersion,
                 completion: @escaping (Result<Transaction, Error>) -> Void) {
        sdk.sdkAuth(cardNetwork: cardNetwork, protocolVersion: protocolVersion, completion: completion)
    }
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.threeDSBeginAuth(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        })
    }
    
    func performChallenge(with sdk: ThreeDSSDKProtocol,
                          on transaction: Transaction,
                          with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol,
                          presentOn viewController: UIViewController,
                          completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void) {
        sdk.performChallenge(on: transaction,
                             with: threeDSecureAuthResponse,
                             presentOn: viewController,
                             completion: completion)
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.threeDSContinueAuth(clientToken: clientToken, threeDSTokenId: threeDSTokenId) { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        }
    }
    
}

class MockThreeDSService: ThreeDSServiceProtocol {
    func perform3DS(
        _ sdk: ThreeDSSDKProtocol,
        cardNetwork: CardNetwork,
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        presentOn viewController: UIViewController,
        completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void
    ) { }
    
    
    var response: Data?
    let throwsError: Bool = false
    var isCalled: Bool = false
    
    init(with response: Data? = nil) {
        self.response = response
    }
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.initializeSDK(completion: completion)
    }
    
    func sdkAuth(sdk: ThreeDSSDKProtocol, cardNetwork: CardNetwork, protocolVersion: ThreeDS.ProtocolVersion, completion: @escaping (Result<Transaction, Error>) -> Void) {
        sdk.sdkAuth(cardNetwork: cardNetwork, protocolVersion: protocolVersion, completion: completion)
    }
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.threeDSBeginAuth(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: completion)
    }
    
    func performChallenge(with sdk: ThreeDSSDKProtocol, on transaction: Transaction, with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol, presentOn viewController: UIViewController, completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void) {
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            do {
                let authCompletion = ThreeDS.ThreeDSSDKAuthCompletion(sdkTransactionId: "transaction_id", transactionStatus: .y)
                completion(.success(authCompletion))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.threeDSContinueAuth(clientToken: clientToken, threeDSTokenId: threeDSTokenId, completion: completion)
    }
}

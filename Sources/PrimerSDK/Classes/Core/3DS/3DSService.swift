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
        withSDK sdk: ThreeDSSDKProtocol,
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void
    )
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void)
    func authenticateSdk(sdk: ThreeDSSDKProtocol,
                 cardNetwork: CardNetwork,
                 protocolVersion: ThreeDS.ProtocolVersion,
                 completion: @escaping (Result<Transaction, Error>) -> Void)
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func performChallenge(with sdk: ThreeDSSDKProtocol,
                          on transaction: Transaction,
                          threeDSAuth: ThreeDSAuthenticationProtocol,
                          presentOn viewController: UIViewController,
                          completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void)
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void)
}

class ThreeDSService: ThreeDSServiceProtocol {
    
    private var threeDSSDKWindow: UIWindow?
    
    deinit {
        
    }
    
    static func validate3DSParameters() throws {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !Primer.shared.flow.internalSessionFlow.vaulted && settings.amount == nil {
            throw PrimerError.amountMissing
        }
        
        guard settings.currency != nil else {
            throw PrimerError.currencyMissing
        }
        
        guard settings.orderId != nil else {
            throw PrimerError.orderIdMissing
        }
        
        guard let city = settings.userDetails?.city, !city.isEmpty else {
            throw PrimerError.userDetailsCityMissing
        }
        
        guard let countryCodeStr = settings.userDetails?.countryCode, CountryCode(rawValue: countryCodeStr) != nil else {
            throw PrimerError.userDetailsCountryCodeMissing
        }
        
        guard let postalCode = settings.userDetails?.postalCode, !postalCode.isEmpty else {
            throw PrimerError.userDetailsPostalCodeMissing
        }
    }
    
    func perform3DS(
        withSDK sdk: ThreeDSSDKProtocol,
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void
    ) {
        var transaction: Transaction!
        let cardNetwork = CardNetwork(rawValue: paymentMethodToken.paymentInstrumentData?.network)
        
        firstly {
            initializeSDK(sdk)
        }
        .then { () -> Promise<Transaction> in
            return self.authenticateSdk(sdk: sdk, cardNetwork: cardNetwork, protocolVersion: protocolVersion)
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
            
            guard settings.orderId != nil else {
                throw PrimerError.orderIdMissing
            }
            
            guard let addressLine1 = settings.userDetails?.addressLine1, !addressLine1.isEmpty else {
                throw PrimerError.userDetailsAddressLine1Missing
            }
            
            guard let city = settings.userDetails?.city, !city.isEmpty else {
                throw PrimerError.userDetailsCityMissing
            }
            
            guard let countryCodeStr = settings.userDetails?.countryCode, let countryCode = CountryCode(rawValue: countryCodeStr) else {
                throw PrimerError.userDetailsCountryCodeMissing
            }
            
            guard let postalCode = settings.userDetails?.postalCode, !postalCode.isEmpty else {
                throw PrimerError.userDetailsCountryCodeMissing
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
                                                 addressLine2: settings.userDetails?.addressLine2,
                                                 addressLine3: nil,
                                                 city: city,
                                                 state: nil,
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
            switch beginAuthResponse.authentication.responseCode {
            case .authSuccess:
                // Frictionless pass
                // Frictionless attempt
                completion(.success(beginAuthResponse.token))
                return
            case .notPerformed:
                // Not enough data to perform 3DS. Won't be returned.
                break
            case .skipped:
                // Skipped because of a technical failure.
                completion(.success(beginAuthResponse.token))
                return
            case .authFailed:
                // Frictionless fail
                // Frictionless not authenticated
                completion(.success(beginAuthResponse.token))
                return
            case .challenge:
                // Continue to present the challenge
                break
            case .METHOD:
                // Only applies on the web
                break
            }
            
            self.threeDSSDKWindow = UIWindow(frame: UIScreen.main.bounds)
            self.threeDSSDKWindow!.rootViewController = ClearViewController()
            self.threeDSSDKWindow!.backgroundColor = UIColor.clear
            self.threeDSSDKWindow!.windowLevel = UIWindow.Level.normal
            self.threeDSSDKWindow!.makeKeyAndVisible()
            
            firstly {
                self.performChallenge(with: sdk, on: transaction, threeDSAuth: beginAuthResponse.authentication, presentOn: self.threeDSSDKWindow!.rootViewController!)
            }
            .done { sdkAuth in
                self.threeDSSDKWindow!.isHidden = true
                self.threeDSSDKWindow = nil
                
                firstly {
                    self.continueRemoteAuth(threeDSTokenId: paymentMethodToken.token!)
                }
                .done { postAuthResponse in
                    completion(.success(postAuthResponse.token))
                }
                .catch { err in
                    completion(.failure(err))
                }
            }
            .ensure {
                sdkDismissed?()
            }
            .catch { err in
                completion(.failure(err))
            }
        }
        .catch { err in
            completion(.failure(err))
        }
    }
    
    func initializeSDK(_ sdk: ThreeDSSDKProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        sdk.initializeSDK(completion: completion)
    }
    
    func authenticateSdk(sdk: ThreeDSSDKProtocol,
                 cardNetwork: CardNetwork,
                 protocolVersion: ThreeDS.ProtocolVersion,
                 completion: @escaping (Result<Transaction, Error>) -> Void) {
        sdk.authenticateSdk(cardNetwork: cardNetwork, protocolVersion: protocolVersion, completion: completion)
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
                          threeDSAuth: ThreeDSAuthenticationProtocol,
                          presentOn viewController: UIViewController,
                          completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void) {
        sdk.performChallenge(on: transaction,
                             with: threeDSAuth,
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
        withSDK sdk: ThreeDSSDKProtocol,
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        sdkDismissed: (() -> Void)?,
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
    
    func authenticateSdk(sdk: ThreeDSSDKProtocol, cardNetwork: CardNetwork, protocolVersion: ThreeDS.ProtocolVersion, completion: @escaping (Result<Transaction, Error>) -> Void) {
        sdk.authenticateSdk(cardNetwork: cardNetwork, protocolVersion: protocolVersion, completion: completion)
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
    
    func performChallenge(with sdk: ThreeDSSDKProtocol, on transaction: Transaction, threeDSAuth: ThreeDSAuthenticationProtocol, presentOn viewController: UIViewController, completion: @escaping (Result<ThreeDS.ThreeDSSDKAuthCompletion, Error>) -> Void) {
        
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

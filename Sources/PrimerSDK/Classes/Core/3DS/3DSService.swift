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
        var errors: [Error] = []
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !Primer.shared.flow.internalSessionFlow.vaulted && settings.amount == nil {
            errors.append(PrimerError.amountMissing)
        }
        
        if settings.currency == nil {
            errors.append(PrimerError.currencyMissing)
        }
        
        if settings.orderId == nil {
            errors.append(PrimerError.orderIdMissing)
        }
        
        if (settings.userDetails?.addressLine1 ?? "").isEmpty {
            errors.append(PrimerError.userDetailsAddressLine1Missing)
        }
        
        if (settings.userDetails?.city ?? "").isEmpty {
            errors.append(PrimerError.userDetailsCityMissing)
        }
        
        if settings.userDetails?.countryCode == nil {
            errors.append(PrimerError.userDetailsCountryCodeMissing)
        } else if CountryCode(rawValue: settings.userDetails!.countryCode) == nil {
            errors.append(PrimerError.userDetailsCountryCodeMissing)
        }
        
        if (settings.userDetails?.postalCode ?? "").isEmpty {
            errors.append(PrimerError.userDetailsCountryCodeMissing)
        }
        
        if (settings.userDetails?.firstName ?? "").isEmpty ||
            (settings.userDetails?.lastName ?? "").isEmpty ||
            (settings.userDetails?.email ?? "").isEmpty
        {
            errors.append(PrimerError.userDetailsMissing)
        }
        
        if !errors.isEmpty {
            var errorDescription: String = ""
            for err in errors {
                errorDescription += err.localizedDescription + "\n"
            }
            
            throw PrimerError.dataMissing(description: errorDescription)
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
        
        do {
            try ThreeDSService.validate3DSParameters()
        } catch {
            completion(.failure(error))
            return
        }
        
        firstly {
            initializeSDK(sdk)
        }
        .then { () -> Promise<Transaction> in
            return self.authenticateSdk(sdk: sdk, cardNetwork: cardNetwork, protocolVersion: protocolVersion)
        }
        .then { trx -> Promise<ThreeDS.BeginAuthResponse> in
            transaction = trx
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            let userDetails = settings.userDetails!
            
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
                                                 addressLine1: userDetails.addressLine1,
                                                 addressLine2: settings.userDetails?.addressLine2,
                                                 addressLine3: nil,
                                                 city: userDetails.city,
                                                 state: nil,
                                                 countryCode: CountryCode(rawValue: userDetails.countryCode)!,
                                                 postalCode: userDetails.postalCode)
            
            do {
                let threeDSecureAuthData = try transaction.buildThreeDSecureAuthData()
                let threeDSecureBeginAuthRequest = ThreeDS.BeginAuthRequest(testScenario: nil,
                                                                            amount: settings.amount ?? 0,
                                                                            currencyCode: settings.currency!,
                                                                            orderId: settings.orderId ?? "",
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
            self.threeDSSDKWindow?.rootViewController = ClearViewController()
            self.threeDSSDKWindow?.backgroundColor = UIColor.clear
            self.threeDSSDKWindow?.windowLevel = UIWindow.Level.normal
            self.threeDSSDKWindow?.makeKeyAndVisible()
            
            firstly {
                self.performChallenge(with: sdk, on: transaction, threeDSAuth: beginAuthResponse.authentication, presentOn: self.threeDSSDKWindow!.rootViewController!)
            }
            .done { sdkAuth in
                firstly {
                    self.continueRemoteAuth(threeDSTokenId: paymentMethodToken.token!)
                }
                .done { postAuthResponse in
                    completion(.success(postAuthResponse.token))
                }
                .catch { err in
                    var token = paymentMethodToken
                    token.threeDSecureAuthentication = ThreeDS.AuthenticationDetails(responseCode: .skipped, reasonCode: "CLIENT_ERROR", reasonText: err.localizedDescription, protocolVersion: ThreeDS.ProtocolVersion.v1.rawValue, challengeIssued: true)
                    completion(.success(token))
                }
            }
            .ensure {
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    self.threeDSSDKWindow?.isHidden = true
                    self.threeDSSDKWindow = nil
                    sdkDismissed?()
                }
            }
            .catch { err in
                var token = paymentMethodToken
                token.threeDSecureAuthentication = ThreeDS.AuthenticationDetails(responseCode: .skipped, reasonCode: "CLIENT_ERROR", reasonText: err.localizedDescription, protocolVersion: ThreeDS.ProtocolVersion.v1.rawValue, challengeIssued: false)
                completion(.success(token))
            }
        }
        .catch { err in
            self.threeDSSDKWindow?.isHidden = true
            self.threeDSSDKWindow = nil
            
            var token = paymentMethodToken
            token.threeDSecureAuthentication = ThreeDS.AuthenticationDetails(responseCode: .skipped, reasonCode: "CLIENT_ERROR", reasonText: err.localizedDescription, protocolVersion: ThreeDS.ProtocolVersion.v1.rawValue, challengeIssued: false)
            completion(.success(token))
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

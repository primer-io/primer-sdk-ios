//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(Primer3DS)
#if canImport(UIKit)

import Foundation
import Primer3DS
import UIKit

protocol ThreeDSServiceProtocol {
    func perform3DS(
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        beginAuthExtraData: ThreeDS.BeginAuthExtraData?,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<(PaymentMethodToken, ThreeDS.PostAuthResponse?), Error>) -> Void
    )
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void)
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void)
}

extension ThreeDS {
    class Cer: Primer3DSCertificate {
        var cardScheme: String
        var encryptionKey: String
        var rootCertificate: String
        
        init(cardScheme: String, rootCertificate: String, encryptionKey: String) {
            self.cardScheme = cardScheme
            self.rootCertificate = rootCertificate
            self .encryptionKey = encryptionKey
        }
        
    }
    
    class ServerAuthData: Primer3DSServerAuthData {
        var acsReferenceNumber: String?
        var acsSignedContent: String?
        var acsTransactionId: String?
        var responseCode: String
        var transactionId: String?
        
        init(acsReferenceNumber: String?, acsSignedContent: String?, acsTransactionId: String?, responseCode: String, transactionId: String?) {
            self.acsReferenceNumber = acsReferenceNumber
            self.acsSignedContent = acsSignedContent
            self.acsTransactionId = acsTransactionId
            self.responseCode = responseCode
            self.transactionId = transactionId
        }
    }
}

class ThreeDSService: ThreeDSServiceProtocol {
    
    private var threeDSSDKWindow: UIWindow?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    static func validate3DSParameters() throws {
        var errors: [Error] = []
                
        if Primer.shared.intent == .checkout && AppState.current.amount == nil {
            let err = PrimerError.invalidValue(key: "settings.amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if AppState.current.currency == nil {
            let err = PrimerError.invalidValue(key: "settings.currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if AppState.current.apiConfiguration?.clientSession?.order?.id == nil {
            let err = PrimerError.invalidValue(key: "settings.orderId", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (AppState.current.apiConfiguration?.clientSession?.customer?.billingAddress?.addressLine1 ?? "").isEmpty {
            let err = PrimerError.invalidValue(key: "settings.customer?.billingAddress?.addressLine1", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (AppState.current.apiConfiguration?.clientSession?.customer?.billingAddress?.city ?? "").isEmpty {
            let err = PrimerError.invalidValue(key: "settings.customer?.billingAddress?.city", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if AppState.current.apiConfiguration?.clientSession?.customer?.billingAddress?.countryCode == nil {
            let err = PrimerError.invalidValue(key: "settings.customer?.billingAddress?.countryCode", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (AppState.current.apiConfiguration?.clientSession?.customer?.billingAddress?.postalCode ?? "").isEmpty {
            let err = PrimerError.invalidValue(key: "settings.customer?.billingAddress?.postalCode", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (AppState.current.apiConfiguration?.clientSession?.customer?.firstName ?? "").isEmpty {
            let err = PrimerError.invalidValue(key: "settings.customer?.firstName", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (AppState.current.apiConfiguration?.clientSession?.customer?.lastName ?? "").isEmpty {
            let err = PrimerError.invalidValue(key: "settings.customer?.lastName", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (AppState.current.apiConfiguration?.clientSession?.customer?.emailAddress ?? "").isEmpty {
            let err = PrimerError.invalidValue(key: "settings.customer?.emailAddress", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if !errors.isEmpty {
            let containerErr = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: containerErr)
            throw containerErr
        }
    }
    
    static func buildBeginAuthExtraData() throws -> ThreeDS.BeginAuthExtraData {
        do {
            try ThreeDSService.validate3DSParameters()
        } catch {
            ErrorHandler.shared.handle(error: error)
            throw error
        }
        
        let clientSession = AppState.current.apiConfiguration!.clientSession!
        let customer = clientSession.customer!
        
        let threeDSCustomer = ThreeDS.Customer(name: "\(customer.firstName!) \(customer.lastName!)",
                                        email: customer.emailAddress!,
                                        homePhone: nil,
                                        mobilePhone: customer.mobileNumber,
                                        workPhone: nil)
        
        let threeDSAddress = ThreeDS.Address(title: nil,
                                             firstName: customer.firstName,
                                             lastName: customer.lastName,
                                             email: customer.emailAddress,
                                             phoneNumber: customer.mobileNumber,
                                             addressLine1: customer.billingAddress!.addressLine1!,
                                             addressLine2: customer.billingAddress!.addressLine2,
                                             addressLine3: nil,
                                             city: customer.billingAddress!.city!,
                                             state: nil,
                                             countryCode: CountryCode(rawValue: customer.billingAddress!.countryCode!.rawValue)!,
                                             postalCode: customer.billingAddress!.postalCode!)
        
        return ThreeDS.BeginAuthExtraData(
            amount: 0,
            currencyCode: AppState.current.currency!,
            orderId: clientSession.order?.id ?? "",
            customer: threeDSCustomer,
            billingAddress: threeDSAddress,
            shippingAddress: nil,
            customerAccount: nil)
    }
    
    var primer3DS: Primer3DS?
    
    // swiftlint:disable function_body_length
    func perform3DS(
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        beginAuthExtraData: ThreeDS.BeginAuthExtraData? = nil,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<(PaymentMethodToken, ThreeDS.PostAuthResponse?), Error>) -> Void
    ) {
        let state = AppState.current
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let env = Environment(rawValue: decodedClientToken.env ?? "")
        
        guard let apiConfiguration = state.apiConfiguration else {
            let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let licenseKey = apiConfiguration.keys?.netceteraLicenseKey else {
            let err = PrimerError.invalid3DSKey(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let cardNetwork = CardNetwork(cardNetworkStr: paymentMethodToken.paymentInstrumentData?.network ?? "")
        
        guard let directoryServerId = cardNetwork.directoryServerId else {
            let err = PrimerError.invalidValue(key: "cardNetwork.directoryServerId", value: cardNetwork.directoryServerId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        switch env {
        case .production:
            primer3DS = Primer3DS(environment: .production)
        case .staging:
            primer3DS = Primer3DS(environment: .staging)
        default:
            primer3DS = Primer3DS(environment: .sandbox)
        }
        
        var certs: [Primer3DSCertificate] = []
        for certificate in apiConfiguration.keys?.threeDSecureIoCertificates ?? [] {
            let cer = ThreeDS.Cer(cardScheme: certificate.cardNetwork, rootCertificate: certificate.rootCertificate, encryptionKey: certificate.encryptionKey)
            certs.append(cer)
        }
        
        var data: Primer3DSSDKGeneratedAuthData!
        
        do {
            let cardNetwork = CardNetwork(cardNetworkStr: paymentMethodToken.paymentInstrumentData?.network ?? "")

            try primer3DS!.initializeSDK(licenseKey: licenseKey, certificates: certs)
            data = try primer3DS!.createTransaction(directoryServerId: directoryServerId, protocolVersion: protocolVersion.rawValue)
        } catch {
            ErrorHandler.shared.handle(error: error)
            completion(.failure(error))
            return
        }
        
        let threeDSecureAuthData = ThreeDS.SDKAuthData(sdkAppId: data.sdkAppId,
                                                       sdkTransactionId: data.sdkTransactionId,
                                                       sdkTimeout: data.sdkTimeout,
                                                       sdkEncData: data.sdkEncData,
                                                       sdkEphemPubKey: data.sdkEphemPubKey,
                                                       sdkReferenceNumber: data.sdkReferenceNumber)
        
        var threeDSecureBeginAuthRequest = ThreeDS.BeginAuthRequest(maxProtocolVersion: env == .production ? .v1 : .v2,
                                                                    challengePreference: .requestedByRequestor,
                                                                    device: threeDSecureAuthData,
                                                                    amount: nil,
                                                                    currencyCode: nil,
                                                                    orderId: nil,
                                                                    customer: nil,
                                                                    billingAddress: nil,
                                                                    shippingAddress: nil,
                                                                    customerAccount: nil)
        
        do {
            try ThreeDSService.validate3DSParameters()
        } catch {
            ErrorHandler.shared.handle(error: error)
            completion(.failure(error))
            return
        }
        
        let customer = AppState.current.apiConfiguration!.clientSession!.customer!
        
        let threeDSCustomer = ThreeDS.Customer(name: "\(customer.firstName) \(customer.lastName)",
                                        email: customer.emailAddress!,
                                        homePhone: nil,
                                        mobilePhone: customer.mobileNumber,
                                        workPhone: nil)
        
        let threeDSAddress = ThreeDS.Address(title: nil,
                                             firstName: customer.firstName,
                                             lastName: customer.lastName,
                                             email: customer.emailAddress,
                                             phoneNumber: customer.mobileNumber,
                                             addressLine1: customer.billingAddress!.addressLine1!,
                                             addressLine2: customer.billingAddress!.addressLine2,
                                             addressLine3: nil,
                                             city: customer.billingAddress!.city!,
                                             state: nil,
                                             countryCode: CountryCode(rawValue: customer.billingAddress!.countryCode!.rawValue)!,
                                             postalCode: customer.billingAddress!.postalCode!)
        
        threeDSecureBeginAuthRequest.amount = AppState.current.amount
        threeDSecureBeginAuthRequest.currencyCode = AppState.current.currency
        threeDSecureBeginAuthRequest.orderId = AppState.current.apiConfiguration?.clientSession?.order?.id
        threeDSecureBeginAuthRequest.customer = threeDSCustomer
        threeDSecureBeginAuthRequest.billingAddress = threeDSAddress
        
        firstly {
            self.beginRemoteAuth(paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
        }
        .done { beginAuthResponse in
            switch beginAuthResponse.authentication.responseCode {
            case .authSuccess:
                // Frictionless pass
                // Frictionless attempt
                completion(.success((beginAuthResponse.token, nil)))
                return
            case .notPerformed:
                // Not enough data to perform 3DS. Won't be returned.
                break
            case .skipped:
                // Skipped because of a technical failure.
                completion(.success((beginAuthResponse.token, nil)))
                return
            case .authFailed:
                // Frictionless fail
                // Frictionless not authenticated
                completion(.success((beginAuthResponse.token, nil)))
                return
            case .challenge:
                // Continue to present the challenge
                break
            case .METHOD:
                // Only applies on the web
                break
            }
            
            if #available(iOS 13.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.filter({ $0.activationState == .foregroundActive }).first as? UIWindowScene {
                    self.threeDSSDKWindow = UIWindow(windowScene: windowScene)
                } else {
                    // Not opted-in in UISceneDelegate
                    self.threeDSSDKWindow = UIWindow(frame: UIScreen.main.bounds)
                }
            } else {
                // Fallback on earlier versions
                self.threeDSSDKWindow = UIWindow(frame: UIScreen.main.bounds)
            }

            self.threeDSSDKWindow!.rootViewController = ClearViewController()
            self.threeDSSDKWindow!.backgroundColor = UIColor.clear
            self.threeDSSDKWindow!.windowLevel = UIWindow.Level.normal
            self.threeDSSDKWindow!.makeKeyAndVisible()
            
            let serverAuthData = ThreeDS.ServerAuthData(acsReferenceNumber: beginAuthResponse.authentication.acsReferenceNumber,
                                             acsSignedContent: beginAuthResponse.authentication.acsSignedContent,
                                             acsTransactionId: beginAuthResponse.authentication.acsTransactionId,
                                             responseCode: beginAuthResponse.authentication.responseCode.rawValue,
                                             transactionId: beginAuthResponse.authentication.transactionId)
            
            firstly {
                self.performChallenge(with: serverAuthData, urlScheme: nil, presentOn: self.threeDSSDKWindow!.rootViewController!)
            }
            .then { primer3DSCompletion -> Promise<ThreeDS.PostAuthResponse> in
                self.continueRemoteAuth(threeDSTokenId: paymentMethodToken.token!)
            }
            .done { postAuthResponse in
                completion(.success((postAuthResponse.token, postAuthResponse)))
            }
            .ensure {
                self.threeDSSDKWindow?.isHidden = true
                self.threeDSSDKWindow = nil
            }
            .catch { err in
                let token = paymentMethodToken
                token.threeDSecureAuthentication = ThreeDS.AuthenticationDetails(responseCode: .skipped, reasonCode: "CLIENT_ERROR", reasonText: err.localizedDescription, protocolVersion: ThreeDS.ProtocolVersion.v2.rawValue, challengeIssued: true)
                completion(.success((token, nil)))
            }
            
        }
        .catch { err in
            let token = paymentMethodToken
            token.threeDSecureAuthentication = ThreeDS.AuthenticationDetails(responseCode: .skipped, reasonCode: "CLIENT_ERROR", reasonText: err.localizedDescription, protocolVersion: ThreeDS.ProtocolVersion.v2.rawValue, challengeIssued: false)
            completion(.success((token, nil)))
            self.threeDSSDKWindow?.isHidden = true
            self.threeDSSDKWindow = nil
        }
    }
    
    func performChallenge(with threeDSecureAuthResponse: Primer3DSServerAuthData, urlScheme: String?, presentOn viewController: UIViewController) -> Promise<Primer3DSCompletion> {
        return Promise { seal in
            guard let primer3DS = primer3DS else {
                let err = PrimerError.generic(message: "Failed to find Primer3DS", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            primer3DS.performChallenge(with: threeDSecureAuthResponse, urlScheme: urlScheme, presentOn: viewController) { (primer3DSCompletion, err) in
                if let err = err {
                    let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                } else if let primer3DSCompletion = primer3DSCompletion {
                    seal.fulfill(primer3DSCompletion)
                } else {
                    let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
    }
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.begin3DSAuth(clientToken: decodedClientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        })
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.continue3DSAuth(clientToken: decodedClientToken, threeDSTokenId: threeDSTokenId) { result in
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
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        beginAuthExtraData: ThreeDS.BeginAuthExtraData?,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (Result<(PaymentMethodToken, ThreeDS.PostAuthResponse?), Error>) -> Void) {
        
    }
    
    
    var response: Data?
    let throwsError: Bool = false
    var isCalled: Bool = false
    
    init(with response: Data? = nil) {
        self.response = response
    }
    
    func beginRemoteAuth(paymentMethodToken: PaymentMethodToken, threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest, completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.begin3DSAuth(clientToken: decodedClientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: completion)
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.continue3DSAuth(clientToken: decodedClientToken, threeDSTokenId: threeDSTokenId, completion: completion)
    }
}

#endif
#endif

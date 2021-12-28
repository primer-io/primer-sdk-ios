//
//  ThreeDSService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 17/6/21.
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
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !Primer.shared.flow.internalSessionFlow.vaulted && settings.amount == nil {
            let err = PaymentError.invalidAmount(amount: settings.amount)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if settings.currency == nil {
            let err = PaymentError.invalidCurrency(currency: settings.currency?.rawValue)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if settings.orderId == nil {
            let err = PaymentError.invalidValue(key: "orderId", value: settings.orderId)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (settings.customer?.billingAddress?.addressLine1 ?? "").isEmpty {
            let err = PaymentError.invalidValue(key: "settings.customer?.billingAddress?.addressLine1", value: settings.customer?.billingAddress?.addressLine1)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (settings.customer?.billingAddress?.city ?? "").isEmpty {
            let err = PaymentError.invalidValue(key: "settings.customer?.billingAddress?.city", value: settings.customer?.billingAddress?.city)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if settings.customer?.billingAddress?.countryCode == nil {
            let err = PaymentError.invalidValue(key: "settings.customer?.billingAddress?.countryCode", value: settings.customer?.billingAddress?.countryCode)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (settings.customer?.billingAddress?.postalCode ?? "").isEmpty {
            let err = PaymentError.invalidValue(key: "settings.customer?.billingAddress?.postalCode", value: settings.customer?.billingAddress?.postalCode)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (settings.customer?.firstName ?? "").isEmpty {
            let err = PaymentError.invalidValue(key: "settings.customer?.firstName", value: settings.customer?.firstName)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (settings.customer?.lastName ?? "").isEmpty {
            let err = PaymentError.invalidValue(key: "settings.customer?.lastName", value: settings.customer?.lastName)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if (settings.customer?.emailAddress ?? "").isEmpty {
            let err = PaymentError.invalidValue(key: "settings.customer?.emailAddress", value: settings.customer?.emailAddress)
            ErrorHandler.handle(error: err)
            errors.append(err)
        }
        
        if !errors.isEmpty {
            let containerErr = PrimerInternalError.underlyingErrors(errors: errors)
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
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let customer = ThreeDS.Customer(name: "\(settings.customer!.firstName) \(settings.customer!.lastName)",
                                        email: settings.customer!.emailAddress!,
                                        homePhone: nil,
                                        mobilePhone: settings.customer!.mobilePhoneNumber,
                                        workPhone: nil)
        
        let threeDSAddress = ThreeDS.Address(title: nil,
                                             firstName: settings.customer!.firstName,
                                             lastName: settings.customer!.lastName,
                                             email: settings.customer!.emailAddress,
                                             phoneNumber: settings.customer!.mobilePhoneNumber,
                                             addressLine1: settings.customer!.billingAddress!.addressLine1!,
                                             addressLine2: settings.customer!.billingAddress!.addressLine2,
                                             addressLine3: nil,
                                             city: settings.customer!.billingAddress!.city!,
                                             state: nil,
                                             countryCode: CountryCode(rawValue: settings.customer!.billingAddress!.countryCode!)!,
                                             postalCode: settings.customer!.billingAddress!.postalCode!)
        
        return ThreeDS.BeginAuthExtraData(
            amount: 0,
            currencyCode: settings.currency!,
            orderId: settings.orderId ?? "",
            customer: customer,
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let env = Environment(rawValue: decodedClientToken.env ?? "")
        
        guard let primerConfiguration = state.primerConfiguration else {
            let err = PrimerInternalError.missingPrimerConfiguration
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let licenseKey = primerConfiguration.keys?.netceteraLicenseKey else {
            let err = PaymentError.invalid3DSKey
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let cardNetwork = CardNetwork(cardNetworkStr: paymentMethodToken.paymentInstrumentData?.network ?? "")
        
        guard let directoryServerId = cardNetwork.directoryServerId else {
            let err = PaymentError.invalidValue(key: "cardNetwork.directoryServerId", value: cardNetwork.directoryServerId)
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
        for certificate in primerConfiguration.keys?.threeDSecureIoCertificates ?? [] {
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
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let customer = ThreeDS.Customer(name: "\(settings.customer!.firstName) \(settings.customer!.lastName)",
                                        email: settings.customer!.emailAddress!,
                                        homePhone: nil,
                                        mobilePhone: settings.customer!.mobilePhoneNumber,
                                        workPhone: nil)
        
        let threeDSAddress = ThreeDS.Address(title: nil,
                                             firstName: settings.customer!.firstName,
                                             lastName: settings.customer!.lastName,
                                             email: settings.customer!.emailAddress,
                                             phoneNumber: settings.customer!.mobilePhoneNumber,
                                             addressLine1: settings.customer!.billingAddress!.addressLine1!,
                                             addressLine2: settings.customer!.billingAddress!.addressLine2,
                                             addressLine3: nil,
                                             city: settings.customer!.billingAddress!.city!,
                                             state: nil,
                                             countryCode: CountryCode(rawValue: settings.customer!.billingAddress!.countryCode!)!,
                                             postalCode: settings.customer!.billingAddress!.postalCode!)
        
        threeDSecureBeginAuthRequest.amount = settings.amount
        threeDSecureBeginAuthRequest.currencyCode = settings.currency
        threeDSecureBeginAuthRequest.orderId = settings.orderId
        threeDSecureBeginAuthRequest.customer = customer
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
                self.continueRemoteAuth(threeDSTokenId: paymentMethodToken.token)
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
                let err = PrimerInternalError.generic(message: "Failed to find Primer3DS", userInfo: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            primer3DS.performChallenge(with: threeDSecureAuthResponse, urlScheme: urlScheme, presentOn: viewController) { (primer3DSCompletion, err) in
                if let err = err {
                    let containerErr = PaymentError.failedToPerform3DS(error: err)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                } else if let primer3DSCompletion = primer3DSCompletion {
                    seal.fulfill(primer3DSCompletion)
                } else {
                    let err = PaymentError.failedToPerform3DS(error: nil)
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
            let err = PrimerInternalError.invalidClientToken
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.threeDSBeginAuth(clientToken: decodedClientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
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
            let err = PrimerInternalError.invalidClientToken
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.threeDSContinueAuth(clientToken: decodedClientToken, threeDSTokenId: threeDSTokenId) { result in
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
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerInternalError.invalidClientToken
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.threeDSBeginAuth(clientToken: decodedClientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: completion)
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.threeDSContinueAuth(clientToken: decodedClientToken, threeDSTokenId: threeDSTokenId, completion: completion)
    }
}

#endif
#endif

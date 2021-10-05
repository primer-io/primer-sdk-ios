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
        
        if (settings.customer?.billingAddress?.addressLine1 ?? "").isEmpty {
            errors.append(PrimerError.userDetailsAddressLine1Missing)
        }
        
        if (settings.customer?.billingAddress?.city ?? "").isEmpty {
            errors.append(PrimerError.userDetailsCityMissing)
        }
        
        if settings.customer?.billingAddress?.countryCode == nil {
            errors.append(PrimerError.userDetailsCountryCodeMissing)
        } else if CountryCode(rawValue: settings.customer!.billingAddress!.countryCode!.rawValue) == nil {
            errors.append(PrimerError.userDetailsCountryCodeMissing)
        }
        
        if (settings.customer?.billingAddress?.postalCode ?? "").isEmpty {
            errors.append(PrimerError.userDetailsCountryCodeMissing)
        }
        
        if (settings.customer?.firstName ?? "").isEmpty ||
            (settings.customer?.lastName ?? "").isEmpty ||
            (settings.customer?.emailAddress ?? "").isEmpty
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
    
    static func buildBeginAuthExtraData() throws -> ThreeDS.BeginAuthExtraData {
        do {
            try ThreeDSService.validate3DSParameters()
        } catch {
            throw error
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let customer = ThreeDS.Customer(name: "\(settings.customer!.firstName) \(settings.customer!.lastName)",
                                        email: settings.customer!.emailAddress!,
                                        homePhone: nil,
                                        mobilePhone: settings.customer!.mobileNumber,
                                        workPhone: nil)
        
        let threeDSAddress = ThreeDS.Address(title: nil,
                                             firstName: settings.customer!.firstName,
                                             lastName: settings.customer!.lastName,
                                             email: settings.customer!.emailAddress,
                                             phoneNumber: settings.customer!.mobileNumber,
                                             addressLine1: settings.customer!.billingAddress!.addressLine1!,
                                             addressLine2: settings.customer!.billingAddress!.addressLine2,
                                             addressLine3: nil,
                                             city: settings.customer!.billingAddress!.city!,
                                             state: nil,
                                             countryCode: CountryCode(rawValue: settings.customer!.billingAddress!.countryCode!.rawValue)!,
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
        
        guard let decodedClientToken = state.decodedClientToken else {
            completion(.failure(PrimerError.clientTokenNull))
            return
        }
        
        let env = Environment(rawValue: decodedClientToken.env ?? "")
        
        guard let paymentMethodConfig = state.paymentMethodConfig else {
            completion(.failure(PrimerError.configFetchFailed))
            return
        }
        
        guard let licenseKey = paymentMethodConfig.keys?.netceteraLicenseKey else {
            completion(.failure(PrimerError.threeDSSDKKeyMissing))
            return
        }
        
        let cardNetwork = CardNetwork(cardNetworkStr: paymentMethodToken.paymentInstrumentData?.network ?? "")
        
        guard let directoryServerId = cardNetwork.directoryServerId else {
            completion(.failure(PrimerError.dataMissing(description: "Failed to find directoryServerId for selected payment method")))
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
        for certificate in paymentMethodConfig.keys?.threeDSecureIoCertificates ?? [] {
            let cer = ThreeDS.Cer(cardScheme: certificate.cardNetwork, rootCertificate: certificate.rootCertificate, encryptionKey: certificate.encryptionKey)
            certs.append(cer)
        }
        
        var data: Primer3DSSDKGeneratedAuthData!
        
        do {
            let cardNetwork = CardNetwork(cardNetworkStr: paymentMethodToken.paymentInstrumentData?.network ?? "")

            try primer3DS!.initializeSDK(licenseKey: licenseKey, certificates: certs)
            data = try primer3DS!.createTransaction(directoryServerId: directoryServerId, protocolVersion: protocolVersion.rawValue)
        } catch {
            completion(.failure(PrimerError.threeDSSDKKeyMissing))
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
        
        if let beginAuthExtraData = beginAuthExtraData {
            do {
                try ThreeDSService.validate3DSParameters()
            } catch {
                completion(.failure(error))
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            let customer = ThreeDS.Customer(name: "\(settings.customer!.firstName) \(settings.customer!.lastName)",
                                            email: settings.customer!.emailAddress!,
                                            homePhone: nil,
                                            mobilePhone: settings.customer!.mobileNumber,
                                            workPhone: nil)
            
            let threeDSAddress = ThreeDS.Address(title: nil,
                                                 firstName: settings.customer!.firstName,
                                                 lastName: settings.customer!.lastName,
                                                 email: settings.customer!.emailAddress,
                                                 phoneNumber: settings.customer!.mobileNumber,
                                                 addressLine1: settings.customer!.billingAddress!.addressLine1!,
                                                 addressLine2: settings.customer!.billingAddress!.addressLine2,
                                                 addressLine3: nil,
                                                 city: settings.customer!.billingAddress!.city!,
                                                 state: nil,
                                                 countryCode: CountryCode(rawValue: settings.customer!.billingAddress!.countryCode!.rawValue)!,
                                                 postalCode: settings.customer!.billingAddress!.postalCode!)
            
            threeDSecureBeginAuthRequest.amount = beginAuthExtraData.amount
            threeDSecureBeginAuthRequest.currencyCode = beginAuthExtraData.currencyCode
            threeDSecureBeginAuthRequest.orderId = beginAuthExtraData.orderId
            threeDSecureBeginAuthRequest.customer = beginAuthExtraData.customer
            threeDSecureBeginAuthRequest.billingAddress = beginAuthExtraData.billingAddress
            threeDSecureBeginAuthRequest.shippingAddress = beginAuthExtraData.shippingAddress
            threeDSecureBeginAuthRequest.customerAccount = beginAuthExtraData.customerAccount
        }
        
        
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
            
            self.threeDSSDKWindow = UIWindow(frame: UIScreen.main.bounds)
            self.threeDSSDKWindow?.rootViewController = ClearViewController()
            self.threeDSSDKWindow?.backgroundColor = UIColor.clear
            self.threeDSSDKWindow?.windowLevel = UIWindow.Level.normal
            self.threeDSSDKWindow?.makeKeyAndVisible()
            
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
                seal.reject(PrimerError.generic)
                return
            }
            
            primer3DS.performChallenge(with: threeDSecureAuthResponse, urlScheme: urlScheme, presentOn: viewController) { (primer3DSCompletion, err) in
                if let err = err {
                    seal.reject(err)
                } else if let primer3DSCompletion = primer3DSCompletion {
                    seal.fulfill(primer3DSCompletion)
                } else {
                    seal.reject(PrimerError.generic)
                }
            }
        }
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(PrimerError.vaultFetchFailed))
        }
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        api.response = response
        
        api.threeDSBeginAuth(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: completion)
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

#endif
#endif

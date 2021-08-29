//
//  ThreeDSService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 17/6/21.
//

#if canImport(Primer3DS)
#if canImport(ThreeDS_SDK)
import Foundation
import Primer3DS
import ThreeDS_SDK

protocol ThreeDSServiceProtocol {
    func perform3DS(
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void
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
    
    var primer3DS: Primer3DS?
    
    // swiftlint:disable function_body_length
    func perform3DS(
        paymentMethodToken: PaymentMethodToken,
        protocolVersion: ThreeDS.ProtocolVersion,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<PaymentMethodToken, Error>) -> Void
    ) {
        do {
            try ThreeDSService.validate3DSParameters()
        } catch {
            completion(.failure(error))
            return
        }
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = state.decodedClientToken else {
            completion(.failure(PrimerError.clientTokenNull))
            return
        }
        
        guard let env = Environment(rawValue: decodedClientToken.env ?? "") else {
            completion(.failure(PrimerError.dataMissing(description: "Failed to find environment in client token")))
            return
        }
        
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
        case .sandbox,
             .local:
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
        
        let threeDSecureAuthData = ThreeDS.SDKAuthData(sdkAppId: data.sdkAppId,
                                                       sdkTransactionId: data.sdkTransactionId,
                                                       sdkTimeout: data.sdkTimeout,
                                                       sdkEncData: data.sdkEncData,
                                                       sdkEphemPubKey: data.sdkEphemPubKey,
                                                       sdkReferenceNumber: data.sdkReferenceNumber)
        
        let threeDSecureBeginAuthRequest = ThreeDS.BeginAuthRequest(testScenario: nil,
                                                                    maxProtocolVersion: env == .production ? .v1 : .v2,
                                                                    amount: settings.amount ?? 0,
                                                                    challengePreference: .requestedByRequestor,
                                                                    currencyCode: settings.currency!,
                                                                    orderId: settings.orderId ?? "",
                                                                    customer: customer,
                                                                    device: threeDSecureAuthData,
                                                                    billingAddress: threeDSAddress,
                                                                    shippingAddress: nil,
                                                                    customerAccount: nil)
    
        
        
        firstly {
            self.beginRemoteAuth(paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
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
                completion(.success(postAuthResponse.token))
            }
            .ensure {
                self.threeDSSDKWindow?.isHidden = true
                self.threeDSSDKWindow = nil
            }
            .catch { err in
                var token = paymentMethodToken
                token.threeDSecureAuthentication = ThreeDS.AuthenticationDetails(responseCode: .skipped, reasonCode: "CLIENT_ERROR", reasonText: err.localizedDescription, protocolVersion: ThreeDS.ProtocolVersion.v2.rawValue, challengeIssued: true)
                completion(.success(token))
            }
            
        }
//        .ensure {
//            self.threeDSSDKWindow?.isHidden = true
//            self.threeDSSDKWindow = nil
//        }
        .catch { err in
            var token = paymentMethodToken
            token.threeDSecureAuthentication = ThreeDS.AuthenticationDetails(responseCode: .skipped, reasonCode: "CLIENT_ERROR", reasonText: err.localizedDescription, protocolVersion: ThreeDS.ProtocolVersion.v2.rawValue, challengeIssued: false)
            completion(.success(token))
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

#endif
#endif

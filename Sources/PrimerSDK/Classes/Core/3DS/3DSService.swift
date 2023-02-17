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
    
    static var apiClient: PrimerAPIClientProtocol? { get set }
    
    func perform3DS(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        protocolVersion: ThreeDS.ProtocolVersion,
        beginAuthExtraData: ThreeDS.BeginAuthExtraData?,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<String, Error>) -> Void
    )
    
    func beginRemoteAuth(paymentMethodTokenData: PrimerPaymentMethodTokenData,
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
    static var apiClient: PrimerAPIClientProtocol?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    var primer3DS: Primer3DS?
    
    // swiftlint:disable function_body_length
    func perform3DS(
        paymentMethodTokenData: PrimerPaymentMethodTokenData,
        protocolVersion: ThreeDS.ProtocolVersion,
        beginAuthExtraData: ThreeDS.BeginAuthExtraData? = nil,
        sdkDismissed: (() -> Void)?,
        completion: @escaping (_ result: Result<String, Error>) -> Void
    ) {
        let state = AppState.current
        
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let env = Environment(rawValue: decodedJWTToken.env ?? "")
        
        guard let apiConfiguration = state.apiConfiguration else {
            let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let licenseKey = apiConfiguration.keys?.netceteraLicenseKey else {
            let err = PrimerError.invalid3DSKey(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let cardNetwork = CardNetwork(cardNetworkStr: paymentMethodTokenData.paymentInstrumentData?.binData?.network ?? "")
        
        guard let directoryServerId = cardNetwork.directoryServerId else {
            let err = PrimerError.invalidValue(key: "cardNetwork.directoryServerId", value: cardNetwork.directoryServerId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
        
        var isMockedBE = false
#if DEBUG
        if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
            isMockedBE = true
        }
#endif
        
        do {
            let cardNetwork = CardNetwork(cardNetworkStr: paymentMethodTokenData.paymentInstrumentData?.binData?.network ?? "")
            
            if !isMockedBE {
                try primer3DS!.initializeSDK(licenseKey: licenseKey, certificates: certs)
                data = try primer3DS!.createTransaction(directoryServerId: directoryServerId, protocolVersion: protocolVersion.rawValue)
            } else {
                let vc = PrimerDemo3DSViewController()
                PrimerUIManager.primerRootViewController?.present(vc, animated: true)
                
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
                    vc.dismiss(animated: true) {
                        completion(.success("resume_token"))
                        timer.invalidate()
                    }
                }
                
                return
            }
            
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
        
        let threeDSecureBeginAuthRequest = ThreeDS.BeginAuthRequest(maxProtocolVersion: env == .production ? .v1 : .v2,
                                                                    challengePreference: .requestedByRequestor,
                                                                    device: threeDSecureAuthData,
                                                                    amount: nil,
                                                                    currencyCode: nil,
                                                                    orderId: nil,
                                                                    customer: nil,
                                                                    billingAddress: nil,
                                                                    shippingAddress: nil,
                                                                    customerAccount: nil)
        
        firstly {
            self.beginRemoteAuth(paymentMethodTokenData: paymentMethodTokenData, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest)
        }
        .done { beginAuthResponse in
            switch beginAuthResponse.authentication.responseCode {
            case .authSuccess:
                // Frictionless pass or frictionless attempt
                guard let resumeToken = beginAuthResponse.resumeToken else {
                    let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    completion(.failure(err))
                    return
                }
                
                completion(.success(resumeToken))
                return
                
            case .notPerformed:
                // Not enough data to perform 3DS. Won't be returned.
                guard let resumeToken = beginAuthResponse.resumeToken else {
                    let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    completion(.failure(err))
                    return
                }
                
                completion(.success(resumeToken))
                return
                
            case .skipped:
                // Skipped because of a technical failure.
                guard let resumeToken = beginAuthResponse.resumeToken else {
                    let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    completion(.failure(err))
                    return
                }
                
                completion(.success(resumeToken))
                return
                
            case .authFailed:
                // Frictionless fail or frictionless not authenticated
                guard let resumeToken = beginAuthResponse.resumeToken else {
                    let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    completion(.failure(err))
                    return
                }
                
                completion(.success(resumeToken))
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
            
            let present3DSUIEvent = Analytics.Event(
                eventType: .ui,
                properties: UIEventProperties(
                    action: Analytics.Event.Property.Action.present,
                    objectType: .thirdPartyView,
                    place: .threeDSScreen))
            Analytics.Service.record(events: [present3DSUIEvent])
            
            firstly {
                self.performChallenge(with: serverAuthData, urlScheme: nil, presentOn: self.threeDSSDKWindow!.rootViewController!)
            }
            .then { primer3DSCompletion -> Promise<ThreeDS.PostAuthResponse> in
                self.continueRemoteAuth(threeDSTokenId: paymentMethodTokenData.token!)
            }
            .done { postAuthResponse in
                guard let resumeToken = beginAuthResponse.resumeToken else {
                    let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    completion(.failure(err))
                    return
                }
                
                completion(.success(resumeToken))

            }
            .ensure {
                let dismiss3DSUIEvent = Analytics.Event(
                    eventType: .ui,
                    properties: UIEventProperties(
                        action: Analytics.Event.Property.Action.dismiss,
                        objectType: .thirdPartyView,
                        place: .threeDSScreen))
                Analytics.Service.record(events: [dismiss3DSUIEvent])
                
                self.threeDSSDKWindow?.isHidden = true
                self.threeDSSDKWindow = nil
            }
            .catch { err in
                completion(.failure(err))
            }
            
        }
        .catch { err in
            completion(.failure(err))
        }
    }
    
    func performChallenge(with threeDSecureAuthResponse: Primer3DSServerAuthData, urlScheme: String?, presentOn viewController: UIViewController) -> Promise<Primer3DSCompletion> {
        return Promise { seal in
            guard let primer3DS = primer3DS else {
                let err = PrimerError.generic(message: "Failed to find Primer3DS", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            primer3DS.performChallenge(with: threeDSecureAuthResponse, urlScheme: urlScheme, presentOn: viewController) { (primer3DSCompletion, err) in
                if let err = err {
                    var containerErr: PrimerError
                    let isCanceledError = (err as NSError).code == -4
                    if isCanceledError {
                        containerErr = PrimerError.cancelled(paymentMethodType: "3DS", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    } else {
                        containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    }
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                } else if let primer3DSCompletion = primer3DSCompletion {
                    seal.fulfill(primer3DSCompletion)
                } else {
                    let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                }
            }
        }
    }
    
    func beginRemoteAuth(paymentMethodTokenData: PrimerPaymentMethodTokenData,
                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                         completion: @escaping (Result<ThreeDS.BeginAuthResponse, Error>) -> Void) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = ThreeDSService.apiClient ?? PrimerAPIClient()
        apiClient.begin3DSAuth(clientToken: decodedJWTToken, paymentMethodTokenData: paymentMethodTokenData, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        })
    }
    
    func continueRemoteAuth(threeDSTokenId: String, completion: @escaping (Result<ThreeDS.PostAuthResponse, Error>) -> Void) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = ThreeDSService.apiClient ?? PrimerAPIClient()
        apiClient.continue3DSAuth(clientToken: decodedJWTToken, threeDSTokenId: threeDSTokenId) { result in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let res):
                completion(.success(res))
            }
        }
    }
    
}

#endif
#endif

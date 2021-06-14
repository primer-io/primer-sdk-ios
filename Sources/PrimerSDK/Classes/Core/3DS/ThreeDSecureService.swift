//
//  ThreeDService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 1/4/21.
//

#if canImport(UIKit)

import Foundation
import ThreeDS_SDK

protocol ThreeDSecureServiceProtocol {
    func threeDSecureBeginAuthentication(paymentMethodToken: PaymentMethodToken,
                                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                                         completion: @escaping (ThreeDS.BeginAuthResponse?, Error?) -> Void)
}

class ThreeDSecureService: ThreeDSecureServiceProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var api: PrimerAPIClientProtocol
    
    let threeDS2Service: ThreeDS_SDK.ThreeDS2Service = ThreeDS2ServiceSDK(bundle: Bundle.primerFramework)
    private var transaction: Transaction?
    private var netceteraCompletion: ((_ netceteraThreeDSCompletion: ThreeDS.NetceteraThreeDSCompletion?, _ err: Error?) -> Void)?
    
    deinit {
        print("ThreeDSecureServiceProtocol deinit")
    }
    
    func initializeSDK(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let configBuilder = ConfigurationBuilder()
            try configBuilder.log(to: .debug)
            try configBuilder.license(key: Primer.netceteraLicenseKey)
            
            let supportedSchemeIds: [String] = ["A999999999"]
                         
            let scheme = Scheme(name: "scheme_name")
            scheme.ids = supportedSchemeIds
            scheme.encryptionKeyValue = Certificates.cer1
            scheme.rootCertificateValue = Certificates.cer3
            scheme.logoImageName = "visa"
            
            try configBuilder.add(scheme)
             
            let configParameters = configBuilder.configParameters()
            
            try threeDS2Service.initialize(configParameters,
                                           locale: nil,
                                           uiCustomization: nil)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func verifyWarnings(completion: @escaping (Result<Void, Error>) -> Void) {
        var sdkWarnings: [Warning] = []
        do {
            sdkWarnings = try threeDS2Service.getWarnings()
        } catch {
            completion(.success(()))
            return
        }
        
        if !sdkWarnings.isEmpty {
            var message = ""
            for warning in sdkWarnings {
                message += warning.getMessage()
                message += "\n"
            }
            
            #if DEBUG
            completion(.success(()))
            #else
            let err = NSError(domain: "netcetera", code: 100, userInfo: [NSLocalizedDescriptionKey: message])
            completion(.failure(err))
            #endif
        } else {
            completion(.success(()))
        }
    }
    
    func netceteraAuth(paymentMethod: PaymentMethodToken, protocolVersion: ThreeDS.ProtocolVersion, completion: @escaping (Result<Transaction, Error>) -> Void) {
        do {
            var directoryServerId: String
            
            switch paymentMethod.paymentInstrumentData?.network?.lowercased() {
            case "visa":
                directoryServerId = ThreeDS.directoryServerIdFor(scheme: .visa())
            case "mastercard":
                directoryServerId = ThreeDS.directoryServerIdFor(scheme: .mastercard())
            case "diners":
                directoryServerId = ThreeDS.directoryServerIdFor(scheme: .diners())
            case "jcb":
                directoryServerId = ThreeDS.directoryServerIdFor(scheme: .jcb())
            case "amex":
                directoryServerId = ThreeDS.directoryServerIdFor(scheme: .amex())
            case "union":
                directoryServerId = ThreeDS.directoryServerIdFor(scheme: .union())
            default:
                directoryServerId = "A999999999"
            }

            transaction = try threeDS2Service.createTransaction(directoryServerId: directoryServerId,
                                                                messageVersion: protocolVersion.rawValue)
            completion(.success(transaction!))
        } catch {
            print(error)
            completion(.failure(error))
        }
        
    }
    
    func performChallenge(on transaction: Transaction, with threeDSecureAuthResponse: ThreeDSAuthenticationProtocol, presentOn viewController: UIViewController, completion: @escaping (Result<ThreeDS.NetceteraThreeDSCompletion, Error>) -> Void) {
        self.transaction = transaction
        
        let challengeParameters = ChallengeParameters(
            threeDSServerTransactionID: threeDSecureAuthResponse.transactionId,
            acsTransactionID: threeDSecureAuthResponse.acsTransactionId,
            acsRefNumber: threeDSecureAuthResponse.acsReferenceNumber,
            acsSignedContent: threeDSecureAuthResponse.acsSignedContent)
        
        netceteraCompletion = { [weak self] (netceteraThreeDSCompletion, err) in
            if let err = err {
                completion(.failure(err))
            } else if let netceteraThreeDSCompletion = netceteraThreeDSCompletion {
                completion(.success(netceteraThreeDSCompletion))
            } else {
                // Will never get in here! Assert an error.
            }
            
            self?.netceteraCompletion = nil
        }
        
        do {
            try transaction.doChallenge(challengeParameters: challengeParameters,
                                        challengeStatusReceiver: self,
                                        timeOut: 60,
                                        inViewController: viewController)
            
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func threeDSecureBeginAuthentication(paymentMethodToken: PaymentMethodToken,
                                         threeDSecureBeginAuthRequest: ThreeDS.BeginAuthRequest,
                                         completion: @escaping (ThreeDS.BeginAuthResponse?, Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(nil, PrimerError.vaultFetchFailed)
        }
        
        api.threeDSecureBeginAuthentication(clientToken: clientToken, paymentMethodToken: paymentMethodToken, threeDSecureBeginAuthRequest: threeDSecureBeginAuthRequest, completion: { result in
            switch result {
            case .failure:
                completion(nil, PrimerError.clientTokenNull)
            case .success(let res):
                print(res)
                completion(res, nil)
            }
        })
    }
}

extension ThreeDSecureService: ChallengeStatusReceiver {
    func completed(completionEvent: CompletionEvent) {
        let sdkTransactionId = completionEvent.getSDKTransactionID()
        let authenticationStatus = ThreeDS.AuthenticationStatus(rawValue: completionEvent.getTransactionStatus())
        let netceteraThreeDSCompletion = ThreeDS.NetceteraThreeDSCompletion(sdkTransactionId: sdkTransactionId, transactionStatus: authenticationStatus)
        netceteraCompletion?(netceteraThreeDSCompletion, nil)
    }
    
    func cancelled() {
        let err = NSError(domain: "netcetera", code: -4, userInfo: [NSLocalizedDescriptionKey: "3DS canceled"])
        ErrorHandler.shared.handle(error: err)
        netceteraCompletion?(nil, err)
    }
    
    func timedout() {
        let err = NSError(domain: "netcetera", code: -3, userInfo: [NSLocalizedDescriptionKey: "3DS timed out"])
        ErrorHandler.shared.handle(error: err)
        netceteraCompletion?(nil, err)
    }
    
    func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        let userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: protocolErrorEvent.getErrorMessage(),
            "sdkTransactionId": protocolErrorEvent.getSDKTransactionID()
        ]
        
        let err = NSError(domain: "netcetera", code: -1, userInfo: userInfo)
        ErrorHandler.shared.handle(error: err)
        netceteraCompletion?(nil, err)
    }
    
    func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        let err = NSError(domain: "netcetera", code: Int(runtimeErrorEvent.getErrorCode() ?? "-2") ?? -2, userInfo: [NSLocalizedDescriptionKey: runtimeErrorEvent.getErrorMessage()])
        ErrorHandler.shared.handle(error: err)
        netceteraCompletion?(nil, err)
    }
}

#endif


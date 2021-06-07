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
            
            let err = NSError(domain: "netcetera", code: 100, userInfo: [NSLocalizedDescriptionKey: message])
//            completion(.failure(err))
            completion(.success(()))
        } else {
            completion(.success(()))
        }
    }
    
    func netceteraAuth(paymentMethod: PaymentMethodToken, completion: @escaping (Result<Transaction, Error>) -> Void) {
        do {
//            var scheme: Scheme!
//            switch paymentMethod.paymentInstrumentData?.binData?.network?.lowercased() {
//            case "visa":
//                scheme = .visa()
//            default:
//                let err = NSError(domain: "netcetera", code: 100, userInfo: [NSLocalizedDescriptionKey: "Only Visa for now"])
//                completion(.failure(err))
//                return
//
//            }
//
//            let directoryServerId = ThreeDSecureService.directoryServerIdFor(scheme: scheme)
            transaction = try threeDS2Service.createTransaction(directoryServerId: "A999999999",
                                                                    messageVersion: "2.1.0")
            completion(.success(transaction!))
        } catch {
            print(error)
            completion(.failure(error))
        }
        
    }
    
    func performChallenge(on transaction: Transaction, with threeDSecureAuthResponse: ThreeDSMethodAPIResponse, presentOn viewController: UIViewController, completion: @escaping (Result<ThreeDS.NetceteraThreeDSCompletion, Error>) -> Void) {
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
    
//    func submitButtonTapped() {
//        var progressView: ProgressDialog?
//        var requestSentTime: Date?
//        var directoryServerId: String!
//
//        requestSentTime = Date()
//        do {
//            directoryServerId = "" //try directoryServerIdFor(accountNumber: paymentDetails.accountNumber)
//            let transaction = try self.paymentDetailsUseCase.createTransaction(directoryServerId: directoryServerId)
//            progressView = try self.transaction!.getProgressView()
//            progressView!.start()
//        } catch let error {
//            print(error)
//            self.view?.showErrorScreen(with: "\(error)")
//            return
//        }
//        let authenticatingPromise = paymentDetailsUseCase.sendAuthenticationRequest(transaction: self.transaction!,
//                                                                                    paymentDetails: paymentDetails)
//        authenticatingPromise.done { authenticationResponse in
//            self.handleResponseReceived(requestSentTime: requestSentTime!, {
//                progressView!.stop()
//                self.handleAuthenticationResponse(authenticationResponse, for: self.transaction!)
//            })
//            }.catch { (error) in
//                if let requestSentTime = requestSentTime {
//                    self.handleResponseReceived(requestSentTime: requestSentTime, {
//                        if let progressView = progressView {
//                            progressView.stop()
//                        }
//                        self.view?.showErrorScreen(with: "Transaction failed")
//                    })
//                } else {
//                    self.view?.showErrorScreen(with: "Transaction failed")
//                }
//        }
//    }
    
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
        
        //        api.vaultFetchPaymentMethods(clientToken: clientToken) { [weak self] (result) in
        //            switch result {
        //            case .failure:
        //                completion(PrimerError.vaultFetchFailed)
        //            case .success(let paymentMethods):
        //                self?.state.paymentMethods = paymentMethods.data
        //
        //                guard let paymentMethods = self?.state.paymentMethods else { return }
        //
        //                if self?.state.selectedPaymentMethod.isEmpty == true && paymentMethods.isEmpty == false {
        //                    guard let id = paymentMethods[0].token else { return }
        //                    self?.state.selectedPaymentMethod = id
        //                }
        //
        //                completion(nil)
        //            }
        //        }
    }
}

extension ThreeDSecureService {
    static func directoryServerIdFor(scheme: Scheme) -> String {
        print(DsRidValues.visa)
        return "A000000003"
        switch scheme {
        case .visa():
            print(DsRidValues.visa)
            return DsRidValues.visa
        case .mastercard():
            return DsRidValues.mastercard
        case .amex():
            return DsRidValues.amex
        case .jcb():
            return DsRidValues.jcb
        case .diners():
            return DsRidValues.diners
        case .union():
            return DsRidValues.union
        default:
            return ""
        }
//        let visaRegex = try NSRegularExpression(pattern: "^4[0-9]*", options: [.anchorsMatchLines])
//        if visaRegex.matches(accountNumber) {
//            return DsRidValues.visa
//        }
//
//        let mastercardRegex = try NSRegularExpression(pattern: "^(2[0-1]|220[5-9]|22[1-9]|2[3-9]|5|6)[0-9]*",
//                                                      options: [.anchorsMatchLines])
//        if mastercardRegex.matches(accountNumber) {
//            return DsRidValues.mastercard
//        }
//
//        let amexRegex = try NSRegularExpression(pattern: "^(34|37)[0-9]*", options: [.anchorsMatchLines])
//        if amexRegex.matches(accountNumber) {
//            return DsRidValues.amex
//        }
//
//        let jcbRegex = try NSRegularExpression(pattern: "^35[0-9]*", options: [.anchorsMatchLines])
//        if jcbRegex.matches(accountNumber) {
//            return DsRidValues.jcb
//        }
//
//        let dinersRegex = try NSRegularExpression(pattern: "^36[0-9]*", options: [.anchorsMatchLines])
//        if dinersRegex.matches(accountNumber) {
//            return DsRidValues.diners
//        }
//
//        let mirRegex = try NSRegularExpression(pattern: "^220[0-4][0-9]*", options: [.anchorsMatchLines])
//        if mirRegex.matches(accountNumber) {
//            return "A000000658"
//        }
//
//        let unionRegex = try NSRegularExpression(pattern: "^(62[0-9]{14,17})$", options: [.anchorsMatchLines])
//        if unionRegex.matches(accountNumber) {
//            return DsRidValues.union
//        }
//
//        throw AppError.InvalidCard
    }
}

struct ThreeDSecureAuthData: Codable {
    let sdkAppId: String
    let sdkTransactionId: String
    let sdkTimeout: Int
    let sdkEncData: String
    let sdkEphemPubKey: String
    let sdkReferenceNumber: String
}

extension Transaction {
    func buildThreeDSecureAuthData() throws -> ThreeDSecureAuthData {
        let transactionParameters = try self.getAuthenticationRequestParameters()
        let sdkAppId = transactionParameters.getSDKAppID()
        let sdkTransactionId = transactionParameters.getSDKTransactionId()
//        let sdkMaxTimeout = 10
        let sdkEncData = transactionParameters.getDeviceData()
        let sdkEphemeralKey = transactionParameters.getSDKEphemeralPublicKey()
//        let sdkEphemeralKeyJSON = try! JSONSerialization.jsonObject(with: sdkEphemeralKey.data(using: .utf8)!, options: .allowFragments) as! [String: Any]
        let sdkReferenceNumber = transactionParameters.getSDKReferenceNumber()
        let threeDSecureAuthData = ThreeDSecureAuthData(sdkAppId: sdkAppId, sdkTransactionId: sdkTransactionId, sdkTimeout: 10, sdkEncData: sdkEncData, sdkEphemPubKey: sdkEphemeralKey, sdkReferenceNumber: sdkReferenceNumber)
        return threeDSecureAuthData
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


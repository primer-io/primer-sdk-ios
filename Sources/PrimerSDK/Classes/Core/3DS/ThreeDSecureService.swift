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
                                         threeDSecureBeginAuthRequest: ThreeDSecureBeginAuthRequest,
                                         completion: @escaping (ThreeDSecureBeginAuthResponse?, Error?) -> Void)
}

class ThreeDSecureService: ThreeDSecureServiceProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var api: PrimerAPIClientProtocol
    
    let threeDS2Service: ThreeDS_SDK.ThreeDS2Service = ThreeDS2ServiceSDK()
    
    func initializeSDK(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let configBuilder = ConfigurationBuilder()
            try configBuilder.license(key: Primer.netceteraLicenseKey)
                         
            let scheme = Scheme(name: "scheme_name")
            scheme.ids = ["A999999999"]
            scheme.encryptionKeyValue = "MIIBxTCCAWygAwIBAgIIC86P1uYPsHcwCgYIKoZIzj0EAwIwSTELMAkGA1UEBhMCREsxFDASBgNVBAoTCzNkc2VjdXJlLmlvMSQwIgYDVQQDExszZHNlY3VyZS5pbyBzdGFuZGluIGlzc3VpbmcwIBgPMDAwMTAxMDEwMDAwMDBaFw0zMTA1MTEwNzE3NDlaMEQxCzAJBgNVBAYTAkRLMRQwEgYDVQQKEwszZHNlY3VyZS5pbzEfMB0GA1UEAxMWM2RzZWN1cmUuaW8gc3RhbmRpbiBEUzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABPlvqaJJN/P+cbWlFgkMdPrHHYudaDba3BXjc77p8iAfwQj/zlnB722Xhc6cPod9E9sAQusKFlSPM3apXWco/qSjQTA/MA4GA1UdDwEB/wQEAwIDqDAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFBDbGDMLlWPTHL2yGKAG9C8Vlp3DMAoGCCqGSM49BAMCA0cAMEQCIDcKPmQqXPwBWSV52rWOOIVaChr9otyjEM1uvFZuFCnbAiBq7c00mNkJn8MFBx5u7EEjO6qVGIr+4QUrjjicBlyk+Q=="
            
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
    
    func netceteraAuth(paymentMethod: PaymentMethodToken, completion: @escaping (Result<ThreeDSecureAuthData, Error>) -> Void) {
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
            let transaction = try threeDS2Service.createTransaction(directoryServerId: "A999999999",
                                                                    messageVersion: "2.2.0")
            
            print(transaction)
            let transactionParameters = try transaction.getAuthenticationRequestParameters()
            print(transactionParameters)
            let sdkAppId = transactionParameters.getSDKAppID()
            let sdkTransactionId = transactionParameters.getSDKTransactionId()
            let sdkMaxTimeout = 10
            let sdkEncData = transactionParameters.getDeviceData()
            let sdkEphemeralKey = transactionParameters.getSDKEphemeralPublicKey()
            let sdkEphemeralKeyJSON = try! JSONSerialization.jsonObject(with: sdkEphemeralKey.data(using: .utf8)!, options: .allowFragments) as! [String: Any]
            let sdkReferenceNumber = transactionParameters.getSDKReferenceNumber()
//            print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
//            print("sdkEncData:\n\(sdkEncData)\n\n")
//            print("sdkEphemPubKey-Y:\n\(sdkEphemeralKeyJSON["y"] as! String)\n\n")
//            print("sdkEphemPubKey-X:\n\(sdkEphemeralKeyJSON["x"] as! String)\n\n")
//            print("sdkTransactionId:\n\(sdkTransactionId)\n\n")
            let threeDSecureAuthData = ThreeDSecureAuthData(sdkAppId: sdkAppId, sdkTransactionId: sdkTransactionId, sdkTimeout: 10, sdkEncData: sdkEncData, sdkEphemPubKey: sdkEphemeralKey, sdkReferenceNumber: sdkReferenceNumber)
            print("\n\n\n\n\n\nsdkEncData:\n\(threeDSecureAuthData.sdkEncData)")
            completion(.success(threeDSecureAuthData))
        } catch {
            print(error)
            completion(.failure(error))
        }
        
    }
    
    func performChallenge(on transaction: Transaction, with threeDSecureAuthResponse: ThreeDSecureBeginAuthResponse, presentOn viewController: UIViewController) {
//        let challengeParameters = ChallengeParameters(
//            threeDSServerTransactionID: "",
//            acsTransactionID: threeDSecureAuthResponse.authentication.acs,
//            acsRefNumber: <#T##String?#>,
//            acsSignedContent: <#T##String?#>)
//        do {
//            try transaction.doChallenge(challengeParameters: challengeParameters,
//                                        challengeStatusReceiver: self,
//                                        timeOut:5,
//                                        inViewController: viewController)
//        } catch {
//            // ...
//        }
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
                                         threeDSecureBeginAuthRequest: ThreeDSecureBeginAuthRequest,
                                         completion: @escaping (ThreeDSecureBeginAuthResponse?, Error?) -> Void) {
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

#endif


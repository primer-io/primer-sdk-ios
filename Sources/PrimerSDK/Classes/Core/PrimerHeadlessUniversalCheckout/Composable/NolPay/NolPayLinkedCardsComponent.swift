//
//  NolPayLinkedCardsComponent.swift
//  PrimerSDK
//
//  Created by Boris on 15.9.23..
//

import Foundation
#if canImport(PrimerNolPaySDK)
import PrimerNolPaySDK


public class NolPayLinkedCardsComponent: PrimerHeadlessComponent {
    
    var nolPay: PrimerNolPayProtocol?
    
    public var errorDelegate: PrimerHeadlessErrorableDelegate?
    private var isDebug: Bool

    public init(isDebug: Bool) {
        self.isDebug = isDebug
        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.internalPaymentMethodType == .nolPay})?.options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            let error = PrimerError.invalidValue(key: "Nol AppID",
                                                 value: nil,
                                                 userInfo: [
                                                "file": #file,
                                                "class": "\(Self.self)",
                                                "function": #function,
                                                "line": "\(#line)"
                                            ],
                                            diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: error)
            self.errorDelegate?.didReceiveError(error: error)
            return
        }
        
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, 
                                                                "class": "\(Self.self)",
                                                                "function": #function,
                                                                "line": "\(#line)"],
                                                     diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return
        }
        
        let isSandbox = clientToken.env != "PRODUCTION"
        
        nolPay = PrimerNolPay(appId: appId, isDebug: isDebug, isSandbox: isSandbox) { sdkId, deviceId in
            
            let requestBody = await Request.Body.NolPay.NolPaySecretDataRequest(nolSdkId: deviceId,
                                                                                nolAppId: sdkId,
                                                                                phoneVendor: "Apple",
                                                                                phoneModel: UIDevice.modelIdentifier!)
            let client = PrimerAPIClient()
            
            return try await withCheckedThrowingContinuation { continuation in
                client.fetchNolSdkSecret(clientToken: clientToken, paymentRequestBody: requestBody) { result in
                    switch result {
                    case .success(let appSecret):
                        continuation.resume(returning: appSecret.sdkSecret)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    public func getLinkedCardsFor(phoneCountryDiallingCode: String,
                                  mobileNumber: String,
                                  completion: @escaping (Result<[PrimerNolPaymentCard], PrimerError>) -> Void) {
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINKED_CARDS_GET_CARDS_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])
        guard let nolPay = nolPay else {
            // TODO: (NOL) Add new errors
            let error = PrimerError.nolError(code: "unknown",
                                             message: "error.description",
                                             userInfo: [
                                                "file": #file,
                                                "class": "\(Self.self)",
                                                "function": #function,
                                                "line": "\(#line)"
                                             ],
                                             diagnosticsId: UUID().uuidString)
            self.errorDelegate?.didReceiveError(error: error)
            ErrorHandler.handle(error: error)
            completion(.failure(error))
            return
        }
        
        nolPay.getAvaliableCards(for: mobileNumber, with: phoneCountryDiallingCode) { result in
            switch result {
                
            case .success(let cards):
                completion(.success(PrimerNolPaymentCard.makeFrom(arrayOf: cards)))
            case .failure(let error):
                let error = PrimerError.nolError(code: error.errorCode,
                                                 message: error.description,
                                                 userInfo: [
                                                    "file": #file,
                                                    "class": "\(Self.self)",
                                                    "function": #function,
                                                    "line": "\(#line)"
                                                 ],
                                                 diagnosticsId: UUID().uuidString)
                self.errorDelegate?.didReceiveError(error: error)
                ErrorHandler.handle(error: error)
                completion(.failure(error))
            }
        }
    }
}

#endif

//
//  NolPayGetLinkedCardsComponent.swift
//  PrimerSDK
//
//  Created by Boris on 15.9.23..
//

import Foundation
import PrimerNolPaySDK

public class NolPayGetLinkedCardsComponent: PrimerHeadlessComponent {
    
    private var nolPay: PrimerNolPay!
    public var errorDelegate: PrimerHeadlessErrorableDelegate?
    
    public init() {
        guard let nolPaymentMethodOption = PrimerAPIConfiguration.current?.paymentMethods?.first(where: { $0.internalPaymentMethodType == .nolPay})?.options as? MerchantOptions,
              let appId = nolPaymentMethodOption.appId
        else {
            self.errorDelegate?.didReceiveError(error: PrimerError.generic(message: "Initialisation error, Nol AppId is not present",
                                                                           userInfo: [
                                                                               "file": #file,
                                                                               "class": "\(Self.self)",
                                                                               "function": #function,
                                                                               "line": "\(#line)"
                                                                           ],
                                                                           diagnosticsId: UUID().uuidString))
            return
        }
        
        nolPay = PrimerNolPay(appId: appId, isDebug: true, isSandbox: true) { sdkId, deviceId in
            // Implement your API call here and return the fetched secret key
            //            Task {
            //               ... async await
            //                }
            return "f335565cce50459d82e5542de7f56426"
        }
    }
    
    public func getLinkedCardsFor(phoneCountryDiallingCode: String,
                           mobileNumber: String,
                           completion: @escaping (Result<[PrimerNolPayCard], PrimerError>) -> Void) {
        
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: NolPayAnalyticsConstants.LINKED_CARDS_GET_CARDS_METHOD,
                params: [
                    "category": "NOL_PAY",
                ]))
        Analytics.Service.record(events: [sdkEvent])

        nolPay.getAvaliableCardsFor(mobileNumber: mobileNumber, withCountryCode: phoneCountryDiallingCode) { result in
            switch result {
                
            case .success(let cards):
                completion(.success(cards))
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

                completion(.failure(error))
            }
        }
    }
}

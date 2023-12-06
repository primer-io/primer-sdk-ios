//
//  PrimerKlarnaError+Extension.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 06/12/23.
//

import Foundation

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
extension PrimerKlarnaError {
 
    var errorId: String {
        switch self {
        case .userNotApproved:
            return "klarna-user-not-approved"
        case .klarnaSdkError:
            return "klarna-sdk-error"
        }
    }
    
    var analyticsContext: [String : Any] {
        [
            AnalyticsContextKeys.errorId: errorId,
            AnalyticsContextKeys.paymentMethodType: PrimerPaymentMethodType.klarna.rawValue
        ]
    }
    
    var diagnosticsId: String {
        return UUID().uuidString
    }
}
#else
struct PrimerKlarnaError {}
#endif

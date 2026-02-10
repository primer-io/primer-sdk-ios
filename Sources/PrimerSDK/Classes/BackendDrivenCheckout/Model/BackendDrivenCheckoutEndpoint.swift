//
//  BackendDrivenCheckoutEndpoint.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum BackendDrivenCheckoutEndpoint {
    case pay(paymentMethod: PrimerPaymentMethod)
    case expandClientSession
}

extension BackendDrivenCheckoutEndpoint: Endpoint {
    var baseURL: String? { PrimerAPIConfiguration.current?.pciUrl }
    
    var path: String {
        switch self {
        case .pay: "client-session/\(PrimerAPIConfigurationModule.clientSessionId):pay"
        case .expandClientSession: "client-session/\(PrimerAPIConfigurationModule.clientSessionId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .pay: .post
        case .expandClientSession: .get
        }
    }
    
    var headers: [String : String]? {
        [
            "Primer-Client-Token": PrimerAPIConfigurationModule.decodedJWTToken!.accessToken!,
            "Primer-SDK-Checkout-Session-ID": PrimerInternal.shared.checkoutSessionId!,
            "Primer-SDK-Client": PrimerSource.defaultSourceType,
            "Content-Type": "application/json",
            "x-primer-branch": "part-922",
            "Primer-SDK-Version": VersionUtils.releaseVersionNumber!
        ]
    }
    
    var queryParameters: [String : String]? {
        switch self {
        case .pay: nil
        case .expandClientSession: ["expand" : "clientInstruction"]
        }
    }
    
    var body: Data? {
        switch self {
        case .expandClientSession:
            return nil
        case .pay:
            guard let paymentMethod else { return nil }
            return try? PayBody(
                paymentMethodConfigId: paymentMethod.id,
                processorMerchantAccountId: paymentMethod.merchantOptions.merchantAccountId
            ).data()
        }
    }
    
    var paymentMethod: PrimerPaymentMethod? {
        switch self {
        case .expandClientSession: nil
        case let .pay(paymentMethod): PrimerAPIConfigurationModule.paymentMethods?.first(where: { $0.type == paymentMethod.type })
        }
    }
        
    var timeout: TimeInterval? { 30 }
    
}

private extension PrimerAPIConfigurationModule {
    static var clientSessionId: String { apiConfiguration!.clientSession!.clientSessionId! }
    static var paymentMethods: [PrimerPaymentMethod]? { apiConfiguration?.paymentMethods }
}

extension PrimerPaymentMethod {
    var merchantOptions: MerchantOptions { options as! MerchantOptions }
}

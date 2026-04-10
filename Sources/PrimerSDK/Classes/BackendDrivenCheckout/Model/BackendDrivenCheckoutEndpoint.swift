//
//  BackendDrivenCheckoutEndpoint.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum BackendDrivenCheckoutEndpoint {
    case manifest
    case pay(paymentMethod: PrimerPaymentMethod)
    case expandClientSession
}

extension BackendDrivenCheckoutEndpoint: Endpoint {
    var baseURL: String? {
        switch self {
        case .expandClientSession, .pay: PrimerAPIConfiguration.current?.pciUrl
        case .manifest: "https://sdk.dev.primer.io"
        }
    }
    
    var path: String {
        let json = PrimerAPIConfiguration.current?.env?.rawValue.lowercased() ?? "dev"
        return switch self {
        case .manifest: "state-processor/pr-16/manifest.json"
        case .pay: "client-session/\(PrimerAPIConfigurationModule.clientSessionId):pay"
        case .expandClientSession: "client-session/\(PrimerAPIConfigurationModule.clientSessionId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .pay: .post
        case .expandClientSession, .manifest: .get
        }
    }
    
    var headers: [String : String]? {
        [
            "Primer-Client-Token": PrimerAPIConfigurationModule.decodedJWTToken?.accessToken,
            "Primer-SDK-Checkout-Session-ID": PrimerInternal.shared.checkoutSessionId,
            "Primer-SDK-Client": PrimerSource.defaultSourceType,
            "Content-Type": "application/json",
            "Primer-SDK-Version": VersionUtils.releaseVersionNumber
        ].compactMapValues(\.self)
    }
    
    var queryParameters: [String : String]? {
        switch self {
        case .manifest, .pay: nil
        case .expandClientSession: ["expand" : "clientInstruction"]
        }
    }
    
    var body: Data? {
        switch self {
        case .manifest, .expandClientSession: return nil
        case .pay:
            guard let paymentMethod, let options = paymentMethod.merchantOptions else { return nil }
            let body = PayBody(
                paymentMethodConfigId: paymentMethod.id,
                processorMerchantAccountId: options.merchantAccountId,
                paymentMethodType: paymentMethod.type
            )
            return try? body.data()
        }
    }
    
    var paymentMethod: PrimerPaymentMethod? {
        switch self {
        case .manifest, .expandClientSession: nil
        case let .pay(paymentMethod): PrimerAPIConfigurationModule.paymentMethods?.first(where: { $0.type == paymentMethod.type })
        }
    }
        
    var timeout: TimeInterval? { 30 }
    
}

private extension PrimerAPIConfigurationModule {
    static var clientSessionId: String { apiConfiguration?.clientSession?.clientSessionId ?? "unknown" }
    static var paymentMethods: [PrimerPaymentMethod]? { apiConfiguration?.paymentMethods }
}

private extension PrimerPaymentMethod {
    var merchantOptions: MerchantOptions? { options as? MerchantOptions }
}

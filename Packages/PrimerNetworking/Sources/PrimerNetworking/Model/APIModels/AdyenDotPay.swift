//
//  AdyenDotPay.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public typealias AdyenBank = Response.Body.Adyen.Bank

extension Request.Body {
    public final class Adyen {}
}

extension Response.Body {
    public final class Adyen {}
}

extension Request.Body.Adyen {

    public struct BanksList: Encodable {
        public let paymentMethodConfigId: String
        public let command: String = "FETCH_BANK_ISSUERS"
        public let parameters: BankTokenizationSessionRequestParameters
        
        public init(paymentMethodConfigId: String, parameters: BankTokenizationSessionRequestParameters) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.parameters = parameters
        }
    }
}

public struct BankTokenizationSessionRequestParameters: Encodable {
    public let paymentMethod: String
    
    public init(paymentMethod: String) {
        self.paymentMethod = paymentMethod
    }
}

extension Response.Body.Adyen {

    public struct Bank: Decodable, Equatable {

        public let id: String
        public let name: String
        public let iconUrlStr: String?
        public lazy var iconUrl: URL? = {
            guard let iconUrlStr = iconUrlStr else { return nil }
            return URL(string: iconUrlStr)
        }()
        public let disabled: Bool
        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case iconUrlStr = "iconUrl"
            case disabled
        }
        
        init(
            id: String,
            name: String,
            iconUrlStr: String?,
            disabled: Bool
        ) {
            self.id = id
            self.name = name
            self.iconUrlStr = iconUrlStr
            self.disabled = disabled
        }
    }
}

public struct BanksListSessionResponse: Decodable {
    public let result: [Response.Body.Adyen.Bank]
    
    init(result: [Response.Body.Adyen.Bank]) {
        self.result = result
    }
}

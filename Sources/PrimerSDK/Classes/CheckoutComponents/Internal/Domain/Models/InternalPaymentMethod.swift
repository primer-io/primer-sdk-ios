//
//  InternalPaymentMethod.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation
import UIKit

/// Internal representation of a payment method with full details.
/// This is used internally and mapped to the public PrimerComposablePaymentMethod.
internal struct InternalPaymentMethod: Equatable {
    let id: String
    let type: String
    let name: String
    let icon: UIImage?
    let configId: String?
    let isEnabled: Bool
    let supportedCurrencies: [String]?
    let requiredInputElements: [PrimerInputElementType]
    let metadata: [String: Any]?
    // Android parity: Surcharge support
    let surcharge: Int?                    // Raw amount in minor currency units
    let hasUnknownSurcharge: Bool          // "Fee may apply" flag
    let networkSurcharges: [String: Int]?  // Card network-specific surcharges
    let backgroundColor: UIColor?          // Dynamic background color from server

    init(
        id: String,
        type: String,
        name: String,
        icon: UIImage? = nil,
        configId: String? = nil,
        isEnabled: Bool = true,
        supportedCurrencies: [String]? = nil,
        requiredInputElements: [PrimerInputElementType] = [],
        metadata: [String: Any]? = nil,
        surcharge: Int? = nil,
        hasUnknownSurcharge: Bool = false,
        networkSurcharges: [String: Int]? = nil,
        backgroundColor: UIColor? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.icon = icon
        self.configId = configId
        self.isEnabled = isEnabled
        self.supportedCurrencies = supportedCurrencies
        self.requiredInputElements = requiredInputElements
        self.metadata = metadata
        self.surcharge = surcharge
        self.hasUnknownSurcharge = hasUnknownSurcharge
        self.networkSurcharges = networkSurcharges
        self.backgroundColor = backgroundColor
    }

    static func == (lhs: InternalPaymentMethod, rhs: InternalPaymentMethod) -> Bool {
        lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.name == rhs.name &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.surcharge == rhs.surcharge &&
            lhs.hasUnknownSurcharge == rhs.hasUnknownSurcharge &&
            lhs.backgroundColor == rhs.backgroundColor
    }
}

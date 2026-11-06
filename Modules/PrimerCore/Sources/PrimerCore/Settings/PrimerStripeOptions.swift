//
//  PrimerStripeOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public final class PrimerStripeOptions: Codable, Equatable {

    public enum MandateData: Codable, Equatable {
        case fullMandate(text: String)
        case templateMandate(merchantName: String)
    }

    public let publishableKey: String
    public let mandateData: MandateData?

    public init(publishableKey: String, mandateData: MandateData? = nil) {
        self.publishableKey = publishableKey
        self.mandateData = mandateData
    }

    public static func == (lhs: PrimerStripeOptions, rhs: PrimerStripeOptions) -> Bool {
        lhs.publishableKey == rhs.publishableKey &&
            lhs.mandateData == rhs.mandateData
    }
}

//
//  PrimerStripeOptions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public final class PrimerStripeOptions: Codable {

    public enum MandateData: Codable {
        case fullMandate(text: String)
        case templateMandate(merchantName: String)
    }

    public var publishableKey: String
    public var mandateData: MandateData?

    public init(publishableKey: String, mandateData: MandateData? = nil) {
        self.publishableKey = publishableKey
        self.mandateData = mandateData
    }
}

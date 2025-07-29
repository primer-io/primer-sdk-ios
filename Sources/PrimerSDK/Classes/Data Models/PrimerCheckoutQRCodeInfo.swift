//
//  PrimerCheckoutQRCodeInfo.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - QRCode

@objc public class PrimerCheckoutQRCodeInfo: PrimerCheckoutAdditionalInfo {}

// MARK: PromptPay

@objc public final class PromptPayCheckoutAdditionalInfo: PrimerCheckoutQRCodeInfo {

    public let expiresAt: String
    public let qrCodeUrl: String?
    public let qrCodeBase64: String?

    private enum CodingKeys: String, CodingKey {
        case expiresAt
        case qrCodeUrl
        case qrCodeBase64
    }

    public init(expiresAt: String, qrCodeUrl: String?, qrCodeBase64: String?) {
        self.expiresAt = expiresAt
        self.qrCodeUrl = qrCodeUrl
        self.qrCodeBase64 = qrCodeBase64
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiresAt = try container.decode(String.self, forKey: .expiresAt)
        qrCodeUrl = try? container.decode(String.self, forKey: .qrCodeUrl)
        qrCodeBase64 = try? container.decode(String.self, forKey: .qrCodeBase64)
        super.init()
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(qrCodeUrl, forKey: .qrCodeUrl)
        try? container.encode(qrCodeBase64, forKey: .qrCodeBase64)
    }

}

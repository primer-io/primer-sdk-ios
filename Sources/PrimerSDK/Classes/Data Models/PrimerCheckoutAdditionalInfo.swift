//
//  PrimerCheckoutAdditionalInfo.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

#if canImport(UIKit)

import Foundation

// MARK: Checkout Data Payment Additional Info

@objc public class PrimerCheckoutAdditionalInfo: NSObject, Codable {}

// MARK: -

@objc public class MultibancoCheckoutAdditionalInfo: PrimerCheckoutAdditionalInfo {
    
    let expiresAt: Date?
    let entity: String?
    let reference: String?
    
    private enum CodingKeys : String, CodingKey {
        case expiresAt
        case entity
        case reference
    }
    
    public init(expiresAt: Date?, entity: String?, reference: String?) {
        self.expiresAt = expiresAt
        self.entity = entity
        self.reference = reference
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiresAt = try? container.decode(Date.self, forKey: .expiresAt)
        entity = try? container.decode(String.self, forKey: .entity)
        reference = try? container.decode(String.self, forKey: .reference)
        super.init()
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(entity, forKey: .entity)
        try? container.encode(reference, forKey: .reference)
    }
}

// MARK: - QRCode

@objc public class PrimerCheckoutQRCodeInfo: PrimerCheckoutAdditionalInfo {}

// MARK: PromptPay

@objc public class PromptPayCheckoutAdditionalInfo: PrimerCheckoutQRCodeInfo {
    
    let expiresAt: Date
    let qrCodeUrl: URL
    
    private enum CodingKeys : String, CodingKey {
        case expiresAt
        case qrCodeUrl
    }
    
    public init(expiresAt: Date, qrCodeUrl: URL) {
        self.expiresAt = expiresAt
        self.qrCodeUrl = qrCodeUrl
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        qrCodeUrl = try container.decode(URL.self, forKey: .qrCodeUrl)
        super.init()
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(qrCodeUrl, forKey: .qrCodeUrl)
    }

}

#endif

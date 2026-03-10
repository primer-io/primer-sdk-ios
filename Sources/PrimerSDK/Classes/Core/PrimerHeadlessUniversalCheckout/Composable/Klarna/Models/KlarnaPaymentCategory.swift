//
//  KlarnaPaymentCategory.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

public struct KlarnaPaymentCategory: Codable {
    public let id: String
    public let name: String
    public let descriptiveAssetUrl: String
    public let standardAssetUrl: String
    // MARK: - Init
    init(response: Response.Body.Klarna.SessionCategory) {
        id = response.identifier
        name = response.name
        descriptiveAssetUrl = response.descriptiveAssetUrl
        standardAssetUrl = response.standardAssetUrl
    }
}

extension KlarnaPaymentCategory: Equatable {
    public static func == (lhs: KlarnaPaymentCategory, rhs: KlarnaPaymentCategory) -> Bool {
        lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.descriptiveAssetUrl == rhs.descriptiveAssetUrl &&
            lhs.standardAssetUrl == rhs.standardAssetUrl
    }
}

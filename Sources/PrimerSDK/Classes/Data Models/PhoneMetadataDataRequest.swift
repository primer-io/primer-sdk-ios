//
//  PhoneMetadataDataRequest.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
// Request
extension Request.Body {
    final class PhoneMetadata {}
}

extension Request.Body.PhoneMetadata {

    struct PhoneMetadataDataRequest: Codable {

        let phoneNumber: String
    }
}

// Response
extension Response.Body {
    final class PhoneMetadata {}
}

extension Response.Body.PhoneMetadata {
    struct PhoneMetadataDataResponse: Codable {

        let isValid: Bool
        let countryCode: String?
        let nationalNumber: String?
    }
}

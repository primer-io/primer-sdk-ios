//
//  PhoneMetadataDataRequest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// Request
extension Request.Body {
    @_spi(PrimerInternal) public final class PhoneMetadata {}
}

extension Request.Body.PhoneMetadata {

    public struct PhoneMetadataDataRequest: Codable {

        public let phoneNumber: String

        public init(phoneNumber: String) {
            self.phoneNumber = phoneNumber
        }
    }
}

// Response
extension Response.Body {
    @_spi(PrimerInternal) public final class PhoneMetadata {}
}

extension Response.Body.PhoneMetadata {
    public struct PhoneMetadataDataResponse: Codable {

        public let isValid: Bool
        public let countryCode: String?
        public let nationalNumber: String?
    }
}

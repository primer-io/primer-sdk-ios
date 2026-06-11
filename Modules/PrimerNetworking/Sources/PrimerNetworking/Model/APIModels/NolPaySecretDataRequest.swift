//
//  NolPaySecretDataRequest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// Request
@_spi(PrimerInternal) public extension Request.Body {
    final class NolPay {}
}

@_spi(PrimerInternal) public extension Request.Body.NolPay {

    struct NolPaySecretDataRequest: Codable {
        let nolSdkId: String
        let nolAppId: String
        let phoneVendor: String
        let phoneModel: String
        
        public init(nolSdkId: String, nolAppId: String, phoneVendor: String, phoneModel: String) {
            self.nolSdkId = nolSdkId
            self.nolAppId = nolAppId
            self.phoneVendor = phoneVendor
            self.phoneModel = phoneModel
        }
    }
}

// Response
@_spi(PrimerInternal) public extension Response.Body {
    final class NolPay {}
}

@_spi(PrimerInternal) public extension Response.Body.NolPay {
    struct NolPaySecretDataResponse: Codable {
        public let sdkSecret: String
    }
}

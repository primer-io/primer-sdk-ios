//
//  NolPaySecretDataRequest.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// Request
extension Request.Body {
    final class NolPay {}
}

extension Request.Body.NolPay {

    struct NolPaySecretDataRequest: Codable {

        let nolSdkId: String
        let nolAppId: String
        let phoneVendor: String
        let phoneModel: String
    }
}

// Response
extension Response.Body {
    final class NolPay {}
}

extension Response.Body.NolPay {
    struct NolPaySecretDataResponse: Codable {

        let sdkSecret: String
    }
}

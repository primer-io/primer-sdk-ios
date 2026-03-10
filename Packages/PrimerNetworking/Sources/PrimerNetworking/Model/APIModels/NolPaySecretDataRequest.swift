//
//  NolPaySecretDataRequest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// Request
extension Request.Body {
    public final class NolPay {}
}

extension Request.Body.NolPay {

    public struct NolPaySecretDataRequest: Codable {
        public let nolSdkId: String
        public let nolAppId: String
        public let phoneVendor: String
        public let phoneModel: String
        
        public init(nolSdkId: String, nolAppId: String, phoneVendor: String, phoneModel: String) {
            self.nolSdkId = nolSdkId
            self.nolAppId = nolAppId
            self.phoneVendor = phoneVendor
            self.phoneModel = phoneModel
        }
    }
}

// Response
extension Response.Body {
    public final class NolPay {}
}

extension Response.Body.NolPay {
    public struct NolPaySecretDataResponse: Codable {

        public let sdkSecret: String
        
        init(sdkSecret: String) {
            self.sdkSecret = sdkSecret
        }
    }
}

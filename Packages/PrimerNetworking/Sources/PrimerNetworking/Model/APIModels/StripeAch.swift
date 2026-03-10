//
//  StripeAch.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Request.Body {
    public final class StripeAch {}
}

extension Response.Body {
    public final class StripeAch {}
}

extension Request.Body.StripeAch {
    public struct SessionData: Codable {
        public let locale: String?
        public let platform: String?
        
        public init(locale: String?, platform: String?) {
            self.locale = locale
            self.platform = platform
        }
    }
}

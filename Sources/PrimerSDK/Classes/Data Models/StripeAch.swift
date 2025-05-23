//
//  Stripe.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 01.05.2024.
//

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
    }
}

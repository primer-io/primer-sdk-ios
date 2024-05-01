//
//  Stripe.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 01.05.2024.
//

import Foundation

extension Request.Body {
    public class Stripe {}
}

extension Response.Body {
    public class Stripe {}
}

extension Request.Body.Stripe {
    public struct SessionData: Codable {
        public let locale: String?
        public let platform: String?
    }
}

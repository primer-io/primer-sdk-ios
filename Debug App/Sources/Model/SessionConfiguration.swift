//
//  AppetizeContext.swift
//  Debug App
//
//  Created by Niall Quinn on 08/03/24.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation
import PrimerSDK

struct SessionConfiguration: Codable, Equatable {
    let customerId: String
    let locale: String
    let paymentFlow: String
    let currency: String
    let countryCode: String
    let value: String
    let surchargeEnabled: Bool
    let applePaySurcharge: Int

    let firstName: String
    let lastName: String
    let email: String
    let mobileNumber: String
    let addressLine1: String
    let state: String
    let city: String
    let postalCode: String

    let vault: Bool
    let newWorkflows: Bool
    let environment: String

    let customApiKey: String
    let metadata: String

    var paymentHandling: PrimerPaymentHandling {
        switch paymentFlow {
        case "default":
            return .auto
        case "manual":
            return .manual
        default:
            return .auto
        }
    }

    var env: Environment {
        let strippedEnv = environment.replacingOccurrences(of: "CUSTOM_", with: "").lowercased()
        switch strippedEnv {
        case "staging":
            return .staging
        case "sandbox":
            return .sandbox
        case "dev":
            return .dev
        case "production":
            return .production
        default:
            return .sandbox
        }
    }
}

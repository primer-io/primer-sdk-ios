//
//  3DS.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 1/4/21.
//

import Foundation

enum ThreeDSecureTestScenario: String, Codable {
    // swiftlint:disable identifier_name
    case three3DS_V2_METHOD_TIMEOUT = "3DS_V2_METHOD_TIMEOUT"
    case threeDS_V2_FRICTIONLESS_NO_METHOD = "3DS_V2_FRICTIONLESS_NO_METHOD"
    case threeDS_V2_FRICTIONLESS_PASS = "3DS_V2_FRICTIONLESS_PASS"
    case threeDS_V2_MANUAL_CHALLENGE_PASS = "3DS_V2_MANUAL_CHALLENGE_PASS"
    case threeDS_V2_AUTO_CHALLENGE_PASS = "3DS_V2_AUTO_CHALLENGE_PASS"
    case threeDS_V2_AUTO_CHALLENGE_FAIL = "3DS_V2_AUTO_CHALLENGE_FAIL"
    case threeDS_V2_AUTO_CHALLENGE_PASS_NO_METHOD = "3DS_V2_AUTO_CHALLENGE_PASS_NO_METHOD"
    case threeDS_V2_FRICTIONLESS_FAILURE_N = "3DS_V2_FRICTIONLESS_FAILURE_N"
    case threeDS_V2_FRICTIONLESS_FAILURE_U = "3DS_V2_FRICTIONLESS_FAILURE_U"
    case threeDS_V2_FRICTIONLESS_FAILURE_R = "3DS_V2_FRICTIONLESS_FAILURE_R"
    case threeDS_V2_FRICTIONLESS_FAILURE_ATTEMPTED = "3DS_V2_FRICTIONLESS_FAILURE_ATTEMPTED"
    case threeDS_V2_DS_TIMEOUT = "3DS_V2_DS_TIMEOUT"
}

struct ThreeDSecureBeginAuthRequest: Codable {
    let testScenario: ThreeDSecureTestScenario?
    let amount: Int
    let currencyCode: Currency
    let orderId: String
    let customer: ThreeDSecureCustomer
    let device: ThreeDSecureDevice
    let billingAddress: ThreeDSecureAddress
    let shippingAddress: ThreeDSecureAddress?
    let customerAccount: ThreeDSecureCustomerAccount?
}

struct ThreeDSecureCustomer: Codable {
    let name: String
    let email: String
    let homePhone: String?
    let mobilePhone: String?
    let workPhone: String?
}

struct ThreeDSecureDevice: Codable {
    struct Web {
        let colorDepth: Int
        let javaEnabled: Bool
        let language: String
        let screenHeight: Int
        let screenWidth: Int
        let timezoneOffset: Int
        let userAgent: String
    }
    
    struct App {
        let device: String
    }
}

struct ThreeDSecureAddress: Codable {
    let title: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let phoneNumber: String?
    let addressLine1: String
    let addressLine2: String?
    let addressLine3: String?
    let city: String
    let state: String?
    let countryCode: CountryCode
    let postalCode: String
}

struct ThreeDSecureCustomerAccount: Codable {
    let id: String?
    let createdAt: String?
    let updatedAt: String?
    let passwordUpdatedAt: String?
    let purchaseCount: Int?
}

//
//  Payment.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
import Foundation
import PrimerFoundation

public struct PaymentAPIModelAddress: Codable {
    public let firstName: String?
    public let lastName: String?
    public let addressLine1: String?
    public let addressLine2: String?
    public let city: String?
    public let state: String?
    public let countryCode: String?
    public let postalCode: String?

    public init(
        firstName: String?,
        lastName: String?,
        addressLine1: String,
        addressLine2: String?,
        city: String,
        state: String?,
        countryCode: String,
        postalCode: String
    ) {
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.countryCode = countryCode
        self.postalCode = postalCode
        self.firstName = firstName
        self.lastName = lastName
        self.state = state
    }

}

extension Request.Body {
    public final class Payment {}
}

extension Request.Body.Payment {

    public struct Create: Encodable {
        public let paymentMethodToken: String

        public init(token: String) {
            paymentMethodToken = token
        }
    }

    public struct Resume: Encodable {
        public let resumeToken: String

        public init(token: String) {
            resumeToken = token
        }
    }

    public struct Complete: Encodable {
        public let mandateSignatureTimestamp: String
        public let paymentMethodId: String?

        public init(
            mandateSignatureTimestamp: String,
            paymentMethodId: String? = nil
        ) {
            self.mandateSignatureTimestamp = mandateSignatureTimestamp
            self.paymentMethodId = paymentMethodId
        }
    }
}

extension Response.Body {

    public struct Payment: Codable {
        public var id: String?
        public var paymentId: String?
        public var amount: Int?
        public var currencyCode: String?
        public var customer: Request.Body.ClientSession.Customer?
        public var customerId: String?
        public var dateStr: String?
        public var date: Date? {
            dateStr?.toDate()
        }
        public var order: Request.Body.ClientSession.Order?
        public var orderId: String?
        public var requiredAction: Response.Body.Payment.RequiredAction?
        public let status: Status
        public var paymentFailureReason: PrimerPaymentErrorCode.RawValue?
        public var showSuccessCheckoutOnPendingPayment: Bool?
        public var checkoutOutcome: CheckoutOutcome?

        // swiftlint:disable:next nesting
        public enum CodingKeys: String, CodingKey {
            case id,
                 paymentId,
                 amount,
                 currencyCode,
                 customer,
                 customerId,
                 order,
                 orderId,
                 requiredAction,
                 status,
                 paymentFailureReason,
                 showSuccessCheckoutOnPendingPayment,
                 checkoutOutcome
            case dateStr = "date"
        }

        // swiftlint:disable:next nesting
        public struct RequiredAction: Codable {
            public let clientToken: String
            public let name: RequiredActionName
            public let description: String?

            public init(clientToken: String, name: RequiredActionName, description: String?) {
                self.clientToken = clientToken
                self.name = name
                self.description = description
            }
        }

        // swiftlint:disable:next nesting
        public enum Status: String, Codable {
            case failed = "FAILED"
            case pending = "PENDING"
            case success = "SUCCESS"
        }

        // swiftlint:disable:next nesting
        public enum CheckoutOutcome: String, Codable {
            case complete = "CHECKOUT_COMPLETE"
            case failure = "CHECKOUT_FAILURE"
            case determineFromPaymentStatus = "DETERMINE_FROM_PAYMENT_STATUS"
        }
    }

    public struct Complete: Codable {
        public init() {}
    }
}

// MARK: - Checkout Data Payment Error

@objc public enum PrimerPaymentErrorCode: Int, RawRepresentable, Codable {

    case failed
    case cancelledByCustomer

    public typealias RawValue = String

    public var rawValue: RawValue {
        switch self {
        case .failed:
            "payment-failed"
        case .cancelledByCustomer:
            "cancelled-by-customer"
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case "payment-failed":
            self = .failed
        case "cancelled-by-customer":
            self = .cancelledByCustomer
        default:
            return nil
        }
    }
}
// swiftlint:enable file_length

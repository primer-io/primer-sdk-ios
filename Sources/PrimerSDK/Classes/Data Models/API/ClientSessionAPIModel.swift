//
//  ClientSessionAPIModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 5/9/22.
//

import Foundation

extension Request.Body {

    public struct ClientSession {

        public let customerId: String?
        public let orderId: String?
        public let currencyCode: Currency?
        public let amount: Int?
        public let metadata: [String: Any]?
        public let customer: Request.Body.ClientSession.Customer?
        public let order: Request.Body.ClientSession.Order?
        public let paymentMethod: Request.Body.ClientSession.PaymentMethod?

        // swiftlint:disable:next nesting
        public struct Customer: Codable {
            public let firstName: String?
            public let lastName: String?
            public let emailAddress: String?
            public let mobileNumber: String?
            public let billingAddress: PaymentAPIModelAddress?
            public let shippingAddress: PaymentAPIModelAddress?
        }
        // swiftlint:disable:next nesting
        public struct Order: Codable {
            public let countryCode: CountryCode?
            public let lineItems: [LineItem]?

            // swiftlint:disable:next nesting
            public struct LineItem: Codable {
                public let itemId: String?
                public let description: String?
                public let amount: Int?
                public let quantity: Int?
            }
        }
        // swiftlint:disable:next nesting
        public struct PaymentMethod {
            public let vaultOnSuccess: Bool?
            public let options: [String: Any]?
        }
    }
}

public struct ClientSessionAction: Encodable {
    let actions: [ClientSession.Action]
}

public struct ClientSessionUpdateRequest: Encodable {
    let actions: ClientSessionAction
}

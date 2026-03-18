//
//  CheckoutModule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public protocol CheckoutModuleOptions: Codable {}

// swiftlint:disable nesting
public struct CheckoutModule: Codable {

    public let type: String
    public let requestUrlStr: String?
    public let options: CheckoutModuleOptions?

    private enum CodingKeys: String, CodingKey {
        case type, options
        case requestUrlStr = "requestUrl"
    }

    public struct CardInformationOptions: CheckoutModuleOptions {
        public let cardHolderName: Bool?
        public let saveCardCheckbox: Bool?

        private enum CodingKeys: String, CodingKey {
            case cardHolderName
            case saveCardCheckbox
        }

        public init(cardHolderName: Bool?, saveCardCheckbox: Bool?) {
            self.cardHolderName = cardHolderName
            self.saveCardCheckbox = saveCardCheckbox
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.cardHolderName = (try? container.decode(Bool?.self, forKey: .cardHolderName)) ?? nil
            self.saveCardCheckbox = (try? container.decode(Bool?.self, forKey: .saveCardCheckbox)) ?? nil

            if self.cardHolderName == nil, self.saveCardCheckbox == nil {
                throw InternalError.failedToDecode(message: "All fields are nil")
            }
        }
    }

    public struct ShippingMethodOptions: CheckoutModuleOptions {
        public let shippingMethods: [ShippingMethod]
        public let selectedShippingMethod: String

        public struct ShippingMethod: Codable {
            public let name: String
            public let description: String
            public let amount: Int
            public let id: String

            public init(name: String, description: String, amount: Int, id: String) {
                self.name = name
                self.description = description
                self.amount = amount
                self.id = id
            }
        }

        public init(shippingMethods: [ShippingMethod], selectedShippingMethod: String) {
            self.shippingMethods = shippingMethods
            self.selectedShippingMethod = selectedShippingMethod
        }
    }

    public struct PostalCodeOptions: CheckoutModuleOptions {
        public let firstName: Bool?
        public let lastName: Bool?
        public let city: Bool?
        public let postalCode: Bool?
        public let addressLine1: Bool?
        public let addressLine2: Bool?
        public let countryCode: Bool?
        public let phoneNumber: Bool?
        public let state: Bool?

        private enum CodingKeys: String, CodingKey {
            case firstName
            case lastName
            case city
            case postalCode
            case addressLine1
            case addressLine2
            case countryCode
            case phoneNumber
            case state
        }

        public init(
            firstName: Bool? = nil,
            lastName: Bool? = nil,
            city: Bool? = nil,
            postalCode: Bool? = nil,
            addressLine1: Bool? = nil,
            addressLine2: Bool? = nil,
            countryCode: Bool? = nil,
            phoneNumber: Bool? = nil,
            state: Bool? = nil
        ) {
            self.firstName = firstName
            self.lastName = lastName
            self.city = city
            self.postalCode = postalCode
            self.addressLine1 = addressLine1
            self.addressLine2 = addressLine2
            self.countryCode = countryCode
            self.phoneNumber = phoneNumber
            self.state = state
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.firstName = (try? container.decode(Bool?.self, forKey: .firstName)) ?? nil
            self.lastName = (try? container.decode(Bool?.self, forKey: .lastName)) ?? nil
            self.city = (try? container.decode(Bool?.self, forKey: .city)) ?? nil
            self.postalCode = (try? container.decode(Bool?.self, forKey: .postalCode)) ?? nil
            self.addressLine1 = (try? container.decode(Bool?.self, forKey: .addressLine1)) ?? nil
            self.addressLine2 = (try? container.decode(Bool?.self, forKey: .addressLine2)) ?? nil
            self.countryCode = (try? container.decode(Bool?.self, forKey: .countryCode)) ?? nil
            self.phoneNumber = (try? container.decode(Bool?.self, forKey: .phoneNumber)) ?? nil
            self.state = (try? container.decode(Bool?.self, forKey: .state)) ?? nil

            if self.firstName == nil,
                self.lastName == nil,
                self.city == nil,
                self.postalCode == nil,
                self.addressLine1 == nil,
                self.addressLine2 == nil,
                self.countryCode == nil,
                self.phoneNumber == nil,
                self.state == nil {
                throw InternalError.failedToDecode(message: "All fields are nil")
            }
        }
    }

    public init(type: String, requestUrlStr: String?, options: CheckoutModuleOptions?) {
        self.type = type
        self.requestUrlStr = requestUrlStr
        self.options = options
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.requestUrlStr = (try? container.decode(String?.self, forKey: .requestUrlStr)) ?? nil

        if let options = (try? container.decode(CardInformationOptions.self, forKey: .options)) {
            self.options = options
        } else if let options = (try? container.decode(PostalCodeOptions.self, forKey: .options)) {
            self.options = options
        } else if let options = (try? container.decode(ShippingMethodOptions.self, forKey: .options)) {
            self.options = options
        } else {
            self.options = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(requestUrlStr, forKey: .requestUrlStr)

        if let options = options as? CardInformationOptions {
            try container.encode(options, forKey: .options)
        } else if let options = options as? PostalCodeOptions {
            try container.encode(options, forKey: .options)
        } else if let options = options as? ShippingMethodOptions {
            try container.encode(options, forKey: .options)
        }
    }
}
// swiftlint:enable nesting

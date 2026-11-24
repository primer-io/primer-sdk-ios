//
//  ComponentsPaymentMethodOption.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public struct ComponentsPaymentMethodOption {

    public struct Network {

        public let type: String
        public let surcharge: Int?

        public init(type: String, surcharge: Int?) {
            self.type = type
            self.surcharge = surcharge
        }
    }

    public let type: String
    public let surcharge: Int?
    public let networks: [Network]

    public init(type: String, surcharge: Int?, networks: [Network]) {
        self.type = type
        self.surcharge = surcharge
        self.networks = networks
    }
}

//
//  ComponentsBillingAddressBridge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public final class ComponentsBillingAddressBridge {

    private let dispatch: (ClientSession.Address) async throws -> Void

    public init() {
        dispatch = { address in
            try await ClientSessionActionsModule
                .updateBillingAddressViaClientSessionActionWithAddressIfNeeded(address)
        }
    }

    init(dispatch: @escaping (ClientSession.Address) async throws -> Void) {
        self.dispatch = dispatch
    }

    public func setBillingAddress(_ address: PrimerAddress) async throws {
        Analytics.Service.fire(event: Analytics.Event.sdk(
            name: "\(Self.self).\(#function)",
            params: ["category": "RAW_DATA"]
        ))

        try validate(billingAddress: address)
        try await dispatch(.init(from: address))
    }

    private func validate(billingAddress address: PrimerAddress) throws {
        let hasAnyField = [
            address.firstName,
            address.lastName,
            address.addressLine1,
            address.addressLine2,
            address.city,
            address.state,
            address.postalCode,
            address.countryCode
        ].contains { $0?.isEmpty == false }

        guard hasAnyField else {
            throw PrimerValidationError.invalidRawData()
        }

        if let code = address.countryCode, !code.isEmpty, CountryCode(rawValue: code) == nil {
            throw PrimerValidationError.invalidRawData()
        }
    }
}

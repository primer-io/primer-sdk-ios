//
//  ComponentsClientSessionBridge.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
@_spi(PrimerInternal)
public final class ComponentsClientSessionBridge {

    private let configurationProvider: () -> PrimerAPIConfiguration?

    public init() {
        configurationProvider = { PrimerAPIConfigurationModule.apiConfiguration }
    }

    init(configurationProvider: @escaping () -> PrimerAPIConfiguration?) {
        self.configurationProvider = configurationProvider
    }

    public func getClientSession() -> PrimerClientSession? {
        Analytics.Service.fire(event: Analytics.Event.sdk(
            name: "\(Self.self).\(#function)",
            params: ["category": "CLIENT_SESSION"]
        ))

        guard let configuration = configurationProvider() else { return nil }
        return PrimerClientSession(from: configuration)
    }

    public func getCheckoutModules() -> [ComponentsCheckoutModule]? {
        Analytics.Service.fire(event: Analytics.Event.sdk(
            name: "\(Self.self).\(#function)",
            params: ["category": "CLIENT_SESSION"]
        ))

        guard let modules = configurationProvider()?.checkoutModules else { return nil }
        return modules.map(ComponentsCheckoutModule.init(module:))
    }
}

@available(iOS 15.0, *)
private extension ComponentsCheckoutModule {
    init(module: PrimerAPIConfiguration.CheckoutModule) {
        self.init(type: module.type, options: Self.flatten(module.options))
    }

    static func flatten(_ options: CheckoutModuleOptions?) -> [String: Bool]? {
        if let postal = options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions {
            var dict: [String: Bool] = [:]
            if let v = postal.firstName { dict["firstName"] = v }
            if let v = postal.lastName { dict["lastName"] = v }
            if let v = postal.city { dict["city"] = v }
            if let v = postal.postalCode { dict["postalCode"] = v }
            if let v = postal.addressLine1 { dict["addressLine1"] = v }
            if let v = postal.addressLine2 { dict["addressLine2"] = v }
            if let v = postal.countryCode { dict["countryCode"] = v }
            if let v = postal.phoneNumber { dict["phoneNumber"] = v }
            if let v = postal.state { dict["state"] = v }
            return dict.isEmpty ? nil : dict
        }
        if let card = options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions {
            var dict: [String: Bool] = [:]
            if let v = card.cardHolderName { dict["cardHolderName"] = v }
            if let v = card.saveCardCheckbox { dict["saveCardCheckbox"] = v }
            return dict.isEmpty ? nil : dict
        }
        return nil
    }
}

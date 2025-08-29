//
//  ClientSessionActionsModule.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol ClientSessionActionsProtocol {
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws
    func unselectPaymentMethodIfNeeded() async throws
    func dispatch(actions: [ClientSession.Action]) async throws
}

// MARK: MISSING_TESTS
final class ClientSessionActionsModule: ClientSessionActionsProtocol {

    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws {
        guard PrimerInternal.shared.intent == .checkout else { return }
        guard PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled == true else { return }

        var params: [String: Any] = ["paymentMethodType": paymentMethodType]

        if let cardNetwork {
            params["binData"] = ["network": cardNetwork]
        }

        await PrimerDelegateProxy.primerClientSessionWillUpdate()

        let apiConfigurationModule = PrimerAPIConfigurationModule()
        try await apiConfigurationModule.updateSession(
            withActions: ClientSessionUpdateRequest(
                actions: ClientSessionAction(
                    actions: [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
                )
            )
        )

        if PrimerAPIConfigurationModule.apiConfiguration != nil {
            await PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
        }
    }

    func unselectPaymentMethodIfNeeded() async throws {
        guard PrimerInternal.shared.intent == .checkout else { return }
        guard PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled == true else { return }

        await PrimerDelegateProxy.primerClientSessionWillUpdate()

        let apiConfigurationModule = PrimerAPIConfigurationModule()
        try await apiConfigurationModule
            .updateSession(withActions: ClientSessionUpdateRequest(actions: ClientSessionAction(actions: [ClientSession.Action(
                type: .unselectPaymentMethod,
                params: nil
            )])))

        if PrimerAPIConfigurationModule.apiConfiguration != nil {
            await PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
        }
    }

    static func selectShippingMethodIfNeeded(_ shippingMethodId: String) async throws {
        guard PrimerInternal.shared.intent == .checkout else { return }

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule
            .dispatch(actions: [ClientSession.Action.selectShippingMethodActionWithParameters(["shipping_method_id": shippingMethodId])])
    }

    static func updateBillingAddressViaClientSessionActionWithAddressIfNeeded(_ address: ClientSession.Address?) async throws {
        guard let unwrappedAddress = address, let billingAddress = try? unwrappedAddress.asDictionary() else {
            return
        }

        let billingAddressAction: ClientSession.Action = .setBillingAddressActionWithParameters(billingAddress)
        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

        try await clientSessionActionsModule.dispatch(actions: [billingAddressAction])
    }

    static func updateShippingDetailsViaClientSessionActionIfNeeded(address: ClientSession.Address?,
                                                                    mobileNumber: String?,
                                                                    emailAddress: String?) async throws {
        guard let unwrappedAddress = address, let shippingAddress = try? unwrappedAddress.asDictionary() else {
            return
        }

        var actions: [ClientSession.Action] = []

        let setShippingAddressAction: ClientSession.Action = .setShippingAddressActionWithParameters(shippingAddress)
        actions.append(setShippingAddressAction)

        if let mobileNumber {
            let setMobileNumberAction: ClientSession.Action = .setMobileNumberAction(mobileNumber: mobileNumber)
            actions.append(setMobileNumberAction)
        }

        if let emailAddress {
            let setEmailAddressAction: ClientSession.Action = .setCustomerEmailAddress(emailAddress)
            actions.append(setEmailAddressAction)
        }

        let clientSessionActionsModule = ClientSessionActionsModule()
        try await clientSessionActionsModule.dispatch(actions: actions)
    }

    func dispatch(actions: [ClientSession.Action]) async throws {
        let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))

        await PrimerDelegateProxy.primerClientSessionWillUpdate()
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        try await apiConfigurationModule.updateSession(withActions: clientSessionActionsRequest)

        if AppState.current.apiConfiguration != nil {
            await PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
        }
    }
}

//
//  ClientSessionActionsModule.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol ClientSessionActionsProtocol {
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) -> Promise<Void>
    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) async throws
    func unselectPaymentMethodIfNeeded() -> Promise<Void>
    func unselectPaymentMethodIfNeeded() async throws
    func dispatch(actions: [ClientSession.Action]) -> Promise<Void>
    func dispatch(actions: [ClientSession.Action]) async throws
}

// MARK: MISSING_TESTS
final class ClientSessionActionsModule: ClientSessionActionsProtocol {

    func selectPaymentMethodIfNeeded(_ paymentMethodType: String, cardNetwork: String?) -> Promise<Void> {
        return Promise { seal in
            guard PrimerInternal.shared.intent == .checkout else {
                seal.fulfill()
                return
            }

            if (PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled ?? false) == false {
                seal.fulfill()
                return
            }

            var params: [String: Any] = ["paymentMethodType": paymentMethodType]

            if let cardNetwork = cardNetwork {
                params["binData"] = [
                    "network": cardNetwork
                ]
            }
            let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))

            PrimerDelegateProxy.primerClientSessionWillUpdate()

            let apiConfigurationModule = PrimerAPIConfigurationModule()

            firstly {
                apiConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
            }
            .done {
                if PrimerAPIConfigurationModule.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
                }

                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

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

    func unselectPaymentMethodIfNeeded() -> Promise<Void> {
        return Promise { seal in
            guard PrimerInternal.shared.intent == .checkout else {
                seal.fulfill()
                return
            }

            if (PrimerAPIConfigurationModule.apiConfiguration?.hasSurchargeEnabled ?? false) == false {
                seal.fulfill()
                return
            }

            let unselectPaymentMethodAction = ClientSession.Action(type: .unselectPaymentMethod, params: nil)
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: [unselectPaymentMethodAction]))

            PrimerDelegateProxy.primerClientSessionWillUpdate()
            let apiConfigurationModule = PrimerAPIConfigurationModule()

            firstly {
                apiConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
            }
            .done {
                if PrimerAPIConfigurationModule.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
                }

                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
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

    static func selectShippingMethodIfNeeded(_ shippingMethodId: String) -> Promise<Void> {
        return Promise { seal in
            guard PrimerInternal.shared.intent == .checkout else {
                seal.fulfill()
                return
            }

            let params: [String: Any] = ["shipping_method_id": shippingMethodId]

            let actions = [ClientSession.Action.selectShippingMethodActionWithParameters(params)]
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

            firstly {
                clientSessionActionsModule.dispatch(actions: actions)
            }
            .done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

    static func selectShippingMethodIfNeeded(_ shippingMethodId: String) async throws {
        guard PrimerInternal.shared.intent == .checkout else { return }

        let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
        try await clientSessionActionsModule
            .dispatch(actions: [ClientSession.Action.selectShippingMethodActionWithParameters(["shipping_method_id": shippingMethodId])])
    }

    static func updateBillingAddressViaClientSessionActionWithAddressIfNeeded(_ address: ClientSession.Address?) -> Promise<Void> {
        return Promise { seal in

            guard let unwrappedAddress = address, let billingAddress = try? unwrappedAddress.asDictionary() else {
                seal.fulfill()
                return
            }

            let billingAddressAction: ClientSession.Action = .setBillingAddressActionWithParameters(billingAddress)
            let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()

            firstly {
                clientSessionActionsModule.dispatch(actions: [billingAddressAction])
            }.done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
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
                                                                    emailAddress: String?) -> Promise<Void> {
        return Promise { seal in

            guard let unwrappedAddress = address, let shippingAddress = try? unwrappedAddress.asDictionary() else {
                seal.fulfill()
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

            firstly {
                clientSessionActionsModule.dispatch(actions: actions)
            }.done {
                seal.fulfill()
            }.catch { error in
                seal.reject(error)
            }
        }
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

    func dispatch(actions: [ClientSession.Action]) -> Promise<Void> {
        return Promise { seal in
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))

            PrimerDelegateProxy.primerClientSessionWillUpdate()
            let apiConfigurationModule = PrimerAPIConfigurationModule()

            firstly {
                apiConfigurationModule.updateSession(withActions: clientSessionActionsRequest)
            }
            .done {
                if AppState.current.apiConfiguration != nil {
                    PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: PrimerAPIConfigurationModule.apiConfiguration!))
                }

                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
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
